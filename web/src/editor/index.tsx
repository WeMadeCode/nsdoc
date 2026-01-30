import { EditorContent, isAndroid, useEditor } from '@tiptap/react'
import styles from './index.module.scss'
import { setupBridge } from '../bridge'

import { extensions } from '../extensions/index'
import { useEffect } from 'react'
import { useBlockListen } from '../hooks/useBlockListen'

import { MenuBar } from '../menu-bar'

import { isiOS } from '@tiptap/react'

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
      onClick={e => {
        const target = e.target as HTMLElement
        const res = editor?.view.dom.contains(target)
        if (!res) {
          editor?.chain().focus().run()
        }
      }}
    >
      {!(isiOS() || isAndroid()) && <MenuBar editor={editor} />}
      <EditorContent editor={editor} />
    </div>
  )
}

export default Editor
