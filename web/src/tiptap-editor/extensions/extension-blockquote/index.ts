import BaseBlockquote from '@tiptap/extension-blockquote'

import { createBlockquoteNormalizationPlugin } from './plugin/blockquote-normalization-plugin'

export const Blockquote = BaseBlockquote.extend({
  addProseMirrorPlugins() {
    return [createBlockquoteNormalizationPlugin(this.name)]
  },
})
