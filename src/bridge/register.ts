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
  dsbridge.register('setContent', (param: { content: string; isFocus: boolean }) => {
    const { content, isFocus } = param
    if (isFocus) {
      editor.chain().focus().setContent(JSON.parse(content)).run()
    } else {
      editor.chain().setContent(JSON.parse(content)).run()
    }
  })

  // 获取文档标题
  dsbridge.register('getDocTitle', () => {
    return editor.state.doc.firstChild?.textContent ?? ''
  })

  // 设置粗体
  dsbridge.register('toggleBold', () => {
    return editor.chain().focus().toggleBold().run()
  })

  // 设置斜体
  dsbridge.register('toggleItalic', () => {
    return editor.chain().focus().toggleItalic().run()
  })
  // 设置下划线
  dsbridge.register('toggleUnderline', () => {
    return editor.chain().focus().toggleUnderline().run()
  })
  // 设置删除线
  dsbridge.register('toggleStrike', () => {
    return editor.chain().focus().toggleStrike().run()
  })
  // 设置代码
  dsbridge.register('toggleCode', () => {
    return editor.chain().focus().toggleCode().run()
  })
  // 设置前景颜色
  dsbridge.register('setColor', (param: { color?: string; clear?: boolean }) => {
    const { clear, color } = param
    if (clear) {
      return editor.chain().focus().unsetColor().run()
    } else if (color) {
      return editor.chain().focus().setColor(color).run()
    }
  })
  // 设置背景色
  dsbridge.register('setBackgroundColor', (param: { color?: string; clear?: boolean }) => {
    const { clear, color } = param
    if (clear) {
      return editor.chain().focus().unsetBackgroundColor().run()
    } else if (color) {
      return editor.chain().focus().setBackgroundColor(color).run()
    }
  })

  // 设置对齐方式
  dsbridge.register('setTextAlign', (alignment: 'left' | 'right' | 'center' | 'justify') => {
    return editor.chain().focus().setTextAlign(alignment).run()
  })

  // 插入表格
  dsbridge.register('insertTable', () => {
    return editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
  })

  // 插入横线
  dsbridge.register('setHorizontalRule', () => {
    return editor.chain().setHorizontalRule().run()
  })
}
