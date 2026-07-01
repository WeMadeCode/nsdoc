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
import '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor.scss'

import { EditorContent, EditorContext, useEditor } from '@tiptap/react'
import { useContext, useEffect } from 'react'
import { createPortal } from 'react-dom'
import type { Doc as YDoc } from 'yjs'

import { setupBridge } from '@/bridge'
import { TableCellHandleMenu } from '@/tiptap-editor/components/tiptap-node/table-node/ui/table-cell-handle-menu'
import { TableExtendRowColumnButtons } from '@/tiptap-editor/components/tiptap-node/table-node/ui/table-extend-row-column-button'
import { TableHandle } from '@/tiptap-editor/components/tiptap-node/table-node/ui/table-handle/table-handle'
import { TableSelectionOverlay } from '@/tiptap-editor/components/tiptap-node/table-node/ui/table-selection-overlay'
import { TocSidebar } from '@/tiptap-editor/components/tiptap-node/toc-node'
import { TocProvider, useToc } from '@/tiptap-editor/components/tiptap-node/toc-node/context/toc-context'
// --- Content ---
import { NotionEditorHeader } from '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor-header'
import { MobileToolbar } from '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor-mobile-toolbar'
import { NotionToolbarFloating } from '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor-toolbar-floating'
import { SetupErrorMessage } from '@/tiptap-editor/components/tiptap-templates/notion-like/setup-error-message'
import { useScrollToHash } from '@/tiptap-editor/components/tiptap-ui/copy-anchor-link-button/use-scroll-to-hash'
import { DragContextMenu } from '@/tiptap-editor/components/tiptap-ui/drag-context-menu'
// --- Tiptap UI ---
import { EmojiDropdownMenu } from '@/tiptap-editor/components/tiptap-ui/emoji-dropdown-menu'
import { MentionDropdownMenu } from '@/tiptap-editor/components/tiptap-ui/mention-dropdown-menu'
import { SlashDropdownMenu } from '@/tiptap-editor/components/tiptap-ui/slash-dropdown-menu'
import { AiProvider, useAi } from '@/tiptap-editor/contexts/ai-context'
// --- Contexts ---
import { AppProvider } from '@/tiptap-editor/contexts/app-context'
import { CollabProvider, useCollab } from '@/tiptap-editor/contexts/collab-context'
import { UserProvider, useUser } from '@/tiptap-editor/contexts/user-context'
import { createEditorExtensions } from '@/tiptap-editor/extensions'
// --- Hooks ---
import { useUiEditorState } from '@/tiptap-editor/hooks/use-ui-editor-state'

export interface NotionEditorProps {
  room: string
  placeholder?: string
}

export interface EditorProviderProps {
  provider: unknown
  ydoc: YDoc
  placeholder?: string
  hasCollab: boolean
}

/**
 * Loading spinner component shown while connecting to the notion server
 */
export function LoadingSpinner({ text = 'Connecting...' }: { text?: string }) {
  return (
    <div className="spinner-container">
      <div className="spinner-content">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle cx="12" cy="12" r="10"></circle>
          <path d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <div className="spinner-loading-text">{text}</div>
      </div>
    </div>
  )
}

/**
 * EditorContent component that renders the actual editor
 */
export function EditorContentArea() {
  const { editor } = useContext(EditorContext)!
  const { aiGenerationIsLoading, aiGenerationIsSelection, aiGenerationHasMessage, isDragging } = useUiEditorState(editor)

  // Selection based effect to handle AI generation acceptance
  useEffect(() => {
    if (!editor) {
      return
    }

    if (!aiGenerationIsLoading && aiGenerationIsSelection && aiGenerationHasMessage) {
      // AI commands are provided by the private @tiptap-pro/extension-ai package.
      // Keep the state reset path harmless for local builds without that package.
      editor.commands.resetUiState()
    }
  }, [aiGenerationHasMessage, aiGenerationIsLoading, aiGenerationIsSelection, editor])

  useScrollToHash()

  if (!editor) {
    return null
  }

  return (
    <EditorContent
      editor={editor}
      role="presentation"
      className="notion-like-editor-content"
      style={{
        cursor: isDragging ? 'grabbing' : 'auto',
      }}
    >
      <DragContextMenu />
      <EmojiDropdownMenu />
      <MentionDropdownMenu />
      <SlashDropdownMenu />
      <NotionToolbarFloating />
      {createPortal(<MobileToolbar />, document.body)}
    </EditorContent>
  )
}

/**
 * Component that creates and provides the editor instance
 */
export function EditorProvider(props: EditorProviderProps) {
  const { provider, ydoc, placeholder = 'Start writing...', hasCollab } = props

  const { user } = useUser()
  const { setTocContent } = useToc()

  const editor = useEditor({
    immediatelyRender: false,
    editorProps: {
      attributes: {
        class: 'notion-like-editor',
      },
    },
    extensions: createEditorExtensions({ hasCollab, placeholder, provider, setTocContent, user, ydoc }),
  })

  useEffect(() => {
    return setupBridge(editor)
  }, [editor])

  if (!editor) {
    return <LoadingSpinner />
  }

  return (
    <div className="notion-like-editor-wrapper">
      <EditorContext.Provider value={{ editor }}>
        <NotionEditorHeader />
        <div className="notion-like-editor-layout">
          <EditorContentArea />
          <TocSidebar topOffset={48} />
        </div>

        <TableExtendRowColumnButtons />
        <TableHandle />
        <TableSelectionOverlay
          showResizeHandles={true}
          cellMenu={props => <TableCellHandleMenu editor={props.editor} onMouseDown={e => props.onResizeStart?.('br')(e)} />}
        />
      </EditorContext.Provider>
    </div>
  )
}

/**
 * Full editor with all necessary providers, ready to use with just a room ID
 */
export function NotionEditor({ room, placeholder = 'Start writing...' }: NotionEditorProps) {
  return (
    <UserProvider>
      <AppProvider>
        <CollabProvider room={room}>
          <AiProvider>
            <TocProvider>
              <NotionEditorContent placeholder={placeholder} />
            </TocProvider>
          </AiProvider>
        </CollabProvider>
      </AppProvider>
    </UserProvider>
  )
}

/**
 * Internal component that handles the editor loading state
 */
export function NotionEditorContent({ placeholder }: { placeholder?: string }) {
  const { provider, ydoc, hasCollab, setupError: collabSetupError } = useCollab()
  const { setupError: aiSetupError } = useAi()

  // Show setup error if either collab or AI setup failed
  if (collabSetupError || aiSetupError) {
    return <SetupErrorMessage aiSetupError={aiSetupError} collabSetupError={collabSetupError} />
  }

  const collabIsReady = !hasCollab || !!provider
  if (!collabIsReady) {
    return <LoadingSpinner />
  }

  return <EditorProvider provider={provider} ydoc={ydoc} placeholder={placeholder} hasCollab={hasCollab} />
}
