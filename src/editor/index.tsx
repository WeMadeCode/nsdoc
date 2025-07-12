// import React from "react";

import { EditorContent, useEditor } from "@tiptap/react";
import styles from "./index.module.scss";

import { extensions } from "../extensions/index";

const Editor = () => {
  //   const content = `## 标题二
  // ---

  // [123](https://stackblitz.com/edit/stackblitz-starters-aurlug?file=src%2FApp.tsx)

  // ![](https://www.baidu.com/img/PCtm_d9c8750bed0b3c7d089fa7d55720d6cf.png)

  // ~~~css
  // body{ color:red}
  // ~~~

  // > 区块中使用列表
  // > 1. 第一项
  // > 2. 第二项
  // > + 第一项
  // > + 第二项
  // > + 第三项

  // **sdsd**
  // - sdd
  // - [ ] dssd
  // `;

  //   const content = `
  //   <table style="width:100%">
  //     <tr>
  //       <th>Firstname</th>
  //       <th>Lastname</th>
  //       <th>Age</th>
  //     </tr>
  //     <tr>
  //       <td>Jill</td>
  //       <td>Smith</td>
  //       <td>50</td>
  //     </tr>
  //     <tr>
  //       <td>Eve</td>
  //       <td>Jackson</td>
  //       <td>94</td>
  //     </tr>
  //     <tr>
  //       <td>John</td>
  //       <td>Doe</td>
  //       <td>80</td>
  //     </tr>
  //   </table>
  // `;

  const editor = useEditor({
    extensions: extensions,
    // content: tableHTML,
  });

  return (
    <div
      className={styles.wrap}
      onClick={() => {
        editor?.chain().focus().run();
      }}
      onTouchEnd={() => {
        editor?.chain().focus().run();
      }}
    >
      <EditorContent editor={editor} />
    </div>
  );
};

export default Editor;
