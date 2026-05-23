import BaseBlockquote from '@tiptap/extension-blockquote'
import { Plugin, PluginKey } from '@tiptap/pm/state'

const blockquoteNormalizationPluginKey = new PluginKey('blockquoteNormalization')

export const Blockquote = BaseBlockquote.extend({
  addCommands() {
    return {
      setBlockquote:
        () =>
        ({ commands }) => {
          return commands.wrapIn(this.name)
        },
      toggleBlockquote:
        () =>
        ({ commands, state }) => {
          if (this.editor.isActive(this.name)) {
            return commands.lift(this.name)
          }

          const { selection } = state
          const { $anchor } = selection

          for (let depth = $anchor.depth; depth > 0; depth -= 1) {
            const node = $anchor.node(depth)

            if (!node.isTextblock) {
              continue
            }

            return this.editor.chain().setNodeSelection($anchor.before(depth)).wrapIn(this.name).selectTextblockEnd().run()
          }

          return commands.toggleWrap(this.name)
        },
      unsetBlockquote:
        () =>
        ({ commands }) => {
          return commands.lift(this.name)
        },
    }
  },
})
