// @ts-check
// Manual sidebar mirroring the structure of doc/. Ids are the paths under
// ../doc without the .md extension (doc/README.md is the site home, id
// "README"; doc/providers/index.md is the Providers landing page).

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docs: [
    { type: 'doc', id: 'README', label: 'Overview' },
    {
      type: 'category',
      label: 'Start here',
      collapsed: false,
      items: [
        'getting-started/installation',
        'getting-started/your-first-request',
        'getting-started/core-concepts',
      ],
    },
    {
      type: 'category',
      label: 'Guides',
      items: [
        'guides/result-types',
        'guides/credentials',
        'guides/the-registry',
        'guides/error-handling',
        'guides/retries-and-timeouts',
        'guides/progress',
        'guides/conversations-and-vision',
        'guides/structured-output',
        'guides/testing',
        'guides/custom-provider',
        'guides/debugging',
        'guides/performance',
      ],
    },
    {
      type: 'category',
      label: 'Providers',
      link: { type: 'doc', id: 'providers/index' },
      items: [
        'providers/gemini',
        'providers/veo',
        'providers/openai',
        'providers/flux',
        'providers/elevenlabs',
        'providers/suno',
        'providers/claude',
        'providers/mistral',
        'providers/ollama',
      ],
    },
  ],
};

module.exports = sidebars;
