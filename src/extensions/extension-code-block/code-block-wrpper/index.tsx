import { memo } from "react";

import {
  NodeViewContent,
  NodeViewWrapper,
  type ReactNodeViewProps,
} from "@tiptap/react";
import styles from "./index.module.scss";
const CodeBlockWrapper = (params: ReactNodeViewProps) => {
  const { node, updateAttributes, extension } = params;
  const defaultLanguage = (node.attrs.language as string | undefined) ?? "";
  console.log("???");
  return (
    <NodeViewWrapper className={"code-block"}>
      <select
        contentEditable={false}
        defaultValue={defaultLanguage}
        onChange={(event) => {
          console.log(event.target.value);
          updateAttributes({ language: event.target.value });
        }}
      >
        <option value="null">auto</option>
        <option disabled>—</option>
        {extension.options.lowlight
          .listLanguages()
          .map((lang: string, index: number) => (
            <option key={index} value={lang}>
              {lang}
            </option>
          ))}
      </select>
      <pre>
        <NodeViewContent className={styles.wrap} as="code" />
      </pre>
    </NodeViewWrapper>
  );
};

export default memo(CodeBlockWrapper);
