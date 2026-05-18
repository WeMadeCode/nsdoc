import type { JSONContent } from '@tiptap/core'

const emptyTitle = (): JSONContent => ({ type: 'title' })
const emptyParagraph = (): JSONContent => ({ type: 'paragraph' })

const isTitleNode = (node: JSONContent) => node.type === 'title'

const isPromotableTitleNode = (node: JSONContent) => node.type === 'heading' && node.attrs?.level === 1

const toTitleNode = (node: JSONContent): JSONContent => ({
  type: 'title',
  content: node.content,
})

export const ensureDocumentTitle = (content: JSONContent): JSONContent => {
  const docContent = Array.isArray(content.content) ? [...content.content] : []
  const titleIndex = docContent.findIndex(isTitleNode)

  let title: JSONContent
  let blocks: JSONContent[]

  if (titleIndex >= 0) {
    title = docContent[titleIndex]
    blocks = docContent.filter((_, index) => index !== titleIndex && !isTitleNode(docContent[index]))
  } else if (docContent[0] && isPromotableTitleNode(docContent[0])) {
    title = toTitleNode(docContent[0])
    blocks = docContent.slice(1)
  } else {
    title = emptyTitle()
    blocks = docContent
  }

  return {
    ...content,
    type: 'doc',
    content: [title, ...(blocks.length > 0 ? blocks : [emptyParagraph()])],
  }
}
