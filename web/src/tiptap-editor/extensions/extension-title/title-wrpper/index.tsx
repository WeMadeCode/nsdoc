import { NodeViewContent, NodeViewWrapper, type NodeViewProps } from '@tiptap/react'
import { memo } from 'react'
import styles from './index.module.scss'

const TitleWrapper = ({ node }: NodeViewProps) => {
  const isEmpty = node.textContent.length === 0

  return (
    <NodeViewWrapper data-type="title" className={styles.titleWrapper}>
      <NodeViewContent className={styles.titleContent} />
      {isEmpty && <div className={styles.placeholder}>请输入标题</div>}
    </NodeViewWrapper>
  )
}

export default memo(TitleWrapper)
