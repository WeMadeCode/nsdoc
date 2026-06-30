import { NodeViewContent, type NodeViewProps, NodeViewWrapper } from '@tiptap/react'

import styles from './index.module.scss'

const TitleWrapper = ({ node }: NodeViewProps) => {
  const isEmpty = node.textContent.length === 0
  console.log('isEmpty = ', isEmpty)

  return (
    <NodeViewWrapper data-type="title" className={styles.titleWrapper}>
      <NodeViewContent className={styles.titleContent} />
      {isEmpty && <div className={styles.placeholder}>请输入标题</div>}
    </NodeViewWrapper>
  )
}

export default TitleWrapper
