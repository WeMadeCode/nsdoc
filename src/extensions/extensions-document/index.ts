import { Document as DocumentTiptap } from '@tiptap/extension-document'

export const Document = DocumentTiptap.extend({
  content: 'title block+',
})
