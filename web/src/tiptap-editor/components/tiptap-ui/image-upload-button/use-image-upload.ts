'use client'

import { type Editor } from '@tiptap/react'
import { useCallback, useEffect, useState } from 'react'
import { useHotkeys } from 'react-hotkeys-hook'

// --- Icons ---
import { ImagePlusIcon } from '@/tiptap-editor/components/tiptap-icons/image-plus-icon'
import { useIsBreakpoint } from '@/tiptap-editor/hooks/use-is-breakpoint'
// --- Hooks ---
import { useTiptapEditor } from '@/tiptap-editor/hooks/use-tiptap-editor'
// --- Lib ---
import { isExtensionAvailable } from '@/tiptap-editor/lib/tiptap-utils'
import type { MediaPickImageParams, MediaPickImageResult } from '@/bridge/types'
import { nsBridge } from '@/bridge/web-bridge'

export const IMAGE_UPLOAD_SHORTCUT_KEY = 'mod+shift+i'

/**
 * Configuration for the image upload functionality
 */
export interface UseImageUploadConfig {
  /**
   * The Tiptap editor instance.
   */
  editor?: Editor | null
  /**
   * Whether the button should hide when insertion is not available.
   * @default false
   */
  hideWhenUnavailable?: boolean
  /**
   * Callback function called after a successful image insertion.
   */
  onInserted?: () => void
}

/**
 * Checks if image can be inserted in the current editor state
 */
export function canInsertImage(editor: Editor | null): boolean {
  if (!editor || !editor.isEditable) return false
  if (!isExtensionAvailable(editor, ['image', 'imageUpload'])) return false

  return editor.can().insertContent({ type: isExtensionAvailable(editor, 'image') ? 'image' : 'imageUpload' })
}

/**
 * Checks if image is currently active
 */
export function isImageActive(editor: Editor | null): boolean {
  if (!editor || !editor.isEditable) return false
  return editor.isActive('imageUpload')
}

/**
 * Inserts an image in the editor
 */
export function insertImage(editor: Editor | null): boolean {
  if (!editor || !editor.isEditable) return false
  if (!canInsertImage(editor)) return false

  try {
    return editor
      .chain()
      .focus()
      .insertContent({
        type: 'imageUpload',
      })
      .run()
  } catch {
    return false
  }
}

export async function insertNativeImage(editor: Editor | null): Promise<boolean> {
  if (!editor || !editor.isEditable) return false
  if (!canInsertImage(editor)) return false

  if (!window.webkit?.messageHandlers?.nsBridge) {
    return insertImage(editor)
  }

  try {
    const image = await nsBridge.call<MediaPickImageParams, MediaPickImageResult>(
      'media',
      'pickImage',
      { source: 'photoLibrary' },
      { timeoutMs: 120000 }
    )
    const displayName = image.filename.replace(/\.[^/.]+$/, '')

    return editor
      .chain()
      .focus()
      .insertContent({
        type: 'image',
        attrs: {
          src: image.src,
          attachmentId: image.attachmentId,
          alt: displayName,
          title: displayName,
        },
      })
      .run()
  } catch {
    return false
  }
}

/**
 * Determines if the image button should be shown
 */
export function shouldShowButton(props: { editor: Editor | null; hideWhenUnavailable: boolean }): boolean {
  const { editor, hideWhenUnavailable } = props

  if (!editor || !editor.isEditable) return false

  if (!hideWhenUnavailable) {
    return true
  }

  if (!isExtensionAvailable(editor, 'imageUpload')) return false

  if (!editor.isActive('code')) {
    return canInsertImage(editor)
  }

  return true
}

/**
 * Custom hook that provides image functionality for Tiptap editor
 *
 * @example
 * ```tsx
 * // Simple usage - no params needed
 * function MySimpleImageButton() {
 *   const { isVisible, handleImage } = useImage()
 *
 *   if (!isVisible) return null
 *
 *   return <button onClick={handleImage}>Add Image</button>
 * }
 *
 * // Advanced usage with configuration
 * function MyAdvancedImageButton() {
 *   const { isVisible, handleImage, label, isActive } = useImage({
 *     editor: myEditor,
 *     hideWhenUnavailable: true,
 *     onInserted: () => console.log('Image inserted!')
 *   })
 *
 *   if (!isVisible) return null
 *
 *   return (
 *     <MyButton
 *       onClick={handleImage}
 *       aria-pressed={isActive}
 *       aria-label={label}
 *     >
 *       Add Image
 *     </MyButton>
 *   )
 * }
 * ```
 */
export function useImageUpload(config?: UseImageUploadConfig) {
  const { editor: providedEditor, hideWhenUnavailable = false, onInserted } = config || {}

  const { editor } = useTiptapEditor(providedEditor)
  const isMobile = useIsBreakpoint()
  const [isVisible, setIsVisible] = useState<boolean>(true)
  const canInsert = canInsertImage(editor)
  const isActive = isImageActive(editor)

  useEffect(() => {
    if (!editor) return

    const handleSelectionUpdate = () => {
      setIsVisible(shouldShowButton({ editor, hideWhenUnavailable }))
    }

    handleSelectionUpdate()

    editor.on('selectionUpdate', handleSelectionUpdate)

    return () => {
      editor.off('selectionUpdate', handleSelectionUpdate)
    }
  }, [editor, hideWhenUnavailable])

  const handleImage = useCallback(() => {
    if (!editor) return false

    void insertNativeImage(editor).then(success => {
      if (success) {
        onInserted?.()
      }
    })
    return true
  }, [editor, onInserted])

  useHotkeys(
    IMAGE_UPLOAD_SHORTCUT_KEY,
    event => {
      event.preventDefault()
      handleImage()
    },
    {
      enabled: isVisible && canInsert,
      enableOnContentEditable: !isMobile,
      enableOnFormTags: true,
    }
  )

  return {
    isVisible,
    isActive,
    handleImage,
    canInsert,
    label: 'Add image',
    shortcutKeys: IMAGE_UPLOAD_SHORTCUT_KEY,
    Icon: ImagePlusIcon,
  }
}
