import { Node } from '@tiptap/core'
import { ReactNodeViewRenderer } from '@tiptap/react'

import { createTitlePlugin } from './plugin'
import TitleWrapper from './title-wrpper'

export const Title = Node.create({
  name: 'title',
  defining: true,
  priority: 1000,
  content: 'text*',

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
    return [createTitlePlugin(this.name)]
  },
})
