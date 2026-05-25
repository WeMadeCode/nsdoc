'use client'

import './textarea.scss'

import { cn } from '@/tiptap-editor/lib/tiptap-utils'

function Textarea({ className, ...props }: React.ComponentProps<'textarea'>) {
  return <textarea data-slot="textarea" className={cn('textarea', className)} {...props} />
}

export { Textarea }
