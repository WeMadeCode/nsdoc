import { useEffect, useState } from 'react'

import type { EditorAppInfo } from '@/bridge/types'
import { nsBridge } from '@/bridge/web-bridge'
import { NotionEditor } from '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor'
import { SimpleEditor } from '@/tiptap-editor/components/tiptap-templates/simple/simple-editor'

const defaultAppInfo: EditorAppInfo = {
  hostPlatform: 'iphone',
}

const isAppInfo = (value: unknown): value is EditorAppInfo => {
  if (!value || typeof value !== 'object') {
    return false
  }

  const appInfo = value as Partial<EditorAppInfo>

  return appInfo.hostPlatform === 'iphone' || appInfo.hostPlatform === 'mac'
}

const App = () => {
  const [appInfo, setAppInfo] = useState<EditorAppInfo | null>(null)

  useEffect(() => {
    let active = true

    nsBridge
      .call<undefined, EditorAppInfo>('editor', 'getAppInfo')
      .then(info => {
        if (!isAppInfo(info)) {
          throw new Error('editor.getAppInfo returned invalid app info')
        }
        if (active) {
          setAppInfo(info)
        }
      })
      .catch(() => {
        if (active) {
          setAppInfo(defaultAppInfo)
        }
      })

    return () => {
      active = false
    }
  }, [])

  if (appInfo) {
    return (
      <div style={{ width: '100%', height: '100vh' }}>
        {appInfo.hostPlatform === 'mac' ? <NotionEditor room="local-mac-editor" /> : <SimpleEditor />}
      </div>
    )
  } else {
    return (
      <div style={{ width: '100%', height: '100vh' }}>
        <NotionEditor room="local-mac-editor" />
      </div>
    )
  }
}

export default App
