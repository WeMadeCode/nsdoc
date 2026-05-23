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
}

export type EditorContentSnapshot = {
  changeVersion: number
  title: string
  content: JSONContent
  isEmpty: boolean
  reason?: 'debounced' | 'flush' | 'destroy'
}

export type EditorSetContentParams = {
  content?: JSONContent | null
  focus?: boolean
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

declare global {
  interface Window {
    NSBridge: NSBridgePublicApi
    __NSBridge: {
      receiveFromNative(message: BridgeMessage): void
    }
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

export type NSBridgePublicApi = {
  call<TParams = unknown, TResult = unknown>(
    namespace: string,
    method: string,
    params?: TParams,
    options?: BridgeCallOptions
  ): Promise<TResult>
  emit<TParams = unknown>(namespace: string, method: string, params?: TParams): void
  register<TParams = unknown, TResult = unknown>(namespace: string, method: string, handler: BridgeHandler<TParams, TResult>): () => void
}
