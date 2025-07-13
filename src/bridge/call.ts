import dsbridge from 'dsbridge'
import type { NodeActiveType } from '../hooks/useNodeActive'

export const headingListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
    level: type.attributes?.level,
  }
  dsbridge.call('headingActive', JSON.stringify(obj))
}

export const paragraphListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('paragraphActive', JSON.stringify(obj))
}


export const orderedListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('orderedActive', JSON.stringify(obj))
}


export const bulletListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('bulletActive', JSON.stringify(obj))
}


export const taskListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('taskActive', JSON.stringify(obj))
}


export const codeBlockListener = (type: NodeActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('codeBlockActive', JSON.stringify(obj))
}




