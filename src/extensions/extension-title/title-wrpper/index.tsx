import { NodeViewContent, NodeViewWrapper, type ReactNodeViewProps } from '@tiptap/react'
import { memo } from 'react'

const TitleWrapper = (props: ReactNodeViewProps) => {
  return (
    <NodeViewWrapper>
      <NodeViewContent />
    </NodeViewWrapper>
  )
}

export default memo(TitleWrapper)
