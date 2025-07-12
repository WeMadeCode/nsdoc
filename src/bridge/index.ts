import type { Editor } from '@tiptap/core'
import type { Level } from '@tiptap/extension-heading'
import dsbridge from 'dsbridge'

export const setupBridge = (editor: Editor | null) => {
  if (!editor) {
    return
  }
  dsbridge.register('insertHeading', (level: Level) => {
    console.log('dsbridge insertHeading called with level:', level)
    return editor.chain().focus().setHeading({ level }).run()
  })
}
