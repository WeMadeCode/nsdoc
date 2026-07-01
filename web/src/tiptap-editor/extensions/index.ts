import type { Extensions } from '@tiptap/core'
import Bold from '@tiptap/extension-bold'
import BulletList from '@tiptap/extension-bullet-list'
import Code from '@tiptap/extension-code'
import { Collaboration, isChangeOrigin } from '@tiptap/extension-collaboration'
import { CollaborationCaret } from '@tiptap/extension-collaboration-caret'
import Dropcursor from '@tiptap/extension-dropcursor'
import { Emoji, gitHubEmojis } from '@tiptap/extension-emoji'
import Gapcursor from '@tiptap/extension-gapcursor'
import HardBreak from '@tiptap/extension-hard-break'
import Heading from '@tiptap/extension-heading'
import Highlight from '@tiptap/extension-highlight'
import History from '@tiptap/extension-history'
import Italic from '@tiptap/extension-italic'
import Link from '@tiptap/extension-link'
import ListItem from '@tiptap/extension-list-item'
import { Mathematics } from '@tiptap/extension-mathematics'
import { Mention } from '@tiptap/extension-mention'
import OrderedList from '@tiptap/extension-ordered-list'
import Paragraph from '@tiptap/extension-paragraph'
import Strike from '@tiptap/extension-strike'
import Subscript from '@tiptap/extension-subscript'
import Superscript from '@tiptap/extension-superscript'
import { getHierarchicalIndexes, type TableOfContentData, TableOfContents } from '@tiptap/extension-table-of-contents'
import TaskItem from '@tiptap/extension-task-item'
import TaskList from '@tiptap/extension-task-list'
import Text from '@tiptap/extension-text'
import TextAlign from '@tiptap/extension-text-align'
import { Color, TextStyle } from '@tiptap/extension-text-style'
import Typography from '@tiptap/extension-typography'
import Underline from '@tiptap/extension-underline'
import { UniqueID } from '@tiptap/extension-unique-id'
import { Placeholder, Selection } from '@tiptap/extensions'
import type { Doc as YDoc } from 'yjs'

import { Indent } from '@/tiptap-editor/components/tiptap-extension/indent-extension'
import { ListNormalizationExtension } from '@/tiptap-editor/components/tiptap-extension/list-normalization-extension'
import { NodeAlignment } from '@/tiptap-editor/components/tiptap-extension/node-alignment-extension'
import { NodeBackground } from '@/tiptap-editor/components/tiptap-extension/node-background-extension'
import { UiState } from '@/tiptap-editor/components/tiptap-extension/ui-state-extension'
import { HorizontalRule as NotionHorizontalRule } from '@/tiptap-editor/components/tiptap-node/horizontal-rule-node/horizontal-rule-node-extension'
import { Image } from '@/tiptap-editor/components/tiptap-node/image-node/image-node-extension'
import { TableHandleExtension } from '@/tiptap-editor/components/tiptap-node/table-node/extensions/table-handle'
import { TableKit } from '@/tiptap-editor/components/tiptap-node/table-node/extensions/table-node-extension'
import { TocNode } from '@/tiptap-editor/components/tiptap-node/toc-node/extensions/toc-node-extension'
import { Blockquote } from '@/tiptap-editor/extensions/extension-blockquote'
import { CodeBlockLowlight } from '@/tiptap-editor/extensions/extension-code-block'
import { Document } from '@/tiptap-editor/extensions/extension-document'
import { Title } from '@/tiptap-editor/extensions/extension-title'

import { ImageUploadNode } from '../components/tiptap-node/image-upload-node'
import { handleImageUpload, MAX_FILE_SIZE } from '../lib/tiptap-utils'

interface EditorExtensionsOptions {
  hasCollab?: boolean
  placeholder?: string
  provider?: unknown
  setTocContent?: (content: TableOfContentData | null) => void
  user?: {
    id: string
    name: string
    color: string
  }
  ydoc?: YDoc
}

export function createEditorExtensions({
  hasCollab = false,
  placeholder = 'Start writing...',
  provider,
  setTocContent = () => undefined,
  user = { id: '', name: '', color: '' },
  ydoc,
}: EditorExtensionsOptions = {}): Extensions {
  return [
    Document,
    Title,
    Paragraph,
    Text,
    Bold,
    Italic,
    Strike,
    Underline,
    Code,
    Heading,
    BulletList,
    OrderedList,
    ListItem,
    Blockquote,
    CodeBlockLowlight,
    HardBreak,
    ...(hasCollab ? [] : [History]),
    Dropcursor.configure({ width: 2 }),
    Gapcursor,
    Link.configure({ openOnClick: false }),
    NotionHorizontalRule,
    TextAlign.configure({ types: ['heading', 'paragraph'] }),
    ...(hasCollab && provider && ydoc
      ? [
          Collaboration.configure({ document: ydoc }),
          CollaborationCaret.configure({
            provider: provider as never,
            user,
          }),
        ]
      : []),
    Placeholder.configure({
      placeholder,
      emptyNodeClass: 'is-empty with-slash',
    }),
    Mention,
    Emoji.configure({
      emojis: gitHubEmojis.filter(emoji => !emoji.name.includes('regional')),
      forceFallbackImages: true,
    }),
    TableKit.configure({
      table: {
        resizable: true,
        cellMinWidth: 120,
      },
    }),
    NodeBackground.configure({
      types: [
        'title',
        'paragraph',
        'heading',
        'blockquote',
        'taskList',
        'bulletList',
        'orderedList',
        'tableCell',
        'tableHeader',
        'tocNode',
      ],
    }),
    NodeAlignment,
    TextStyle,
    Mathematics,
    Superscript,
    Subscript,
    Indent,
    Color,
    TaskList,
    TaskItem.configure({ nested: true }),
    Highlight.configure({ multicolor: true }),
    Selection,
    Image,
    TableOfContents.configure({
      getIndex: getHierarchicalIndexes,
      onUpdate: setTocContent,
    }),
    TableHandleExtension,
    ListNormalizationExtension,
    ImageUploadNode.configure({
      accept: 'image/*',
      maxSize: MAX_FILE_SIZE,
      limit: 3,
      upload: handleImageUpload,
      onError: error => console.error('Upload failed:', error),
    }),
    UniqueID.configure({
      types: ['title', 'table', 'paragraph', 'bulletList', 'orderedList', 'taskList', 'heading', 'blockquote', 'codeBlock', 'tocNode'],
      filterTransaction: transaction => !isChangeOrigin(transaction),
    }),
    Typography,
    UiState,
    TocNode.configure({
      topOffset: 48,
    }),
  ]
}
