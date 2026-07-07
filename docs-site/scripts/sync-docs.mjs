// Copies the Markdown in ../doc into the Starlight content directory and
// rewrites intra-doc links so they resolve on the built site.
//
// The doc/ folder is the source of truth: it reads cleanly on GitHub with plain
// relative .md links. Starlight serves routes without the .md extension, so this
// script maps each file to its route and turns every cross-link into a
// base-independent relative link. Links that point outside doc/ (for example the
// root CONTRIBUTING.md) become absolute GitHub URLs.
import { existsSync } from 'node:fs';
import { mkdir, readdir, readFile, rm, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '..', '..');
const docRoot = path.join(repoRoot, 'doc');
const outRoot = path.join(here, '..', 'src', 'content', 'docs');
const blobBase = 'https://github.com/SimonErich/dart_ai_abstracted/blob/main';

// Top-level doc/ subdirectories that are not part of the Starlight site.
// doc/categories holds dartdoc category descriptions (dartdoc_options.yaml):
// plain Markdown without frontmatter, rendered into the API reference, not the
// site. Including them here would trip the frontmatter guard in main().
const skipDirs = new Set(['categories']);

/** Every site Markdown file under doc/, as paths relative to doc/. */
async function collect(dir, base = '') {
  const out = [];
  for (const entry of await readdir(dir)) {
    const abs = path.join(dir, entry);
    const rel = base ? `${base}/${entry}` : entry;
    if ((await stat(abs)).isDirectory()) {
      if (skipDirs.has(rel)) continue;
      out.push(...(await collect(abs, rel)));
    } else if (entry.endsWith('.md')) {
      out.push(rel);
    }
  }
  return out;
}

/** The site route (no base prefix) for a doc-relative Markdown path. */
function routeFor(docRel) {
  if (docRel === 'README.md') return '/';
  const parts = docRel.replace(/\.md$/, '').split('/');
  if (parts[parts.length - 1] === 'index') parts.pop();
  return parts.length ? `/${parts.join('/')}/` : '/';
}

/** The output file path (relative to the content dir) for a doc file. */
function outFor(docRel) {
  return docRel === 'README.md' ? 'index.md' : docRel;
}

/** A base-independent relative link from one route to another. */
function relLink(fromRoute, toRoute) {
  let rel = path.posix.relative(fromRoute, toRoute);
  if (rel === '') rel = '.';
  if (toRoute.endsWith('/') && !rel.endsWith('/')) rel += '/';
  if (!rel.startsWith('.')) rel = `./${rel}`;
  return rel;
}

/** Quotes bare title/description frontmatter values that would break YAML. */
function normalizeFrontmatter(body) {
  if (!body.startsWith('---\n')) return body;
  const end = body.indexOf('\n---', 4);
  if (end === -1) return body;
  const head = body.slice(4, end);
  const rest = body.slice(end);
  const fixed = head
    .split('\n')
    .map((line) => {
      const match = /^(title|description):\s+(.*)$/.exec(line);
      if (!match) return line;
      const value = match[2].trim();
      const quoted = value.startsWith('"') || value.startsWith("'");
      if (quoted) return line;
      return `${match[1]}: "${value.replace(/"/g, '\\"')}"`;
    })
    .join('\n');
  return `---\n${fixed}${rest}`;
}

const linkPattern = /\]\(([^)]+)\)/g;

function rewriteLinks(body, docRel, known, broken) {
  const fromRoute = routeFor(docRel);
  const fromDir = path.posix.dirname(`doc/${docRel}`);
  return body.replace(linkPattern, (whole, target) => {
    if (/^(https?:|mailto:|#)/.test(target)) return whole;
    const [rawPath, anchor] = target.split('#');
    if (!rawPath.endsWith('.md')) return whole;

    const repoRel = path.posix.normalize(path.posix.join(fromDir, rawPath));
    const suffix = anchor ? `#${anchor}` : '';

    if (repoRel.startsWith('..') || !repoRel.startsWith('doc/')) {
      const outside = repoRel.replace(/^(\.\.\/)+/, '');
      return `](${blobBase}/${outside}${suffix})`;
    }

    const targetDocRel = repoRel.slice('doc/'.length);
    if (!known.has(targetDocRel)) broken.push(`${docRel} -> ${rawPath}`);
    return `](${relLink(fromRoute, routeFor(targetDocRel))}${suffix})`;
  });
}

async function main() {
  if (!existsSync(docRoot)) {
    console.error(`doc/ not found at ${docRoot}`);
    process.exit(1);
  }
  await rm(outRoot, { recursive: true, force: true });
  await mkdir(outRoot, { recursive: true });

  const files = await collect(docRoot);
  const known = new Set(files);
  const broken = [];

  for (const docRel of files) {
    const body = await readFile(path.join(docRoot, docRel), 'utf8');
    if (!body.startsWith('---')) {
      console.error(`missing frontmatter: doc/${docRel}`);
      process.exit(1);
    }
    const rewritten = normalizeFrontmatter(rewriteLinks(body, docRel, known, broken));
    const outPath = path.join(outRoot, outFor(docRel));
    await mkdir(path.dirname(outPath), { recursive: true });
    await writeFile(outPath, rewritten);
  }

  if (broken.length) {
    console.error(`broken intra-doc links:\n  ${broken.join('\n  ')}`);
    process.exit(1);
  }
  console.log(`synced ${files.length} pages into src/content/docs`);
}

await main();
