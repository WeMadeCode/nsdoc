import { useEffect, useState } from 'react'

import type { EditorRuntimeConfig } from '@/bridge/types'
import { nsBridge } from '@/bridge/web-bridge'
import { NotionEditor } from '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor'
import { SimpleEditor } from '@/tiptap-editor/components/tiptap-templates/simple/simple-editor'

const defaultRuntimeConfig: EditorRuntimeConfig = {
  hostPlatform: 'iphone',
  editorMode: 'simple',
}

const isRuntimeConfig = (value: unknown): value is EditorRuntimeConfig => {
  if (!value || typeof value !== 'object') {
    return false
  }

  const config = value as Partial<EditorRuntimeConfig>

  return (
    (config.hostPlatform === 'iphone' || config.hostPlatform === 'mac') &&
    (config.editorMode === 'simple' || config.editorMode === 'notion')
  )
}

const getInitialRuntimeConfig = () => {
  if (isRuntimeConfig(window.__NSRuntimeConfig)) {
    return window.__NSRuntimeConfig
  }

  return defaultRuntimeConfig
}

const App = () => {
  const [runtimeConfig, setRuntimeConfig] = useState<EditorRuntimeConfig>(getInitialRuntimeConfig)

  useEffect(() => {
    return nsBridge.register<EditorRuntimeConfig, EditorRuntimeConfig>('editor', 'configureRuntime', params => {
      if (!isRuntimeConfig(params)) {
        throw new Error('editor.configureRuntime requires a valid runtime config')
      }

      window.__NSRuntimeConfig = params
      setRuntimeConfig(params)
      return params
    })
  }, [])

  return (
    <div style={{ width: '100%', height: '100vh' }}>
      {runtimeConfig.editorMode === 'notion' ? <NotionEditor room="local-mac-editor" /> : <SimpleEditor />}
    </div>
  )
}

export default App
