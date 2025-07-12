import { EditorContent, useEditor } from '@tiptap/react'
import styles from './index.module.scss'
import { setupBridge } from '../bridge'

import { extensions } from '../extensions/index'
import { useEffect } from 'react'

const Editor = () => {
  const editor = useEditor({
    extensions: extensions,
  })

  useEffect(() => {
    setupBridge(editor)
  }, [editor])

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
