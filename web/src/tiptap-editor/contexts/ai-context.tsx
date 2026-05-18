'use client'

import { createContext, useContext, useEffect, useMemo, useState } from 'react'

import { fetchAiToken, getUrlParam } from '@/tiptap-editor/lib/tiptap-collab-utils'

export type AiContextValue = {
  aiToken: string | null
  hasAi: boolean
  setupError: boolean
}

export const AiContext = createContext<AiContextValue>({
  hasAi: false,
  aiToken: null,
  setupError: false,
})

export const AiConsumer = AiContext.Consumer
export const useAi = (): AiContextValue => {
  const context = useContext(AiContext)
  if (!context) {
    throw new Error('useAi must be used within an AiProvider')
  }
  return context
}

export const useAiToken = () => {
  const [aiToken, setAiToken] = useState<string | null>(null)
  const [hasAi, setHasAi] = useState<boolean>(true)
  const [setupError, setSetupError] = useState<boolean>(false)

  useEffect(() => {
    const noAiParam = getUrlParam('noAi')
    setHasAi(parseInt(noAiParam || '0') !== 1)
  }, [])

  useEffect(() => {
    if (!hasAi) {
      setAiToken(null)
      setSetupError(false)
      return
    }

    const getToken = async () => {
      const token = await fetchAiToken()
      if (!token) {
        // Missing token should gracefully degrade to non-AI mode.
        setHasAi(false)
        setSetupError(false)
        return
      }
      setAiToken(token)
      setSetupError(false)
    }

    getToken()
  }, [hasAi])

  return { aiToken, hasAi, setupError }
}

export function AiProvider({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  const { hasAi, aiToken, setupError } = useAiToken()

  const value = useMemo<AiContextValue>(
    () => ({
      hasAi,
      aiToken,
      setupError,
    }),
    [hasAi, aiToken, setupError]
  )

  return <AiContext.Provider value={value}>{children}</AiContext.Provider>
}
