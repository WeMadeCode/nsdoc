import { BridgeError, toBridgeError } from './errors'
import type { BridgeCallOptions, BridgeHandler, BridgeMessage, NSBridgeAPI } from './types'
import { BRIDGE_VERSION } from './types'

type PendingRequest = {
  resolve(value: unknown): void
  reject(reason: BridgeError): void
  timer: number
}

const DEFAULT_TIMEOUT_MS = 2000

const makeId = (prefix: 'req' | 'evt') => `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`

const handlerKey = (namespace: string, method: string) => `${namespace}.${method}`

class NSBridgeWeb implements NSBridgeAPI {
  private handlers = new Map<string, BridgeHandler>()
  private pending = new Map<string, PendingRequest>()

  call<TParams = unknown, TResult = unknown>(
    namespace: string,
    method: string,
    params?: TParams,
    options?: BridgeCallOptions
  ): Promise<TResult> {
    if (!this.nativeHandler) {
      return Promise.reject(new BridgeError('NATIVE_UNAVAILABLE', 'Native bridge channel is unavailable', true))
    }

    const id = makeId('req')
    const timeoutMs = options?.timeoutMs ?? DEFAULT_TIMEOUT_MS
    const message = this.makeMessage('request', id, namespace, method, params)

    return new Promise<TResult>((resolve, reject) => {
      const timer = window.setTimeout(() => {
        this.pending.delete(id)
        reject(new BridgeError('TIMEOUT', `Bridge request ${namespace}.${method} timed out`, true))
      }, timeoutMs)

      this.pending.set(id, {
        resolve: value => resolve(value as TResult),
        reject,
        timer,
      })

      this.postToNative(message)
    })
  }

  emit<TParams = unknown>(namespace: string, method: string, params?: TParams) {
    if (!this.nativeHandler) {
      return
    }

    this.postToNative(this.makeMessage('event', makeId('evt'), namespace, method, params))
  }

  ready<TParams = unknown>(namespace: string, method: string, params?: TParams) {
    if (!this.nativeHandler) {
      return
    }

    this.postToNative(this.makeMessage('ready', makeId('evt'), namespace, method, params))
  }

  register<TParams = unknown, TResult = unknown>(namespace: string, method: string, handler: BridgeHandler<TParams, TResult>) {
    const key = handlerKey(namespace, method)
    this.handlers.set(key, handler as BridgeHandler)

    return () => {
      const current = this.handlers.get(key)
      if (current === handler) {
        this.handlers.delete(key)
      }
    }
  }

  receiveFromNative(message: BridgeMessage) {
    if (!this.isValidMessage(message)) {
      return
    }

    if (message.type === 'response') {
      this.resolvePending(message)
      return
    }

    if (message.type === 'request') {
      void this.handleNativeRequest(message)
    }
  }

  private get nativeHandler() {
    return window.webkit?.messageHandlers?.nsBridge
  }

  private postToNative(message: BridgeMessage) {
    this.nativeHandler?.postMessage(message)
  }

  private makeMessage<TParams>(
    type: BridgeMessage['type'],
    id: string,
    namespace: string,
    method: string,
    params?: TParams
  ): BridgeMessage<TParams> {
    return {
      bridgeVersion: BRIDGE_VERSION,
      id,
      type,
      namespace,
      method,
      params,
      timestamp: Date.now(),
    }
  }

  private isValidMessage(message: BridgeMessage) {
    return (
      typeof message === 'object' &&
      typeof message.bridgeVersion === 'string' &&
      typeof message.id === 'string' &&
      typeof message.type === 'string' &&
      typeof message.namespace === 'string' &&
      typeof message.method === 'string'
    )
  }

  private resolvePending(message: BridgeMessage) {
    const pending = this.pending.get(message.id)
    if (!pending) {
      return
    }

    window.clearTimeout(pending.timer)
    this.pending.delete(message.id)

    if (message.status === 'success') {
      pending.resolve(message.data)
      return
    }

    const error = message.error
    pending.reject(new BridgeError(error?.code ?? 'HANDLER_ERROR', error?.message ?? 'Bridge request failed', error?.recoverable ?? true))
  }

  private async handleNativeRequest(message: BridgeMessage) {
    const handler = this.handlers.get(handlerKey(message.namespace, message.method))

    if (!handler) {
      this.postToNative({
        bridgeVersion: BRIDGE_VERSION,
        id: message.id,
        type: 'response',
        namespace: message.namespace,
        method: message.method,
        status: 'error',
        error: new BridgeError('METHOD_NOT_FOUND', `Handler ${message.namespace}.${message.method} is not registered`, false).toPayload(),
        timestamp: Date.now(),
      })
      return
    }

    try {
      const data = await handler(message.params)
      this.postToNative({
        bridgeVersion: BRIDGE_VERSION,
        id: message.id,
        type: 'response',
        namespace: message.namespace,
        method: message.method,
        status: 'success',
        data,
        timestamp: Date.now(),
      })
    } catch (error) {
      this.postToNative({
        bridgeVersion: BRIDGE_VERSION,
        id: message.id,
        type: 'response',
        namespace: message.namespace,
        method: message.method,
        status: 'error',
        error: toBridgeError(error).toPayload(),
        timestamp: Date.now(),
      })
    }
  }
}

export const nsBridge = new NSBridgeWeb()

window.NSBridge = nsBridge
