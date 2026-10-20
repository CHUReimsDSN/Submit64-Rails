import { defineConfig, mergeConfig, UserConfig } from "vitepress";
import { sidebar } from "./generated/sidebar.ts";
import { version } from "./generated/version.ts";
import { vitepressBigBangConfig, frenchTranslate } from "vitepress-bigbang";
import {
  groupIconMdPlugin,
  groupIconVitePlugin,
} from "vitepress-plugin-group-icons";

// https://vitepress.dev/reference/site-config
export default defineConfig(
  mergeConfig(vitepressBigBangConfig as UserConfig, {
    title: "Submit64",
    base: "/Submit64-Rails/",
    themeConfig: {
      logo: '/logo.svg',
      nav: [
        { text: version, link: "changelog" },
        {
          text: "Version Vue",
          link: "https://chureimsdsn.github.io/Submit64-Vue/",
        },
      ],
      mermaid: {},
      MermaidPlugin: {
        class: "mermaid mermaid-doc",
      },
      sidebar,
      socialLinks: [
        {
          icon: "github",
          link: "https://github.com/CHUReimsDSN/Submit64-Rails",
        },
      ],
      ...frenchTranslate,
    },
    markdown: {
      config(md) {
        md.use(groupIconMdPlugin);
      },
    },
    vite: {
      plugins: [groupIconVitePlugin()],
    },
  }),
);
