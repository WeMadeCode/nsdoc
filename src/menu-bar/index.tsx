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
            const obj = {
              type: 'doc',
              content: [
                {
                  type: 'title',
                  content: [
                    {
                      type: 'text',
                      text: '111',
                    },
                  ],
                },
                {
                  type: 'paragraph',
                  content: [
                    {
                      type: 'text',
                      text: 'bbb',
                    },
                  ],
                },
                {
                  type: 'paragraph',
                },
              ],
            }
            editor
              .chain()
              .focus()
              .setContent(JSON.parse(JSON.stringify(obj)))
              .run()
          }}
        >
          我是按钮2
        </button>
      </div>
    </div>
  )
}
