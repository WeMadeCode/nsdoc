import { EditorContent, useEditor } from '@tiptap/react'
import styles from './index.module.scss'
import { setupBridge, headingListener, paragraphListener, orderedListener, bulletListener } from '../bridge'

import { extensions } from '../extensions/index'
import { useEffect } from 'react'
import { useNodeActive } from '../hooks/useNodeActive'
import Heading from '@tiptap/extension-heading'
import Paragraph from '@tiptap/extension-paragraph'
import OrderedList from '@tiptap/extension-ordered-list'
import BulletList from '@tiptap/extension-bullet-list'
import { MenuBar } from '../menu-bar'

const Editor = () => {
  const editor = useEditor({
    extensions: extensions,
  })

  const isHeadingState = useNodeActive(editor, Heading.name)
  const isParagraphState = useNodeActive(editor, Paragraph.name)
  const isOrderState = useNodeActive(editor, OrderedList.name)
  const isButtetState = useNodeActive(editor, BulletList.name)

  headingListener(isHeadingState)
  paragraphListener(isParagraphState)
  orderedListener(isOrderState)
  bulletListener(isButtetState)

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
      <MenuBar editor={editor} />
      <EditorContent editor={editor} />
    </div>
  )
}

export default Editor
