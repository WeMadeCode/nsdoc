import type { Editor } from '@tiptap/core'
import { useEffect, useState } from 'react'

export type NodeActiveType = {
  active: boolean
  attributes: Record<string, any> | undefined
}

export const useNodeActive = (editor: Editor | null, name: string) => {
  const [active, setActive] = useState(false)
  const [attributes, setAttributes] = useState<Record<string, any> | undefined>(undefined)

  useEffect(() => {
    const func = () => {
      const result = editor?.isActive(name) ?? false
      const attrs = editor?.getAttributes(name)
      setActive(result)
      setAttributes(attrs)
    }

    editor?.on('focus', func)
    editor?.on('selectionUpdate', func)
    return () => {
      editor?.off('focus', func)
      editor?.off('selectionUpdate', func)
    }
  }, [])

  return {
    active: active,
    attributes: attributes,
  }
}
