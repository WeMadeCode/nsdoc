import type { Editor } from '@tiptap/core'
import { useEffect, useState } from 'react'

export type ActiveType = {
  active: boolean
  attributes: Record<string, unknown> | undefined
}

export function useActive(editor: Editor | null, name: string) {
  const [active, setActive] = useState(false)
  const [attributes, setAttributes] = useState<Record<string, unknown> | undefined>(undefined)

  useEffect(() => {
    const func = () => {
      const result = editor?.isActive(name) ?? false
      const attrs = editor?.getAttributes(name)
      setActive(result)
      setAttributes(attrs)
    }

    editor?.on('update', func)
    editor?.on('selectionUpdate', func)
    return () => {
      editor?.off('update', func)
      editor?.off('selectionUpdate', func)
    }
  }, [editor, name])

  return {
    active: active,
    attributes: attributes,
  }
}
