import type { JSONContent } from '@tiptap/core'

export const BRIDGE_VERSION = '1.0'

export type BridgeMessageType = 'request' | 'response' | 'event' | 'ready'

export type BridgeResponseStatus = 'success' | 'error'

export type BridgeErrorCode =
  | 'BRIDGE_NOT_READY'
  | 'NATIVE_UNAVAILABLE'
  | 'WEB_UNAVAILABLE'
  | 'TIMEOUT'
  | 'METHOD_NOT_FOUND'
  | 'INVALID_MESSAGE'
  | 'INVALID_PARAMS'
  | 'UNAUTHORIZED'
  | 'PAYLOAD_TOO_LARGE'
  | 'HANDLER_ERROR'
  | 'VERSION_UNSUPPORTED'

export type BridgeErrorPayload = {
  code: BridgeErrorCode
  message: string
  recoverable: boolean
}

export type BridgeMessage<TParams = unknown, TData = unknown> = {
  bridgeVersion: string
  id: string
  type: BridgeMessageType
  namespace: string
  method: string
  params?: TParams
  status?: BridgeResponseStatus
  data?: TData
  error?: BridgeErrorPayload
  timestamp: number
}

export type BridgeCallOptions = {
  timeoutMs?: number
}

export type BridgeHandler<TParams = unknown, TResult = unknown> = (params: TParams) => TResult | Promise<TResult>

export type EditorActiveTools = {
  paragraph: boolean
  bold: boolean
  italic: boolean
  underline: boolean
  strike: boolean
  code: boolean
  heading: {
    active: boolean
    level?: number
  }
  bulletList: boolean
  orderedList: boolean
  taskList: boolean
  blockquote: boolean
  codeBlock: boolean
  textAlign: 'left' | 'center' | 'right' | 'justify'
}

export type EditorSelectionContext = {
  isInTitle: boolean
  textColor?: string | null
  backgroundColor?: string | null
}

export type EditorHistoryState = {
  canUndo: boolean
  canRedo: boolean
}

export type EditorContentSnapshot = {
  changeVersion: number
  title: string
  content: JSONContent
  isEmpty: boolean
  reason?: 'debounced' | 'flush' | 'destroy'
}

export type EditorOpenDocParams = {
  content?: JSONContent | null
  focus?: boolean
}

export type EditorHostPlatform = 'iphone' | 'mac'

export type EditorAppInfo = {
  hostPlatform: EditorHostPlatform
  editorMode?: string
}

export type EditorBooleanResult = {
  active?: boolean
  applied?: boolean
  inserted?: boolean
  focused?: boolean
  blurred?: boolean
  level?: number
  align?: string
}

export type MediaImageResult = {
  attachmentId: string
  src: string
  filename: string
  mimeType: string
  byteSize: number
}

export type MediaPickImageParams = {
  source?: 'photoLibrary'
}

export type MediaPickImageResult = MediaImageResult

export type MediaResolveImageParams = {
  attachmentId: string
}

export type MediaResolveImageResult = {
  src: string
  mimeType: string
}

declare global {
  interface Window {
    NSBridge: NSBridgeAPI
    webkit?: {
      messageHandlers?: {
        nsBridge?: {
          postMessage(message: BridgeMessage): void
        }
        webConsoleLog?: {
          postMessage(message: { level: string; message: string }): void
        }
      }
    }
  }
}

export type NSBridgeAPI = {
  receiveFromNative(message: BridgeMessage): void
  call<TParams = unknown, TResult = unknown>(
    namespace: string,
    method: string,
    params?: TParams,
    options?: BridgeCallOptions
  ): Promise<TResult>
  emit<TParams = unknown>(namespace: string, method: string, params?: TParams): void
  register<TParams = unknown, TResult = unknown>(namespace: string, method: string, handler: BridgeHandler<TParams, TResult>): () => void
}
