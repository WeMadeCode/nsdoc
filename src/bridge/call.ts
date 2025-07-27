import dsbridge from 'dsbridge'
import type { ActiveType } from '../hooks/useActive'

export const codeListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('codeActive', obj)
}

export const underlineListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('underlineActive', obj)
}

export const italicListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('italicActive', obj)
}

export const boldListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('boldActive', obj)
}

export const headingListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
    level: type.attributes?.level,
  }
  dsbridge.call('headingActive', obj)
}

export const paragraphListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('paragraphActive', obj)
}

export const orderedListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('orderedActive', obj)
}

export const bulletListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('bulletActive', obj)
}

export const taskListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('taskActive', obj)
}

export const codeBlockListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('codeBlockActive', obj)
}

export const blockQuoteListener = (type: ActiveType) => {
  const obj = {
    active: type.active,
  }
  dsbridge.call('blockQuoteActive', obj)
}
