import { Editor } from '@tiptap/core'
import React from 'react'

interface TextViewProps {
  editor: Editor
}

const TextView: React.FC<TextViewProps> = props => {
  const { editor } = props
  return (
    <div style={{ position: 'fixed', bottom: '10px', left: '10px' }}>
      <button
        onClick={() => {
          editor.chain().focus().run()
        }}
      >
        我是按钮1
      </button>
    </div>
  )
}

export default TextView
