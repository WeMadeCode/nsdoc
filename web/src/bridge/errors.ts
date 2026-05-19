import type { BridgeErrorCode, BridgeErrorPayload } from './types'

export class BridgeError extends Error {
  readonly code: BridgeErrorCode
  readonly recoverable: boolean

  constructor(code: BridgeErrorCode, message: string, recoverable = false) {
    super(message)
    this.name = 'BridgeError'
    this.code = code
    this.recoverable = recoverable
  }

  toPayload(): BridgeErrorPayload {
    return {
      code: this.code,
      message: this.message,
      recoverable: this.recoverable,
    }
  }
}

export const toBridgeError = (error: unknown): BridgeError => {
  if (error instanceof BridgeError) {
    return error
  }

  if (error instanceof Error) {
    return new BridgeError('HANDLER_ERROR', error.message, true)
  }

  return new BridgeError('HANDLER_ERROR', 'Bridge handler failed', true)
}

