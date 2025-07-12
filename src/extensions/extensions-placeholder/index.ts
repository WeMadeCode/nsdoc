import { Placeholder as PlaceholderTiptap } from '@tiptap/extension-placeholder'

export const Placeholder = PlaceholderTiptap.configure({
  placeholder(props) {
    const { node } = props
    console.log('1--------', node.type.name)
    if (node.type.name === 'title') {
      return '请输入标题'
    } else {
      return '请输入正文'
    }
  },
})
