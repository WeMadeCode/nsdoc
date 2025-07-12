import { EditorContent, useEditor } from '@tiptap/react'
import styles from './index.module.scss'
import { setupBridge, headingListener } from '../bridge'

import { extensions } from '../extensions/index'
import { useEffect } from 'react'
import { useNodeActive } from '../hooks/useNodeActive'
import Heading from '@tiptap/extension-heading'

const Editor = () => {
  const editor = useEditor({
    extensions: extensions,
  })

  const isHeadingState = useNodeActive(editor, Heading.name)
  headingListener(isHeadingState)

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
