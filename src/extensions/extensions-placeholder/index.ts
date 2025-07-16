import { Placeholder as PlaceholderTiptap } from '@tiptap/extension-placeholder'
import TaskList from '@tiptap/extension-task-list'
import { Title } from '../extension-title'
import OrderedList from '@tiptap/extension-ordered-list'

export const Placeholder = PlaceholderTiptap.configure({
  placeholder(props) {
    const { node } = props
    const name = node.type.name
    console.log('name = ', name)
    if (name === TaskList.name || name === OrderedList.name) {
      return ''
    } else if (name === Title.name) {
      return '请输入标题'
    } else {
      return '请输入正文'
    }
  },
})
