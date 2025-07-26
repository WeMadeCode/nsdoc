import { EditorContent, useEditor } from '@tiptap/react'
import styles from './index.module.scss'
import {
  setupBridge,
  headingListener,
  paragraphListener,
  orderedListener,
  bulletListener,
  taskListener,
  codeBlockListener,
  blockQuoteListener,
} from '../bridge'

import { extensions } from '../extensions/index'
import { useEffect } from 'react'
import { useNodeActive } from '../hooks/useNodeActive'
import Heading from '@tiptap/extension-heading'
import Paragraph from '@tiptap/extension-paragraph'
import OrderedList from '@tiptap/extension-ordered-list'
import BulletList from '@tiptap/extension-bullet-list'
// import { MenuBar } from '../menu-bar'
import TaskList from '@tiptap/extension-task-list'
import CodeBlock from '@tiptap/extension-code-block'
import Blockquote from '@tiptap/extension-blockquote'

const Editor = () => {
  const editor = useEditor({
    extensions: extensions,
  })

  const isHeadingState = useNodeActive(editor, Heading.name)
  const isParagraphState = useNodeActive(editor, Paragraph.name)
  const isOrderState = useNodeActive(editor, OrderedList.name)
  const isButtetState = useNodeActive(editor, BulletList.name)
  const isTaskState = useNodeActive(editor, TaskList.name)
  const isCodeBlockState = useNodeActive(editor, CodeBlock.name)
  const isBlockquoteState = useNodeActive(editor, Blockquote.name)

  useEffect(() => {
    headingListener(isHeadingState)
  }, [isHeadingState])

  useEffect(() => {
    paragraphListener(isParagraphState)
  }, [isParagraphState])

  useEffect(() => {
    paragraphListener(isParagraphState)
  }, [isParagraphState])

  useEffect(() => {
    blockQuoteListener(isBlockquoteState)
  }, [isBlockquoteState])

  useEffect(() => {
    codeBlockListener(isCodeBlockState)
  }, [isCodeBlockState])

  useEffect(() => {
    taskListener(isTaskState)
  }, [isTaskState])

  useEffect(() => {
    orderedListener(isOrderState)
  }, [isOrderState])

  useEffect(() => {
    bulletListener(isButtetState)
  }, [isButtetState])

  useEffect(() => {
    setupBridge(editor)
  }, [editor])

  return (
    <div
      className={styles.wrap}
      onClick={() => {
        editor?.chain().focus(3).run()
      }}
      onTouchEnd={() => {
        editor?.chain().focus(3).run()
      }}
    >
      {/* <MenuBar editor={editor} /> */}
      <EditorContent editor={editor} />
    </div>
  )
}

export default Editor
