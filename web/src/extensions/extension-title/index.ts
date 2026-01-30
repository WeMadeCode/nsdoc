import { Node } from '@tiptap/core'
import { ReactNodeViewRenderer } from '@tiptap/react'
import TitleWrapper from './title-wrpper'
import { Plugin } from '@tiptap/pm/state'
import { Selection } from '@tiptap/pm/state'

export const Title = Node.create({
  name: 'title',
  defining: true,
  isolating: true,
  priority: 1000,
  content: 'text*',
  group: 'block',

  addOptions() {
    return {
      HTMLAttributes: {},
    }
  },

  parseHTML() {
    return [{ tag: 'div[data-type="title"]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', { ...HTMLAttributes, 'data-type': 'title' }, 0]
  },

  addNodeView() {
    return ReactNodeViewRenderer(TitleWrapper)
  },

  addProseMirrorPlugins() {
    const plugin = new Plugin({
      props: {
        handleKeyDown(view, event) {
          if (event.key === 'Enter') {
            const { state, dispatch } = view
            const { selection } = state
            const { $from } = selection
            const node = $from.parent
            const isTitle = node.type.name === 'title'
            if (isTitle) {
              const paragraph = state.schema.nodes.paragraph.create()
              const to = node.nodeSize
              const tr = state.tr.insert(to, paragraph)
              tr.setSelection(Selection.near(tr.doc.resolve(to)))
              dispatch(tr)
              return true
            }
          }
        },
      },
    })

    return [plugin]
  },
})
