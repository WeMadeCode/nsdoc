import type { Editor } from '@tiptap/react'

import { RefreshCcwIcon } from '@/tiptap-editor/components/tiptap-icons/refresh-ccw-icon'
// --- Tiptap UI ---
import { DeleteNodeButton } from '@/tiptap-editor/components/tiptap-ui/delete-node-button'
import { ImageAlignButton } from '@/tiptap-editor/components/tiptap-ui/image-align-button'
import { ImageCaptionButton } from '@/tiptap-editor/components/tiptap-ui/image-caption-button'
import { ImageDownloadButton } from '@/tiptap-editor/components/tiptap-ui/image-download-button'
import { ImageUploadButton } from '@/tiptap-editor/components/tiptap-ui/image-upload-button'
// --- UI Primitive ---
import { Separator } from '@/tiptap-editor/components/tiptap-ui-primitive/separator'
// --- Hooks ---
import { useTiptapEditor } from '@/tiptap-editor/hooks/use-tiptap-editor'
// --- Lib ---
import { isNodeTypeSelected } from '@/tiptap-editor/lib/tiptap-utils'

export function ImageNodeFloating({ editor: providedEditor }: { editor?: Editor | null }) {
  const { editor } = useTiptapEditor(providedEditor)
  const visible = isNodeTypeSelected(editor, ['image'])

  if (!editor || !visible) {
    return null
  }

  return (
    <>
      <ImageAlignButton align="left" />
      <ImageAlignButton align="center" />
      <ImageAlignButton align="right" />
      <Separator />
      <ImageCaptionButton />
      <Separator />
      <ImageDownloadButton />
      <ImageUploadButton icon={RefreshCcwIcon} tooltip="Replace" />
      <Separator />
      <DeleteNodeButton />
    </>
  )
}
