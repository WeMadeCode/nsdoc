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
            editor.chain().focus().toggleCode().run()
          }}
        >
          我是按钮
        </button>
      </div>
    </div>
  )
}
