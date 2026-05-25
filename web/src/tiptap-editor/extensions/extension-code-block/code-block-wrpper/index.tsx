import { NodeViewContent, NodeViewWrapper, type ReactNodeViewProps } from '@tiptap/react'
import { memo } from 'react'

const CodeBlockWrapper = (params: ReactNodeViewProps) => {
  const { node } = params
  const defaultLanguage = (node.attrs.language as string | undefined) ?? ''

  return (
    <NodeViewWrapper className={'code-block'}>
      <span className="code-block-language">{defaultLanguage}</span>
      <pre>
        <code>
          <NodeViewContent />
        </code>
      </pre>
    </NodeViewWrapper>
  )
}

export default memo(CodeBlockWrapper)
