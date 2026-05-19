import type { Editor, JSONContent } from '@tiptap/core'
import type { Level } from '@tiptap/extension-heading'
import { BridgeError } from './errors'
import { nsBridge } from './web-bridge'
import type { EditorActiveTools, EditorContentResult, EditorSetContentParams } from './types'
import { BRIDGE_VERSION } from './types'
import { ensureDocumentTitle } from '@/tiptap-editor/lib/document-content'

const capabilities = [
  'editor.setContent',
  'editor.getContent',
  'editor.getTitle',
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
]

const isRecord = (value: unknown): value is Record<string, unknown> => typeof value === 'object' && value !== null

const parseContent = (content: EditorSetContentParams['content']): JSONContent => {
  if (typeof content === 'string') {
    return ensureDocumentTitle(JSON.parse(content) as JSONContent)
  }

  return ensureDocumentTitle(content)
}

const isValidHeadingLevel = (level: unknown): level is Level =>
  typeof level === 'number' && [1, 2, 3, 4, 5].includes(level)

const getTextAlign = (editor: Editor): EditorActiveTools['textAlign'] => {
  const headingAlign = editor.getAttributes('heading').textAlign
  const paragraphAlign = editor.getAttributes('paragraph').textAlign
  const align = headingAlign || paragraphAlign || 'left'

  return ['left', 'center', 'right', 'justify'].includes(String(align)) ? (align as EditorActiveTools['textAlign']) : 'left'
}

export const getEditorActiveTools = (editor: Editor): EditorActiveTools => {
  const headingAttrs = editor.getAttributes('heading')
  const headingLevel = typeof headingAttrs.level === 'number' ? headingAttrs.level : undefined

  return {
    bold: editor.isActive('bold'),
    italic: editor.isActive('italic'),
    underline: editor.isActive('underline'),
    strike: editor.isActive('strike'),
    code: editor.isActive('code'),
    heading: {
      active: editor.isActive('heading'),
      level: headingLevel,
    },
    bulletList: editor.isActive('bulletList'),
    orderedList: editor.isActive('orderedList'),
    taskList: editor.isActive('taskList'),
    blockquote: editor.isActive('blockquote'),
    codeBlock: editor.isActive('codeBlock'),
    textAlign: getTextAlign(editor),
  }
}

const emitSelectionChanged = (editor: Editor) => {
  nsBridge.emit('editor', 'selectionChanged', {
    activeTools: getEditorActiveTools(editor),
  })
}

export const setupEditorBridge = (editor: Editor | null) => {
  if (!editor) {
    return () => {}
  }

  let changeVersion = 0
  const cleanupHandlers = [
    nsBridge.register<EditorSetContentParams, { applied: boolean }>('editor', 'setContent', params => {
      if (!isRecord(params) || !('content' in params)) {
        throw new BridgeError('INVALID_PARAMS', 'editor.setContent requires content', false)
      }

      const nextContent = parseContent(params.content as EditorSetContentParams['content'])
      const focus = params.focus === true
      const chain = focus ? editor.chain().focus() : editor.chain()

      return {
        applied: chain.setContent(nextContent).run(),
      }
    }),
    nsBridge.register<never, EditorContentResult>('editor', 'getContent', () => ({
      content: editor.getJSON(),
      plainText: editor.getText().trim(),
      isEmpty: editor.isEmpty,
    })),
    nsBridge.register<never, { title: string }>('editor', 'getTitle', () => ({
      title: editor.state.doc.firstChild?.textContent?.trim() ?? '',
    })),
    nsBridge.register<never, { focused: boolean }>('editor', 'focus', () => ({
      focused: editor.chain().focus().run(),
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
      editor.chain().focus().toggleUnderline().run()
      return { active: editor.isActive('underline') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleStrike', () => {
      editor.chain().focus().toggleStrike().run()
      return { active: editor.isActive('strike') }
    }),
    nsBridge.register<never, { active: boolean }>('editor', 'toggleCode', () => {
      editor.chain().focus().toggleCode().run()
      return { active: editor.isActive('code') }
    }),
    nsBridge.register<never, { applied: boolean }>('editor', 'setParagraph', () => ({
      applied: editor.chain().focus().setParagraph().run(),
    })),
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

      editor.chain().focus().setTextAlign(align as EditorActiveTools['textAlign']).run()
      return { align: String(align) }
    }),
    nsBridge.register<never, { inserted: boolean }>('editor', 'setHorizontalRule', () => ({
      inserted: editor.chain().focus().setHorizontalRule().run(),
    })),
    nsBridge.register<{ rows?: number; cols?: number; withHeaderRow?: boolean }, { inserted: boolean }>('editor', 'insertTable', params => ({
      inserted: editor
        .chain()
        .focus()
        .insertTable({
          rows: params?.rows ?? 3,
          cols: params?.cols ?? 3,
          withHeaderRow: params?.withHeaderRow ?? true,
        })
        .run(),
    })),
  ]

  const handleUpdate = () => {
    changeVersion += 1
    nsBridge.emit('editor', 'contentChanged', {
      changeVersion,
      isEmpty: editor.isEmpty,
    })
  }
  const handleSelectionUpdate = () => emitSelectionChanged(editor)

  editor.on('update', handleUpdate)
  editor.on('selectionUpdate', handleSelectionUpdate)
  editor.on('transaction', handleSelectionUpdate)

  nsBridge.ready('editor', 'ready', {
    editorVersion: '1.0.0',
    supportedBridgeVersion: BRIDGE_VERSION,
    capabilities,
  })
  emitSelectionChanged(editor)

  return () => {
    cleanupHandlers.forEach(cleanup => cleanup())
    editor.off('update', handleUpdate)
    editor.off('selectionUpdate', handleSelectionUpdate)
    editor.off('transaction', handleSelectionUpdate)
  }
}
