// import React from "react";

import { EditorContent, useEditor } from '@tiptap/react'
import styles from './index.module.scss'

import { extensions } from '../extensions/index'

const Editor = () => {
  const content = `
        <p>
          That's a boring paragraph followed by a fenced code block:
        </p>
        <pre><code class="language-javascript">for (var i=1; i <= 20; i++)
{
  if (i % 15 == 0)
    console.log("FizzBuzz");
  else if (i % 3 == 0)
    console.log("Fizz");
  else if (i % 5 == 0)
    console.log("Buzz");
  else
    console.log(i);
}</code></pre>
        <p>
          Press Command/Ctrl + Enter to leave the fenced code block and continue typing in boring paragraphs.
        </p>
      `

  const editor = useEditor({
    extensions: extensions,
    // content: content,
  })

  return (
    <div
      className={styles.wrap}
      onClick={() => {
        editor?.chain().focus().run()
      }}
      onTouchEnd={() => {
        editor?.chain().focus().run()
      }}
    >
      <EditorContent editor={editor} />
    </div>
  )
}

export default Editor
