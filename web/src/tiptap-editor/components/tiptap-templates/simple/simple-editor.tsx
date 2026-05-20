'use client'

import '@/tiptap-editor/components/tiptap-node/blockquote-node/blockquote-node.scss'
import '@/tiptap-editor/components/tiptap-node/code-block-node/code-block-node.scss'
import '@/tiptap-editor/components/tiptap-node/horizontal-rule-node/horizontal-rule-node.scss'
import '@/tiptap-editor/components/tiptap-node/list-node/list-node.scss'
import '@/tiptap-editor/components/tiptap-node/image-node/image-node.scss'
import '@/tiptap-editor/components/tiptap-node/heading-node/heading-node.scss'
import '@/tiptap-editor/components/tiptap-node/paragraph-node/paragraph-node.scss'
// --- Styles ---
import '@/tiptap-editor/components/tiptap-templates/simple/simple-editor.scss'

import { EditorContent, EditorContext, useEditor } from '@tiptap/react'
import { useEffect } from 'react'

// --- Tiptap Node ---
import { ImageUploadNode } from '@/tiptap-editor/components/tiptap-node/image-upload-node/image-upload-node-extension'
// --- Lib ---
import { setupBridge } from '@/bridge'
import { extensions as baseExtensions } from '@/extensions'
import { handleImageUpload, MAX_FILE_SIZE } from '@/tiptap-editor/lib/tiptap-utils'

export function SimpleEditor() {
  const editor = useEditor({
    immediatelyRender: false,
    editorProps: {
      attributes: {
        autocomplete: 'off',
        autocorrect: 'off',
        autocapitalize: 'off',
        'aria-label': 'Main content area, start typing to enter text.',
        class: 'simple-editor',
      },
    },
    extensions: [
      ...baseExtensions,
      ImageUploadNode.configure({
        accept: 'image/*',
        maxSize: MAX_FILE_SIZE,
        limit: 3,
        upload: handleImageUpload,
      }),
    ],
  })

  useEffect(() => {
    return setupBridge(editor)
  }, [editor])

  return (
    <div className="simple-editor-wrapper">
      <EditorContext.Provider value={{ editor }}>
        <EditorContent editor={editor} role="presentation" className="simple-editor-content" />
      </EditorContext.Provider>
    </div>
  )
}
