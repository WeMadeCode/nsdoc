import { NodeViewContent, NodeViewWrapper, type ReactNodeViewProps } from '@tiptap/react'
import { memo } from 'react'

const TitleWrapper = (_props: ReactNodeViewProps) => {
  return (
    <NodeViewWrapper>
      <NodeViewContent />
    </NodeViewWrapper>
  )
}

export default memo(TitleWrapper)
