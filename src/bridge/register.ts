import type { Editor } from '@tiptap/core'
import type { Level } from '@tiptap/extension-heading'
import dsbridge from 'dsbridge'

export const setupBridge = (editor: Editor | null) => {
  if (!editor) {
    return
  }

  // 插入标题
  dsbridge.register('toggleHeading', (level: Level) => {
    return editor.chain().focus().toggleHeading({ level }).run()
  })

  // 清空段落
  dsbridge.register('clearParagraph', () => {
    return editor.chain().focus().clearNodes().run()
  })

  // 有序列表
  dsbridge.register('toggleOrderedList', () => {
    return editor.chain().focus().toggleOrderedList().run()
  })

  // 无序列表
  dsbridge.register('toggleBulletList', () => {
    return editor.chain().focus().toggleBulletList().run()
  })

  // 任务列表
  dsbridge.register('toggleTaskList', () => {
    return editor.chain().focus().toggleTaskList().run()
  })

  // 代码块
  dsbridge.register('toggleCodeBlcok', () => {
    return editor.chain().focus().toggleCodeBlock().run()
  })

  // 引用
  dsbridge.register('toggleBlockquote', () => {
    return editor.chain().focus().toggleBlockquote().run()
  })

  // 获取文档内容
  dsbridge.register('getContent', () => {
    return editor.getJSON()
  })

  // 设置文档内容
  dsbridge.register('setContent', (content: string) => {
    editor.chain().focus().setContent(JSON.parse(content)).run()
  })
}
