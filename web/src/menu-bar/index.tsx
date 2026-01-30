import { Divider } from '@douyinfe/semi-ui'

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
    <div>
      <button
        onClick={() => {
          editor.chain().focus().setTextAlign('left').run()
        }}
      >
        左对齐
      </button>
      <button
        onClick={() => {
          editor.chain().focus().setTextAlign('center').run()
        }}
      >
        居中对齐
      </button>
      <button
        onClick={() => {
          editor.chain().focus().setTextAlign('right').run()
        }}
      >
        右边对齐
      </button>
      <Divider margin="10px" />
      <button
        onClick={() => {
          editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
        }}
      >
        插入表格
      </button>
      <Divider margin="10px" />
      <button
        onClick={() => {
          editor.chain().focus().setBold().run()
        }}
      >
        Bold
      </button>
      <button onClick={() => editor.chain().focus().toggleItalic().run()}>Italic</button>
      <button onClick={() => editor.chain().focus().toggleStrike().run()}>Strike</button>
      <Divider margin="10px" />
    </div>
  )
}
