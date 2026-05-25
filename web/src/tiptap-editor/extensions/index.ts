import { Blockquote } from '@tiptap/extension-blockquote'
import Bold from '@tiptap/extension-bold'
import BulletList from '@tiptap/extension-bullet-list'
import Code from '@tiptap/extension-code'
import HardBreak from '@tiptap/extension-hard-break'
import Heading from '@tiptap/extension-heading'
import Highlight from '@tiptap/extension-highlight'
import History from '@tiptap/extension-history'
import Image from '@tiptap/extension-image'
import Italic from '@tiptap/extension-italic'
import Link from '@tiptap/extension-link'
import ListItem from '@tiptap/extension-list-item'
import OrderedList from '@tiptap/extension-ordered-list'
import Paragraph from '@tiptap/extension-paragraph'
import Strike from '@tiptap/extension-strike'
import Subscript from '@tiptap/extension-subscript'
import Superscript from '@tiptap/extension-superscript'
import { TableKit } from '@tiptap/extension-table'
import TaskItem from '@tiptap/extension-task-item'
import TaskList from '@tiptap/extension-task-list'
import Text from '@tiptap/extension-text'
import TextAlign from '@tiptap/extension-text-align'
import { BackgroundColor, Color, TextStyle } from '@tiptap/extension-text-style'
import Typography from '@tiptap/extension-typography'
import Underline from '@tiptap/extension-underline'
import { TrailingNode } from '@tiptap/extensions'

import { ListNormalizationExtension } from '@/tiptap-editor/components/tiptap-extension/list-normalization-extension'

import { CodeBlockLowlight } from './extension-code-block'
import { Document } from './extension-document'
import { HorizontalRule } from './extension-horizontal-rule'
import { Placeholder } from './extension-placeholder'
import { TableCell } from './extension-table-cell'
import { Title } from './extension-title'

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
    table: { resizable: true },
    tableCell: false,
  }),
  TableCell,
  HorizontalRule,
  ListNormalizationExtension,
  TrailingNode.configure({
    node: 'paragraph',
  }),
]
