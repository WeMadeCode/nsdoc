import OrderedList from '@tiptap/extension-ordered-list'
import { Placeholder as PlaceholderTiptap } from '@tiptap/extension-placeholder'
import { Table } from '@tiptap/extension-table'
import TaskList from '@tiptap/extension-task-list'
import type { Node as ProseMirrorNode } from '@tiptap/pm/model'

import { Title } from '../extension-title'

const suppressedPlaceholderNodes = new Set([TaskList.name, OrderedList.name, Table.name, Title.name])

const firstBodyNodePos = (doc: ProseMirrorNode): number | null => {
  let pos = 0

  for (let index = 0; index < doc.childCount; index += 1) {
    const node = doc.child(index)

    if (node.type.name !== Title.name) {
      return pos
    }

    pos += node.nodeSize
  }

  return null
}

export const Placeholder = PlaceholderTiptap.configure({
  placeholder(props) {
    const { editor, node, pos } = props
    const name = node.type.name

    if (suppressedPlaceholderNodes.has(name)) {
      return ''
    }

    const doc = editor.state.doc
    if (pos !== firstBodyNodePos(doc)) {
      return ''
    }

    return '请输入正文'
  },
})
