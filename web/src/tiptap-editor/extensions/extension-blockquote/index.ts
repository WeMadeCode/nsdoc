import BaseBlockquote from '@tiptap/extension-blockquote'

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
        ({ commands }) => {
          if (this.editor.isActive(this.name)) {
            return commands.lift(this.name)
          }

          return commands.wrapIn(this.name)
        },
      unsetBlockquote:
        () =>
        ({ commands }) => {
          return commands.lift(this.name)
        },
    }
  },
})
