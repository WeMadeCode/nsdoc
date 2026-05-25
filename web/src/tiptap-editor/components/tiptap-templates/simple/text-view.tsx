import { Editor } from '@tiptap/core'
import React from 'react'

interface TextViewProps {
  editor: Editor | null
}

const TextView: React.FC<TextViewProps> = props => {
  const { editor } = props
  return (
    <div style={{ position: 'fixed', bottom: '10px', left: '10px' }}>
      <button
        onMouseDown={event => {
          event.preventDefault()
        }}
        onClick={() => {
          editor
            ?.chain()
            .focus()
            .insertTable({
              rows: 3,
              cols: 3,
              withHeaderRow: true,
            })
            .run()
        }}
      >
        我是按钮
      </button>
    </div>
  )
}

export default TextView
