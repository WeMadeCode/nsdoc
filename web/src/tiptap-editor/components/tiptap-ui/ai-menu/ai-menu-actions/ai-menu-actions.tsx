'use client'

import '@/tiptap-editor/components/tiptap-ui/ai-menu/ai-menu-actions/ai-menu-actions.scss'

import type { Editor } from '@tiptap/react'
import type { TextOptions } from '@tiptap-pro/extension-ai'
import { useCallback } from 'react'

import { CheckIcon } from '@/tiptap-editor/components/tiptap-icons/check-icon'
import { RefreshAiIcon } from '@/tiptap-editor/components/tiptap-icons/refresh-ai-icon'
import { XIcon } from '@/tiptap-editor/components/tiptap-icons/x-icon'
import { Button } from '@/tiptap-editor/components/tiptap-ui-primitive/button'
import { ButtonGroup } from '@/tiptap-editor/components/tiptap-ui-primitive/button-group'
import { useUiEditorState } from '@/tiptap-editor/hooks/use-ui-editor-state'

export interface AiMenuActionsProps {
  editor: Editor | null
  options: TextOptions
  onRegenerate?: () => void
  onAccept?: () => void
  onReject?: () => void
}

export function AiMenuActions({ editor, options, onRegenerate, onAccept, onReject }: AiMenuActionsProps) {
  const { aiGenerationIsLoading } = useUiEditorState(editor)

  const handleRegenerate = useCallback(() => {
    if (!editor) {
      return
    }
    editor.chain().focus().aiRegenerate(options).run()
    onRegenerate?.()
  }, [editor, onRegenerate, options])

  const handleDiscard = useCallback(() => {
    if (!editor) {
      return
    }
    editor.chain().focus().aiReject().run()
    onReject?.()
  }, [editor, onReject])

  const handleApply = useCallback(() => {
    if (!editor) {
      return
    }
    editor.chain().focus().aiAccept().run()
    onAccept?.()
  }, [editor, onAccept])

  return (
    <div className="tiptap-ai-menu-actions">
      <div className="tiptap-ai-menu-results">
        <Button variant="ghost" className="tiptap-button" onClick={handleRegenerate} disabled={aiGenerationIsLoading}>
          <RefreshAiIcon className="tiptap-button-icon" />
          Try again
        </Button>
      </div>

      <div className="tiptap-ai-menu-commit">
        <ButtonGroup>
          <ButtonGroup>
            <Button variant="ghost" className="tiptap-button" onClick={handleDiscard}>
              <XIcon className="tiptap-button-icon" />
              Discard
            </Button>
          </ButtonGroup>

          <ButtonGroup>
            <Button data-style="primary" className="tiptap-button" onClick={handleApply}>
              <CheckIcon className="tiptap-button-icon" />
              Apply
            </Button>
          </ButtonGroup>
        </ButtonGroup>
      </div>
    </div>
  )
}
