import DefaultTheme from 'vitepress/theme'
import { ThemePicker } from 'vitepress-bigbang'
import 'vitepress-bigbang/style.css'
import 'virtual:group-icons.css'

export default {
  extends: DefaultTheme,
  setup() {
    ThemePicker.setPrimary('Sky')
    ThemePicker.setSurface('Slate')
  }
}
