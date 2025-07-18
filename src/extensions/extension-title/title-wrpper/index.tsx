import { NodeViewContent, NodeViewWrapper } from '@tiptap/react'
import { memo } from 'react'
import styles from './index.module.scss'
import writer from '../../../assets/writer.svg'
import { Image } from '@douyinfe/semi-ui'

const TitleWrapper = () => {
  return (
    <NodeViewWrapper>
      <NodeViewContent />
      <div className={styles.container}>
        <Image preview={false} height={20} width={20} src={writer} />
        <span className={styles.name}>我是雷总</span>
        <span className={styles.line}>|</span>
        <span className={styles.time}>2023-10-01 12:00</span>
      </div>
    </NodeViewWrapper>
  )
}

export default memo(TitleWrapper)
