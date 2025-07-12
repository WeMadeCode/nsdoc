// import React from "react";

import { EditorContent, useEditor } from '@tiptap/react'
import styles from './index.module.scss'

import { extensions } from '../extensions/index'

const Editor = () => {
  const editor = useEditor({
    extensions: extensions,
    // content: content,
  })

  return (
    <div
      className={styles.wrap}
      onClick={() => {
        editor?.chain().focus().run()
      }}
      onTouchEnd={() => {
        editor?.chain().focus().run()
      }}
    >
      <EditorContent editor={editor} />
    </div>
  )
}

export default Editor
