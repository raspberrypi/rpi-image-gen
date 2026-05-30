// @ts-check

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'rpi-image-gen',
  tagline: 'Raspberry Pi image generation',
  url: 'https://lorandmarton.github.io',
  baseUrl: '/rpi-image-gen/',

  organizationName: 'LorandMarton',
  projectName: 'rpi-image-gen',

  trailingSlash: true,
  onBrokenLinks: 'throw',
  onBrokenAnchors: 'throw',

  plugins: ['@asciidoc-js/docusaurus-asciidoc'],

  markdown: {
    format: 'detect',
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  themes: [
    [
      '@easyops-cn/docusaurus-search-local',
      {
        hashed: false,
        indexDocs: true,
        indexBlog: false,
        indexPages: false,
        docsRouteBasePath: 'docs',
        docsDir: 'generated-docs',
        language: ['en'],
        searchBarPosition: 'right',
        explicitSearchResultPath: true,
        highlightSearchTermsOnTargetPage: true,
      },
    ],
  ],

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          path: './generated-docs',
          routeBasePath: 'docs',
          include: ['**/*.{md,mdx,adoc}'],
          sidebarPath: './sidebars.js',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'rpi-image-gen',
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'docsSidebar',
            position: 'left',
            label: 'Docs',
          },
          {
            href: 'https://github.com/LorandMarton/rpi-image-gen',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              { label: 'Overview', to: '/docs/' },
              { label: 'Execution', to: '/docs/execution/' },
              { label: 'Configuration', to: '/docs/config/' },
              { label: 'Layers', to: '/docs/layer/' },
              { label: 'Provisioning', to: '/docs/provisioning/' },
            ],
          },
          {
            title: 'Project',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/LorandMarton/rpi-image-gen',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} rpi-image-gen.`,
      },
    }),
};

export default config;
