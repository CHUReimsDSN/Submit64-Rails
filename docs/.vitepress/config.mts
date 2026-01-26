import { defineConfig } from 'vitepress'
import { sidebar } from './generated/sidebar'
import { version } from './generated/version'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Submit64 - Rails",
  description: "Submit64 for Rails",
  base: '/Submit64-Rails/',
  themeConfig: {
    nav: [
      { text: 'Documentation', link: '/documentation/000_index' },
      { text: 'Définition API', link: '/api-definition/models' },
      { text: version, link: 'changelog' },
      { text: 'Submit64 - Vue', link: 'https://chureimsdsn.github.io/Submit64-Vue/' }
    ],

    sidebar,
    outlineTitle: 'Sur cette page',
    socialLinks: [
      { icon: 'github', link: 'https://github.com/CHUReimsDSN/Submit64-Rails' }
    ],
    docFooter: {
      prev: false,
      next: false
    },
    search: {
      provider: 'local',
      options: {
        translations: {
          button: {
            buttonText: 'Recherche'
          },
          modal: {
            footer: {
              navigateText: 'Naviguer',
              selectText: 'Sélectionner',
              closeText: 'Fermer',
            },
            noResultsText: 'Aucun résultat pour '
          },
          
        }
      }
    }
  },
})
