import type { Editor } from '@tiptap/core'
import { useEffect } from 'react'
import { useActive } from './useActive'
import Heading from '@tiptap/extension-heading'
import Paragraph from '@tiptap/extension-paragraph'
import OrderedList from '@tiptap/extension-ordered-list'
import BulletList from '@tiptap/extension-bullet-list'
import TaskList from '@tiptap/extension-task-list'
import CodeBlock from '@tiptap/extension-code-block'
import Blockquote from '@tiptap/extension-blockquote'
import Bold from '@tiptap/extension-bold'

import {
  headingListener,
  paragraphListener,
  orderedListener,
  bulletListener,
  taskListener,
  codeBlockListener,
  blockQuoteListener,
  boldListener,
} from '../bridge'

export type ActiveType = {
  active: boolean
  attributes: Record<string, unknown> | undefined
}

export function useBlockListen(editor: Editor | null) {
  const isHeadingState = useActive(editor, Heading.name)
  const isParagraphState = useActive(editor, Paragraph.name)
  const isOrderState = useActive(editor, OrderedList.name)
  const isButtetState = useActive(editor, BulletList.name)
  const isTaskState = useActive(editor, TaskList.name)
  const isCodeBlockState = useActive(editor, CodeBlock.name)
  const isBlockquoteState = useActive(editor, Blockquote.name)
  const isBoldActive = useActive(editor, Bold.name)

  useEffect(() => {
    boldListener(isBoldActive)
  }, [isBoldActive])

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
}
