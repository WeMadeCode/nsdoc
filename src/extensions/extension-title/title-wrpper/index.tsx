import { NodeViewContent, NodeViewWrapper, type ReactNodeViewProps } from '@tiptap/react'
import React, { memo } from 'react'
import styles from './index.module.scss'

const TitleWrapper = (props: ReactNodeViewProps) => {
  const { node } = props
  // console.log('props = ', props)
  // TipTap placeholder 扩展会把 data-placeholder 放到 attributes 里
  // const placeholder = attributes['data-placeholder']
  return (
    <NodeViewWrapper className={styles.wrap}>
      <NodeViewContent />
    </NodeViewWrapper>
  )
}

export default memo(TitleWrapper)
