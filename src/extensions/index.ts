import Blockquote from '@tiptap/extension-blockquote'
import Bold from '@tiptap/extension-bold'
import BulletList from '@tiptap/extension-bullet-list'
import Code from '@tiptap/extension-code'
import CodeBlock from '@tiptap/extension-code-block'
import HardBreak from '@tiptap/extension-hard-break'
import Heading from '@tiptap/extension-heading'
import HorizontalRule from '@tiptap/extension-horizontal-rule'
import Image from '@tiptap/extension-image'
import Italic from '@tiptap/extension-italic'
import Link from '@tiptap/extension-link'
import ListItem from '@tiptap/extension-list-item'
import OrderedList from '@tiptap/extension-ordered-list'
import Paragraph from '@tiptap/extension-paragraph'
import Strike from '@tiptap/extension-strike'
import Subscript from '@tiptap/extension-subscript'
import Superscript from '@tiptap/extension-superscript'
import Text from '@tiptap/extension-text'
import Underline from '@tiptap/extension-underline'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import Highlight from '@tiptap/extension-highlight'
import Typography from '@tiptap/extension-typography'
import History from '@tiptap/extension-history'
import { Color, TextStyle, BackgroundColor } from '@tiptap/extension-text-style'
import TextAlign from '@tiptap/extension-text-align'

import { CodeBlockLowlight } from './extension-code-block'
import { Title } from './extension-title'
import { Document } from './extension-document'
import { Placeholder } from './extension-placeholder'
import { TableKit } from '@tiptap/extension-table'
import { TableCell } from './extension-table-cell'

export const extensions = [
  Document,
  Paragraph,
  Title,
  Placeholder,
  Bold,
  BulletList,
  Code,
  CodeBlock,
  HardBreak,
  Text,
  Highlight,
  Typography,
  Blockquote,
  Heading,
  HorizontalRule,
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
  TaskItem,
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
]
