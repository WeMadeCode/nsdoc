'use client'

import '@/tiptap-editor/components/tiptap-node/table-node/styles/prosemirror-table.scss'
import '@/tiptap-editor/components/tiptap-node/table-node/styles/table-node.scss'
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

// --- Lib ---
import { setupBridge } from '@/bridge'
// --- Tiptap Node ---
import { TableCellHandleMenu } from '@/tiptap-editor/components/tiptap-node/table-node/ui/table-cell-handle-menu'
import { TableExtendRowColumnButtons } from '@/tiptap-editor/components/tiptap-node/table-node/ui/table-extend-row-column-button'
import { TableHandle } from '@/tiptap-editor/components/tiptap-node/table-node/ui/table-handle/table-handle'
import { TableSelectionOverlay } from '@/tiptap-editor/components/tiptap-node/table-node/ui/table-selection-overlay'
import { extensions as baseExtensions } from '@/tiptap-editor/extensions'

// import TextView from './text-view'

export function SimpleEditor() {
  const editor = useEditor({
    immediatelyRender: true,
    editorProps: {
      attributes: {
        autocomplete: 'off',
        autocorrect: 'off',
        autocapitalize: 'off',
        'aria-label': 'Main content area, start typing to enter text.',
        class: 'simple-editor',
      },
    },
    extensions: baseExtensions,
  })

  useEffect(() => {
    return setupBridge(editor)
  }, [editor])

  return (
    <div className="simple-editor-wrapper">
      <EditorContext.Provider value={{ editor }}>
        <EditorContent editor={editor} role="presentation" className="simple-editor-content" />
        <TableExtendRowColumnButtons />
        <TableHandle />
        <TableSelectionOverlay
          showResizeHandles={true}
          cellMenu={props => <TableCellHandleMenu editor={props.editor} onMouseDown={event => props.onResizeStart?.('br')(event)} />}
        />
      </EditorContext.Provider>
      {/* <TextView editor={editor}></TextView> */}
    </div>
  )
}
