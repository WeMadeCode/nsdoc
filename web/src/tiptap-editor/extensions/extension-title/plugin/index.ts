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
  let suppressNextParagraphBeforeInput = false
  let suppressNextParagraphBeforeInputTimer: ReturnType<typeof setTimeout> | undefined

  const suppressNextParagraphBeforeInputOnce = () => {
    suppressNextParagraphBeforeInput = true
    if (suppressNextParagraphBeforeInputTimer) {
      clearTimeout(suppressNextParagraphBeforeInputTimer)
    }

    suppressNextParagraphBeforeInputTimer = setTimeout(() => {
      suppressNextParagraphBeforeInput = false
      suppressNextParagraphBeforeInputTimer = undefined
    }, 0)
  }

  const consumeParagraphBeforeInputSuppression = () => {
    if (!suppressNextParagraphBeforeInput) {
      return false
    }

    suppressNextParagraphBeforeInput = false
    if (suppressNextParagraphBeforeInputTimer) {
      clearTimeout(suppressNextParagraphBeforeInputTimer)
      suppressNextParagraphBeforeInputTimer = undefined
    }

    return true
  }

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
        if (event.key !== 'Enter' || event.isComposing || isComposing || event.keyCode === 229) {
          return false
        }

        const handled = insertParagraphAtDocumentStart(view)
        if (handled) {
          suppressNextParagraphBeforeInputOnce()
        }

        return handled
      },
      handleDOMEvents: {
        beforeinput(view, event) {
          const inputEvent = event as InputEvent
          if (isComposing || inputEvent.isComposing || !['insertParagraph', 'insertLineBreak'].includes(inputEvent.inputType)) {
            return false
          }

          if (consumeParagraphBeforeInputSuppression()) {
            event.preventDefault()
            return true
          }

          const handled = insertParagraphAtDocumentStart(view)
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
