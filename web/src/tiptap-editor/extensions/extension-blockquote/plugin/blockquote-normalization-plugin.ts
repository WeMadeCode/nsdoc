import { Plugin, PluginKey } from '@tiptap/pm/state'

export const createBlockquoteNormalizationPlugin = (blockquoteName: string) =>
  new Plugin({
    key: new PluginKey('blockquoteNormalization'),
    appendTransaction(transactions, _oldState, newState) {
      if (!transactions.some(transaction => transaction.docChanged)) {
        return null
      }

      const rangesToDelete: Array<{ from: number; to: number }> = []

      newState.doc.descendants((node, pos) => {
        if (node.type.name !== blockquoteName || node.childCount < 2) {
          return true
        }

        const firstChild = node.child(0)
        const secondChild = node.child(1)

        if (
          firstChild.type.name === 'paragraph' &&
          secondChild.type.name === 'paragraph' &&
          firstChild.textContent.trim().length === 0 &&
          secondChild.textContent.trim().length > 0
        ) {
          rangesToDelete.push({
            from: pos + 1,
            to: pos + 1 + firstChild.nodeSize,
          })
        }

        return true
      })

      if (rangesToDelete.length === 0) {
        return null
      }

      const tr = newState.tr

      rangesToDelete
        .sort((a, b) => b.from - a.from)
        .forEach(range => {
          tr.delete(range.from, range.to)
        })

      return tr
    },
  })
