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
            editor.chain().focus().toggleHeading({ level: 1 }).run()
          }}
        >
          我是按钮1
        </button>
      </div>
      <div className="button-group">
        <button
          onClick={() => {
            editor.chain().focus().toggleHeading({ level: 2 }).run()
          }}
        >
          我是按钮2
        </button>
      </div>
      <div className="button-group">
        <button
          onClick={() => {
            editor.chain().focus().toggleHeading({ level: 3 }).run()
          }}
        >
          我是按钮3
        </button>
      </div>
      <div className="button-group">
        <button
          onClick={() => {
            editor.chain().focus().toggleHeading({ level: 4 }).run()
          }}
        >
          我是按钮4
        </button>
      </div>
      <div className="button-group">
        <button
          onClick={() => {
            editor.chain().focus().toggleHeading({ level: 5 }).run()
          }}
        >
          我是按钮5
        </button>
      </div>
      <div className="button-group">
        <button
          onClick={() => {
            editor.chain().focus().toggleHeading({ level: 6 }).run()
          }}
        >
          我是按钮6
        </button>
      </div>
    </div>
  )
}
