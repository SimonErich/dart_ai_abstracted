import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

// Project pages live under the repository name.
export default defineConfig({
  site: 'https://simonerich.github.io',
  base: '/dart_ai_abstracted',
  integrations: [
    starlight({
      title: 'ai_abstracted',
      description:
        'Provider-agnostic generative AI for Dart: one set of contracts for text, image, video, speech, sound effects, and music.',
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/SimonErich/dart_ai_abstracted',
        },
      ],
      sidebar: [
        {
          label: 'Start here',
          items: [
            { label: 'Overview', link: '/' },
            { label: 'Installation', link: '/getting-started/installation/' },
            { label: 'Your first request', link: '/getting-started/your-first-request/' },
            { label: 'Core concepts', link: '/getting-started/core-concepts/' },
          ],
        },
        {
          label: 'Guides',
          items: [
            { label: 'Result types', link: '/guides/result-types/' },
            { label: 'Credentials and configuration', link: '/guides/credentials/' },
            { label: 'The provider registry', link: '/guides/the-registry/' },
            { label: 'Error handling', link: '/guides/error-handling/' },
            { label: 'Retries and timeouts', link: '/guides/retries-and-timeouts/' },
            { label: 'Progress and long jobs', link: '/guides/progress/' },
            { label: 'Conversations and vision', link: '/guides/conversations-and-vision/' },
            { label: 'Structured output', link: '/guides/structured-output/' },
            { label: 'Testing', link: '/guides/testing/' },
            { label: 'Writing your own provider', link: '/guides/custom-provider/' },
            { label: 'Debugging', link: '/guides/debugging/' },
            { label: 'Performance and cost', link: '/guides/performance/' },
          ],
        },
        {
          label: 'Providers',
          items: [
            { label: 'Overview', link: '/providers/' },
            { label: 'Google Gemini', link: '/providers/gemini/' },
            { label: 'Google Veo', link: '/providers/veo/' },
            { label: 'OpenAI', link: '/providers/openai/' },
            { label: 'Black Forest Labs FLUX', link: '/providers/flux/' },
            { label: 'ElevenLabs', link: '/providers/elevenlabs/' },
            { label: 'Suno', link: '/providers/suno/' },
            { label: 'Anthropic Claude', link: '/providers/claude/' },
            { label: 'Mistral', link: '/providers/mistral/' },
            { label: 'Ollama', link: '/providers/ollama/' },
          ],
        },
      ],
    }),
  ],
});
