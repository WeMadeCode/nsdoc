import type { Editor } from '@tiptap/core'
import type { Level } from '@tiptap/extension-heading'
import dsbridge from 'dsbridge'

export const setupBridge = (editor: Editor | null) => {
  if (!editor) {
    return
  }

  // 插入标题
  dsbridge.register('insertHeading', (level: Level) => {
    return editor.chain().focus().setHeading({ level }).run()
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
}
