import { EditorContent, useEditor } from '@tiptap/react'
import styles from './index.module.scss'
import { setupBridge } from '../bridge'

import { extensions } from '../extensions/index'
import { useEffect } from 'react'
import { useBlockListen } from '../hooks/useBlockListen'

import { MenuBar } from '../menu-bar'

const Editor = () => {
  const editor = useEditor({
    extensions: extensions,
  })

  useBlockListen(editor)

  // @ts-expect-error 为了方便调试
  window.editor = editor

  useEffect(() => {
    setupBridge(editor)
  }, [editor])

  return (
    <div
      className={styles.wrap}
      onClick={() => {
        editor?.chain().focus().run()
      }}
    >
      <MenuBar editor={editor} />
      <EditorContent editor={editor} />
    </div>
  )
}

export default Editor
