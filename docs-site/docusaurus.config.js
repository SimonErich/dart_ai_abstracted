// @ts-check
// Docusaurus configuration for the ai_abstracted documentation site.
//
// The Markdown is NOT copied in here: the docs plugin reads it straight from
// ../doc (the repository's single source of truth, also consumed by dartdoc and
// shipped to pub.dev). This folder holds only the site tooling. The build lands
// in docs-site/build and is published to GitHub Pages by
// .github/workflows/docs.yaml.
const { themes } = require('prism-react-renderer');

const organizationName = 'SimonErich';
const projectName = 'dart_ai_abstracted';
const repoUrl = `https://github.com/${organizationName}/${projectName}`;

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'ai_abstracted',
  tagline:
    'Provider-agnostic generative AI for Dart: one set of contracts for text, image, video, speech, sound effects, and music.',
  url: 'https://simonerich.github.io',
  baseUrl: `/${projectName}/`,
  organizationName,
  projectName,
  trailingSlash: true,

  onBrokenLinks: 'throw',
  onBrokenAnchors: 'warn',
  onDuplicateRoutes: 'throw',

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  i18n: { defaultLocale: 'en', locales: ['en'] },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          // Serve the docs at the site root and read them from ../doc.
          path: '../doc',
          routeBasePath: '/',
          exclude: ['categories/**'],
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: `${repoUrl}/edit/main/doc/`,
          breadcrumbs: true,
        },
        blog: false,
        theme: { customCss: require.resolve('./src/css/custom.css') },
        sitemap: { changefreq: 'weekly', priority: 0.5 },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      colorMode: {
        defaultMode: 'light',
        respectPrefersColorScheme: true,
      },
      docs: {
        sidebar: { hideable: true, autoCollapseCategories: false },
      },
      navbar: {
        title: 'ai_abstracted',
        hideOnScroll: true,
        items: [
          {
            href: 'https://pub.dev/packages/ai_abstracted',
            label: 'pub.dev',
            position: 'right',
          },
          {
            href: repoUrl,
            position: 'right',
            className: 'header-github-link',
            'aria-label': 'GitHub repository',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              { label: 'Installation', to: '/getting-started/installation/' },
              { label: 'Core concepts', to: '/getting-started/core-concepts/' },
              { label: 'Providers', to: '/providers/' },
            ],
          },
          {
            title: 'More',
            items: [
              { label: 'pub.dev', href: 'https://pub.dev/packages/ai_abstracted' },
              { label: 'GitHub', href: repoUrl },
              { label: 'Issues', href: `${repoUrl}/issues` },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Simon Auer. Built with Docusaurus.`,
      },
      prism: {
        theme: themes.github,
        darkTheme: themes.dracula,
        additionalLanguages: ['dart', 'bash', 'json', 'yaml', 'toml'],
      },
    }),
};

module.exports = config;
