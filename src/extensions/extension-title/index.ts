import { mergeAttributes, Node } from '@tiptap/core'
import { ReactNodeViewRenderer } from '@tiptap/react'
import TitleWrapper from './title-wrpper'
import { Plugin } from '@tiptap/pm/state'
import { Selection } from '@tiptap/pm/state'

export const Title = Node.create({
  name: 'title',
  defining: true,
  isolating: true,
  priority: 1000,
  content: 'inline*',
  group: 'block',
  allowGapCursor: true,

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
    const { editor } = this
    const plugin = new Plugin({
      props: {
        handleKeyDown(view, event) {
          if (event.key === 'Enter') {
            const { state, dispatch } = view
            const { selection } = state
            const { $from, $to } = selection
            // 如果光标在标题的最后，按下 Enter 键时，插入一个新的段落
            console.log('xxx = ', $from.parent.type.name)
            if ($from.parent.type.name === 'title') {
              const paragraph = state.schema.nodes.paragraph.create()
              console.log('paragraph = ', paragraph)
              const tr = state.tr.insert($to.pos + 1, paragraph)
              tr.setSelection(Selection.near(tr.doc.resolve($to.pos + 1)))
              // 更新编辑器状态
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
