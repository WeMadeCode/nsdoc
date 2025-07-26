import dsbridge from 'dsbridge'
import type { NodeActiveType } from '../hooks/useNodeActive'

export const headingListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
    level: type.attributes?.level,
  }
  dsbridge.call('headingActive', obj)
}

export const paragraphListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('paragraphActive', obj)
}

export const orderedListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('orderedActive', obj)
}

export const bulletListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('bulletActive', obj)
}

export const taskListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('taskActive', obj)
}

export const codeBlockListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('codeBlockActive', obj)
}

export const blockQuoteListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('blockQuoteActive', obj)
}
