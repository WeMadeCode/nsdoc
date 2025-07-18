import type { Editor } from '@tiptap/core'

interface Props {
  editor: Editor | null
}

export const MenuBar = (props: Props) => {
  const { editor } = props

  if (!editor) {
    return null
  }

  return (
    <div className="control-group">
      <div className="button-group">
        <button
          onClick={() => {
            console.log(editor.getJSON())
          }}
        >
          我是按钮
        </button>
        <button
          onClick={() => {
            // nodeBetW
            const firstNode = editor.state.doc.firstChild
            console.log('xx = ', firstNode?.textContent)
          }}
        >
          我是按钮2
        </button>
      </div>
    </div>
  )
}
