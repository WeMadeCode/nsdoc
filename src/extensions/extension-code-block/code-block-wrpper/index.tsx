import { memo } from 'react'

import { NodeViewContent, NodeViewWrapper, type ReactNodeViewProps } from '@tiptap/react'

const CodeBlockWrapper = (params: ReactNodeViewProps) => {
  const { node } = params
  const defaultLanguage = (node.attrs.language as string | undefined) ?? ''

  return (
    <NodeViewWrapper className={'code-block'}>
      <span className="code-block-language">{defaultLanguage}</span>
      <pre>
        <NodeViewContent as="code" />
      </pre>
    </NodeViewWrapper>
  )
}

export default memo(CodeBlockWrapper)
