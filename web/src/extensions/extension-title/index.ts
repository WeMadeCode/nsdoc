import { Node } from '@tiptap/core'
import { ReactNodeViewRenderer } from '@tiptap/react'
import TitleWrapper from './title-wrpper'
import { Plugin, TextSelection } from '@tiptap/pm/state'

export const Title = Node.create({
  name: 'title',
  defining: true,
  isolating: true,
  priority: 1000,
  group: 'block',
  content: 'inline*',

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
    const titleNodeName = this.name
    const plugin = new Plugin({
      props: {
        handleKeyDown(view, event) {
          if (event.key === 'Enter') {
            const { state, dispatch } = view
            const { selection } = state
            const { $from } = selection
            let titleDepth = -1

            for (let depth = $from.depth; depth > 0; depth -= 1) {
              if ($from.node(depth).type.name === titleNodeName) {
                titleDepth = depth
                break
              }
            }

            if (titleDepth >= 0) {
              const titleEnd = $from.after(titleDepth)
              const paragraph = state.schema.nodes.paragraph.create()
              const tr = state.tr.insert(titleEnd, paragraph)
              tr.setSelection(TextSelection.create(tr.doc, titleEnd + 1))
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
