import { memo } from 'react'

import { NodeViewContent, NodeViewWrapper, type ReactNodeViewProps } from '@tiptap/react'

const CodeBlockWrapper = (params: ReactNodeViewProps) => {
  const { node } = params
  const defaultLanguage = (node.attrs.language as string | undefined) ?? ''

  return (
    <NodeViewWrapper className={'code-block'}>
      <span className="code-block-language">{defaultLanguage}</span>
      {/* <select
        contentEditable={false}
        defaultValue={defaultLanguage}
        onChange={event => {
          console.log(event.target.value)
          updateAttributes({ language: event.target.value })
        }}
      >
        <option value="null">auto</option>
        <option disabled>—</option>
        {extension.options.lowlight.listLanguages().map((lang: string, index: number) => (
          <option key={index} value={lang}>
            {lang}
          </option>
        ))}
      </select> */}
      <pre>
        <NodeViewContent as="code" />
      </pre>
    </NodeViewWrapper>
  )
}

export default memo(CodeBlockWrapper)
