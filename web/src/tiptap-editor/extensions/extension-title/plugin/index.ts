import { Plugin, TextSelection } from '@tiptap/pm/state'
import type { EditorView } from '@tiptap/pm/view'

const normalizeTitleText = (text: string) => text.replace(/\s*\r?\n\s*/g, ' ')

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
  let isComposing = false

  const moveSelectionToBody = (view: EditorView) => {
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
    const nodeAfterTitle = state.doc.nodeAt(titleEnd)
    let tr = state.tr
    const paragraphStart = titleEnd + 1

    if (nodeAfterTitle?.type.name !== 'paragraph' || nodeAfterTitle.content.size > 0) {
      const paragraph = state.schema.nodes.paragraph.create()
      tr = tr.insert(titleEnd, paragraph)
    }

    tr.setSelection(TextSelection.create(tr.doc, paragraphStart))
    dispatch(tr.scrollIntoView())
    return true
  }

  return new Plugin({
    props: {
      handleKeyDown(view, event) {
        if (event.key !== 'Enter' || event.isComposing || isComposing || event.keyCode === 229) {
          return false
        }

        return moveSelectionToBody(view)
      },
      handleDOMEvents: {
        beforeinput(view, event) {
          const inputEvent = event as InputEvent
          if (isComposing || inputEvent.isComposing || !['insertParagraph', 'insertLineBreak'].includes(inputEvent.inputType)) {
            return false
          }

          const handled = moveSelectionToBody(view)
          if (handled) {
            event.preventDefault()
          }

          return handled
        },
        compositionstart() {
          isComposing = true
          return false
        },
        compositionend() {
          isComposing = false
          return false
        },
      },
      handlePaste(view, event) {
        const text = event.clipboardData?.getData('text/plain')
        if (!text || !/[\r\n]/.test(text)) {
          return false
        }

        const { state, dispatch } = view
        const { $from } = state.selection

        for (let depth = $from.depth; depth > 0; depth -= 1) {
          if ($from.node(depth).type.name === titleNodeName) {
            dispatch(state.tr.insertText(normalizeTitleText(text)))
            return true
          }
        }

        return false
      },
    },
  })
}
