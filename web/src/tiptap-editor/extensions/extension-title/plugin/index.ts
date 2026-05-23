import { Plugin, TextSelection } from '@tiptap/pm/state'
import type { EditorView } from '@tiptap/pm/view'

const getTitleDepth = (selection: TextSelection, titleNodeName: string) => {
  const { $from } = selection

  for (let depth = $from.depth; depth > 0; depth -= 1) {
    if ($from.node(depth).type.name === titleNodeName) {
      return depth
    }
  }

  return -1
}

export const createTitlePlugin = (titleNodeName: string) => {
  const insertParagraphAtDocumentStart = (view: EditorView) => {
    const { state, dispatch } = view
    const selection = state.selection

    if (!(selection instanceof TextSelection)) {
      return false
    }

    const titleDepth = getTitleDepth(selection, titleNodeName)
    if (titleDepth < 0) {
      return false
    }

    const titleEnd = selection.$from.after(titleDepth)
    const paragraph = state.schema.nodes.paragraph.create()
    let tr = state.tr.insert(titleEnd, paragraph)

    tr = tr.setSelection(TextSelection.create(tr.doc, titleEnd + 1))
    dispatch(tr.scrollIntoView())
    return true
  }

  return new Plugin({
    props: {
      handleKeyDown(view, event) {
        if (event.key !== 'Enter' || event.isComposing || event.keyCode === 229) {
          return false
        }

        return insertParagraphAtDocumentStart(view)
      },
    },
  })
}
