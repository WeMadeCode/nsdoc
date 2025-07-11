import { CodeBlockLowlight as CodeBlockLowlightTipTap } from "@tiptap/extension-code-block-lowlight";
import { ReactNodeViewRenderer } from "@tiptap/react";
import CodeBlockWrapper from "./code-block-wrpper";

import css from "highlight.js/lib/languages/css";
import js from "highlight.js/lib/languages/javascript";
import ts from "highlight.js/lib/languages/typescript";
import html from "highlight.js/lib/languages/xml";
import { all, createLowlight } from "lowlight";

const lowlight = createLowlight(all);

lowlight.register("html", html);
lowlight.register("css", css);
lowlight.register("js", js);
lowlight.register("ts", ts);

export const CodeBlockLowlight = CodeBlockLowlightTipTap.extend({
  addNodeView() {
    return ReactNodeViewRenderer(CodeBlockWrapper);
  },
}).configure({ lowlight });
