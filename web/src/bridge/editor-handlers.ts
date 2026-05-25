import type { Editor } from '@tiptap/core'
import type { Level } from '@tiptap/extension-heading'
import type { ResolvedPos } from '@tiptap/pm/model'
import debounce from 'lodash.debounce'

import { BridgeError } from './errors'
import type {
  EditorActiveTools,
  EditorContentSnapshot,
  EditorSelectionContext,
  EditorSetContentParams,
  MediaPickImageParams,
  MediaPickImageResult,
} from './types'
import { BRIDGE_VERSION } from './types'
import { nsBridge } from './web-bridge'

const capabilities = [
  'editor.setContent',
  'editor.flushContent',
  'editor.focus',
  'editor.blur',
  'editor.toggleBold',
  'editor.toggleItalic',
  'editor.toggleUnderline',
  'editor.toggleStrike',
  'editor.toggleCode',
  'editor.setParagraph',
  'editor.toggleHeading',
  'editor.toggleBulletList',
  'editor.toggleOrderedList',
  'editor.toggleTaskList',
  'editor.toggleBlockquote',
  'editor.toggleCodeBlock',
  'editor.setTextAlign',
  'editor.setHorizontalRule',
  'editor.insertTable',
  'editor.insertImageUpload',
  'editor.insertNativeImage',
]

const readyEditors = new WeakSet<Editor>()
const CONTENT_CHANGED_DEBOUNCE_MS = 900

const isValidHeadingLevel = (level: unknown): level is Level => typeof level === 'number' && [1, 2, 3, 4, 5].includes(level)

const getTextAlign = (editor: Editor): EditorActiveTools['textAlign'] => {
  const headingAlign = editor.getAttributes('heading').textAlign
  const paragraphAlign = editor.getAttributes('paragraph').textAlign
  const align = headingAlign || paragraphAlign || 'left'

  return ['left', 'center', 'right', 'justify'].includes(String(align)) ? (align as EditorActiveTools['textAlign']) : 'left'
}

const isPositionInsideNode = ($pos: ResolvedPos, nodeName: string) => {
  for (let depth = $pos.depth; depth > 0; depth -= 1) {
    if ($pos.node(depth).type.name === nodeName) {
      return true
    }
  }

  return false
}

const getEditorSelectionContext = (editor: Editor): EditorSelectionContext => {
  const { selection } = editor.state

  return {
    isInTitle: selection.ranges.some(range => isPositionInsideNode(range.$from, 'title') || isPositionInsideNode(range.$to, 'title')),
  }
}

export const getEditorActiveTools = (editor: Editor): EditorActiveTools => {
  const headingAttrs = editor.getAttributes('heading')
  const headingLevel = typeof headingAttrs.level === 'number' ? headingAttrs.level : undefined
  const isBulletListActive = editor.isActive('bulletList')
  const isOrderedListActive = editor.isActive('orderedList')
  const isTaskListActive = editor.isActive('taskList')
  const isBlockquoteActive = editor.isActive('blockquote')
  const isCodeBlockActive = editor.isActive('codeBlock')
  const isHeadingActive = editor.isActive('heading')
  const isPlainParagraphActive =
    editor.isActive('paragraph') &&
    !isHeadingActive &&
    !isBulletListActive &&
    !isOrderedListActive &&
    !isTaskListActive &&
    !isBlockquoteActive &&
    !isCodeBlockActive

  return {
    paragraph: isPlainParagraphActive,
    bold: editor.isActive('bold'),
    italic: editor.isActive('italic'),
    underline: editor.isActive('underline'),
    strike: editor.isActive('strike'),
    code: editor.isActive('code'),
    heading: {
      active: isHeadingActive,
      level: headingLevel,
    },
    bulletList: isBulletListActive,
    orderedList: isOrderedListActive,
    taskList: isTaskListActive,
    blockquote: isBlockquoteActive,
    codeBlock: isCodeBlockActive,
    textAlign: getTextAlign(editor),
  }
}

const createContentSnapshot = (editor: Editor, changeVersion: number, reason: EditorContentSnapshot['reason']): EditorContentSnapshot => ({
  changeVersion,
  title: editor.state.doc.firstChild?.textContent?.trim() ?? '',
  content: editor.getJSON(),
  isEmpty: editor.isEmpty,
  reason,
})

const emitContentChanged = (editor: Editor, changeVersion: number, reason: EditorContentSnapshot['reason']) => {
  nsBridge.emit('editor', 'contentChanged', createContentSnapshot(editor, changeVersion, reason))
}

const emitSelectionChanged = (editor: Editor) => {
  nsBridge.emit('editor', 'selectionChanged', {
    activeTools: getEditorActiveTools(editor),
    selectionContext: getEditorSelectionContext(editor),
  })
}

const focusEditor = (editor: Editor) => {
  const focused = editor.commands.focus(undefined, { scrollIntoView: true })

  requestAnimationFrame(() => {
    editor.commands.focus(undefined, { scrollIntoView: true })
  })

  return focused
}

export const setupEditorBridge = (editor: Editor | null) => {
  if (!editor) {
    return () => {}
  }

  let changeVersion = 0
  let hasContentChanged = false
  let isApplyingContent = false
  let lastEmittedChangeVersion = -1
  const emitLatestContentSnapshot = (reason: EditorContentSnapshot['reason']) => {
    if (changeVersion === lastEmittedChangeVersion) {
      return
    }

    lastEmittedChangeVersion = changeVersion
    emitContentChanged(editor, changeVersion, reason)
  }

  const debouncedEmitContentChanged = debounce(() => {
    emitLatestContentSnapshot('debounced')
  }, CONTENT_CHANGED_DEBOUNCE_MS)

  const flushContentChanged = (reason: EditorContentSnapshot['reason'] = 'flush') => {
    debouncedEmitContentChanged.cancel()
    if (!hasContentChanged && reason === 'destroy') {
      return
    }

    emitLatestContentSnapshot(reason)
  }

  const cleanupHandlers = [
    nsBridge.register<EditorSetContentParams, { applied: boolean }>('editor', 'setContent', params => {
      let applied = false
      if (params.content) {
        isApplyingContent = true
        try {
          applied = editor.chain().setContent(params.content).run()
        } finally {
          isApplyingContent = false
        }
      }

      if (params.focus) {
        applied = editor.chain().focus().run()
      }

      return { applied }
    }),
    nsBridge.register<never, { flushed: boolean }>('editor', 'flushContent', () => {
      flushContentChanged('flush')
      return { flushed: true }
    }),
    nsBridge.register<never, { focused: boolean }>('editor', 'focus', () => ({
      focused: focusEditor(editor),
    })),
    nsBridge.register<never, { blurred: boolean }>('editor', 'blur', () => ({
      blurred: editor.chain().blur().run(),
    })),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleBold', () => {
      editor.chain().focus().toggleBold().run()
      return { active: editor.isActive('bold') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleItalic', () => {
      editor.chain().focus().toggleItalic().run()
      return { active: editor.isActive('italic') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleUnderline', () => {
      console.log('toggleUnderline')
      editor.chain().focus().toggleUnderline().run()
      return { active: editor.isActive('underline') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleStrike', () => {
      console.log('toggleStrike')
      editor.chain().focus().toggleStrike().run()
      return { active: editor.isActive('strike') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleCode', () => {
      editor.chain().focus().toggleCode().run()
      return { active: editor.isActive('code') }
    }),
    nsBridge.register<never, { active: boolean; applied: boolean }>('editor', 'setParagraph', () => {
      const applied = editor.chain().focus().setParagraph().run()
      return {
        active: editor.isActive('paragraph'),
        applied,
      }
    }),
    nsBridge.register<{ level: unknown }, { active: boolean; level: number }>('editor', 'toggleHeading', params => {
      if (!isValidHeadingLevel(params?.level)) {
        throw new BridgeError('INVALID_PARAMS', 'editor.toggleHeading requires level 1-5', false)
      }

      editor.chain().focus().toggleHeading({ level: params.level }).run()
      return {
        active: editor.isActive('heading', { level: params.level }),
        level: params.level,
      }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleBulletList', () => {
      editor.chain().focus().toggleBulletList().run()
      return { active: editor.isActive('bulletList') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleOrderedList', () => {
      editor.chain().focus().toggleOrderedList().run()
      return { active: editor.isActive('orderedList') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleTaskList', () => {
      editor.chain().focus().toggleTaskList().run()
      return { active: editor.isActive('taskList') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleBlockquote', () => {
      console.log('toggleBlockquote')
      editor.chain().focus().toggleBlockquote().run()
      return { active: editor.isActive('blockquote') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleCodeBlock', () => {
      editor.chain().focus().toggleCodeBlock().run()
      return { active: editor.isActive('codeBlock') }
    }),
    nsBridge.register<{ align: unknown }, { align: string }>('editor', 'setTextAlign', params => {
      const align = params?.align
      if (!['left', 'center', 'right', 'justify'].includes(String(align))) {
        throw new BridgeError('INVALID_PARAMS', 'editor.setTextAlign requires a valid align value', false)
      }

      editor
        .chain()
        .focus()
        .setTextAlign(align as EditorActiveTools['textAlign'])
        .run()
      return { align: String(align) }
    }),
    nsBridge.register<never, { inserted: boolean }>('editor', 'setHorizontalRule', () => {
      console.log('setHorizontalRule')
      const value = editor.chain().focus().setHorizontalRule().run()

      return { inserted: value }
    }),
    nsBridge.register<{ rows?: number; cols?: number; withHeaderRow?: boolean }, { inserted: boolean }>('editor', 'insertTable', params => {
      console.log('insertTable')
      const inserted = editor
        .chain()
        .focus()
        .insertTable({
          rows: params?.rows ?? 3,
          cols: params?.cols ?? 3,
          withHeaderRow: params?.withHeaderRow ?? true,
        })
        .run()
      return { inserted: inserted }
    }),
    nsBridge.register<never, { inserted: boolean }>('editor', 'insertImageUpload', () => {
      const inserted = editor.chain().focus().insertContent({ type: 'imageUpload' }).run()
      return { inserted }
    }),
    nsBridge.register<MediaPickImageParams | undefined, Promise<{ inserted: boolean }>>('editor', 'insertNativeImage', async params => {
      const image = await nsBridge.call<MediaPickImageParams | undefined, MediaPickImageResult>('media', 'pickImage', params, {
        timeoutMs: 120000,
      })
      console.log('pickImage = ', image)
      const displayName = image.filename.replace(/\.[^/.]+$/, '')
      const inserted = editor
        .chain()
        .focus()
        .insertContent({
          type: 'image',
          attrs: {
            src: image.src,
            attachmentId: image.attachmentId,
            alt: displayName,
            title: displayName,
          },
        })
        .run()

      return { inserted }
    }),
  ]

  const handleUpdate = () => {
    if (isApplyingContent) {
      return
    }

    changeVersion += 1
    hasContentChanged = true
    debouncedEmitContentChanged()
  }
  const handleSelectionUpdate = () => emitSelectionChanged(editor)

  editor.on('update', handleUpdate)
  editor.on('selectionUpdate', handleSelectionUpdate)
  editor.on('transaction', handleSelectionUpdate)

  if (!readyEditors.has(editor)) {
    readyEditors.add(editor)
    console.log('Editor is ready, emitting ready event to bridge')
    nsBridge.ready('editor', 'ready', {
      editorVersion: '1.0.0',
      supportedBridgeVersion: BRIDGE_VERSION,
      capabilities,
    })
  }
  emitSelectionChanged(editor)

  return () => {
    flushContentChanged('destroy')
    debouncedEmitContentChanged.cancel()
    cleanupHandlers.forEach(cleanup => cleanup())
    editor.off('update', handleUpdate)
    editor.off('selectionUpdate', handleSelectionUpdate)
    editor.off('transaction', handleSelectionUpdate)
  }
}
