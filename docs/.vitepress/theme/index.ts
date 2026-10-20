import DefaultTheme from 'vitepress/theme'
import { ThemePicker } from 'vitepress-bigbang'
import 'vitepress-bigbang/style.css'
import 'virtual:group-icons.css'

export default {
  extends: DefaultTheme,
  setup() {
    if (typeof window === 'undefined') {
      return
    }
    ThemePicker.setPrimary('Sky')
    ThemePicker.setSurface('Slate')
  }
}
