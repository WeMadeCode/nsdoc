import type { Editor } from '@tiptap/core'
import type { Level } from '@tiptap/extension-heading'
import dsbridge from 'dsbridge'
import type { NodeActiveType } from '../hooks/useNodeActive'

export const headingListener = (type: NodeActiveType) => {
  console.log('type = ', type)
  const obj = {
    active: type.active,
    level: type.attributes?.level,
  }
  dsbridge.call('headingActive', obj)
}

export const setupBridge = (editor: Editor | null) => {
  if (!editor) {
    return
  }

  // 插入标题
  dsbridge.register('insertHeading', (level: Level) => {
    console.log('dsbridge insertHeading called with level:', level)
    return editor.chain().focus().setHeading({ level }).run()
  })
}
