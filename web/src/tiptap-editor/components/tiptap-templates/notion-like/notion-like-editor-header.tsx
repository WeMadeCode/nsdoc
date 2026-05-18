'use client'

// --- Styles ---
import '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor-header.scss'

import { CollaborationUsers } from '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor-collaboration-users'
import { ThemeToggle } from '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor-theme-toggle'
import { BlockquoteButton } from '@/tiptap-editor/components/tiptap-ui/blockquote-button'
import { CodeBlockButton } from '@/tiptap-editor/components/tiptap-ui/code-block-button'
import { ColorHighlightPopover } from '@/tiptap-editor/components/tiptap-ui/color-highlight-popover'
import { HeadingDropdownMenu } from '@/tiptap-editor/components/tiptap-ui/heading-dropdown-menu'
import { ImageUploadButton } from '@/tiptap-editor/components/tiptap-ui/image-upload-button'
import { LinkPopover } from '@/tiptap-editor/components/tiptap-ui/link-popover'
import { ListDropdownMenu } from '@/tiptap-editor/components/tiptap-ui/list-dropdown-menu'
import { MarkButton } from '@/tiptap-editor/components/tiptap-ui/mark-button'
import { TextAlignButton } from '@/tiptap-editor/components/tiptap-ui/text-align-button'
// --- Tiptap UI ---
import { UndoRedoButton } from '@/tiptap-editor/components/tiptap-ui/undo-redo-button'
// --- UI Primitives ---
import { Spacer } from '@/tiptap-editor/components/tiptap-ui-primitive/spacer'
import { Toolbar, ToolbarGroup, ToolbarSeparator } from '@/tiptap-editor/components/tiptap-ui-primitive/toolbar'

export function NotionEditorHeader() {
  return (
    <header className="notion-like-editor-header">
      <Toolbar className="notion-like-editor-header-toolbar">
        <Spacer />

        <ToolbarGroup>
          <UndoRedoButton action="undo" />
          <UndoRedoButton action="redo" />
        </ToolbarGroup>

        <ToolbarSeparator />

        <ToolbarGroup>
          <HeadingDropdownMenu modal={false} levels={[1, 2, 3, 4]} />
          <ListDropdownMenu modal={false} types={['bulletList', 'orderedList', 'taskList']} />
          <BlockquoteButton />
          <CodeBlockButton />
        </ToolbarGroup>

        <ToolbarSeparator />

        <ToolbarGroup>
          <MarkButton type="bold" />
          <MarkButton type="italic" />
          <MarkButton type="strike" />
          <MarkButton type="code" />
          <MarkButton type="underline" />
          <ColorHighlightPopover />
          <LinkPopover />
        </ToolbarGroup>

        <ToolbarSeparator />

        <ToolbarGroup>
          <MarkButton type="superscript" />
          <MarkButton type="subscript" />
        </ToolbarGroup>

        <ToolbarSeparator />

        <ToolbarGroup>
          <TextAlignButton align="left" />
          <TextAlignButton align="center" />
          <TextAlignButton align="right" />
          <TextAlignButton align="justify" />
        </ToolbarGroup>

        <ToolbarSeparator />

        <ToolbarGroup>
          <ImageUploadButton text="Add" />
        </ToolbarGroup>

        <Spacer />

        <ToolbarGroup>
          <ThemeToggle />
          <CollaborationUsers />
        </ToolbarGroup>
      </Toolbar>
    </header>
  )
}
