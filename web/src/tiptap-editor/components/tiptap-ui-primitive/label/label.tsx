'use client'

import './label.scss'

import * as React from 'react'

import { cn } from '@/tiptap-editor/lib/tiptap-utils'

function Label({ className, ...props }: React.ComponentProps<'label'>) {
  return <label data-slot="tiptap-label" className={cn('tiptap-label', className)} {...props} />
}

export { Label }
