import Bold from '@tiptap/extension-bold'
import BulletList from '@tiptap/extension-bullet-list'
import Code from '@tiptap/extension-code'
import HardBreak from '@tiptap/extension-hard-break'
import Heading from '@tiptap/extension-heading'
import Highlight from '@tiptap/extension-highlight'
import History from '@tiptap/extension-history'
import Italic from '@tiptap/extension-italic'
import Link from '@tiptap/extension-link'
import ListItem from '@tiptap/extension-list-item'
import OrderedList from '@tiptap/extension-ordered-list'
import Paragraph from '@tiptap/extension-paragraph'
import Strike from '@tiptap/extension-strike'
import Subscript from '@tiptap/extension-subscript'
import Superscript from '@tiptap/extension-superscript'
import TaskItem from '@tiptap/extension-task-item'
import TaskList from '@tiptap/extension-task-list'
import Text from '@tiptap/extension-text'
import TextAlign from '@tiptap/extension-text-align'
import { BackgroundColor, Color, TextStyle } from '@tiptap/extension-text-style'
import Typography from '@tiptap/extension-typography'
import Underline from '@tiptap/extension-underline'
import { TrailingNode } from '@tiptap/extensions'

import { ListNormalizationExtension } from '@/tiptap-editor/components/tiptap-extension/list-normalization-extension'
import { NodeAlignment } from '@/tiptap-editor/components/tiptap-extension/node-alignment-extension'
import { NodeBackground } from '@/tiptap-editor/components/tiptap-extension/node-background-extension'
import { Image } from '@/tiptap-editor/components/tiptap-node/image-node/image-node-extension'
import { TableHandleExtension } from '@/tiptap-editor/components/tiptap-node/table-node/extensions/table-handle'
import { TableKit } from '@/tiptap-editor/components/tiptap-node/table-node/extensions/table-node-extension'
import { Blockquote } from '@/tiptap-editor/extensions/extension-blockquote'
import { CodeBlockLowlight } from '@/tiptap-editor/extensions/extension-code-block'
import { Document } from '@/tiptap-editor/extensions/extension-document'
import { HorizontalRule } from '@/tiptap-editor/extensions/extension-horizontal-rule'
import { Placeholder } from '@/tiptap-editor/extensions/extension-placeholder'
import { TableCell } from '@/tiptap-editor/extensions/extension-table-cell'
import { Title } from '@/tiptap-editor/extensions/extension-title'

import { ImageUploadNode } from '../components/tiptap-node/image-upload-node'
import { handleImageUpload, MAX_FILE_SIZE } from '../lib/tiptap-utils'

export const extensions = [
  Document,
  Paragraph,
  Title,
  Text,
  Placeholder,
  Bold,
  BulletList,
  Code,
  HardBreak,
  Highlight,
  Typography,
  Blockquote,
  Heading,
  Image,
  Italic,
  Link,
  ListItem,
  OrderedList,
  Strike,
  Subscript,
  Superscript,
  Underline,
  TaskList,
  TaskItem,
  TextStyle,
  CodeBlockLowlight,
  History,
  Color,
  BackgroundColor,
  TextAlign.configure({
    types: ['heading', 'paragraph'],
  }),
  TableKit.configure({
    table: {
      resizable: true,
      cellMinWidth: 120,
    },
    tableCell: false,
  }),
  TableCell,
  TableHandleExtension,
  NodeBackground.configure({
    types: ['paragraph', 'heading', 'blockquote', 'taskList', 'bulletList', 'orderedList', 'tableCell', 'tableHeader'],
  }),
  NodeAlignment,
  HorizontalRule,
  ListNormalizationExtension,
  TrailingNode.configure({
    node: 'paragraph',
    notAfter: ['paragraph', 'blockquote', 'title'],
  }),
  ImageUploadNode.configure({
    accept: 'image/*',
    maxSize: MAX_FILE_SIZE,
    limit: 3,
    upload: handleImageUpload,
  }),
]
