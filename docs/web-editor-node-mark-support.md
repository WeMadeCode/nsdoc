# Web 编辑器 Node / Mark 插入能力盘点

## 盘点口径

- 当前 Web 入口：`web/src/App.tsx` 渲染 `SimpleEditor`。
- 当前运行编辑器：`web/src/tiptap-editor/components/tiptap-templates/simple/simple-editor.tsx`。
- 当前扩展来源：`web/src/tiptap-editor/extensions/index.ts` 加 `ImageUploadNode`。
- 补充参考：仓库内还保留了一套 Notion-like 编辑器模板，但当前入口没有渲染它。

本文把“当前运行编辑器已注册的 Node / Mark”和“当前可通过 Native Bridge 直接调用的插入/切换能力”分开列出。

## 当前运行编辑器已注册的 Node

| Node | 来源 | 当前插入/切换入口 | 说明 |
| --- | --- | --- | --- |
| `doc` | `extension-document` | 内容根节点 | 自定义 Document，要求 `title{1} block+`。 |
| `title` | `extension-title` | 初始化/内容结构 | 自定义标题节点，文档必须包含 1 个。 |
| `paragraph` | `@tiptap/extension-paragraph` | Bridge: `editor.setParagraph` | 普通文本段落。 |
| `text` | `@tiptap/extension-text` | 输入文本 | 行内文本节点。 |
| `hardBreak` | `@tiptap/extension-hard-break` | 键盘换行 | 硬换行。 |
| `heading` | `@tiptap/extension-heading` | Bridge: `editor.toggleHeading` | 当前 Bridge 允许 level 1-5；扩展默认支持 1-6。 |
| `blockquote` | `@tiptap/extension-blockquote` | Bridge: `editor.toggleBlockquote` | 引用块。 |
| `codeBlock` | 自定义 `CodeBlockLowlight` | Bridge: `editor.toggleCodeBlock` | 代码块，使用 React NodeView 包装。 |
| `bulletList` | `@tiptap/extension-bullet-list` | Bridge: `editor.toggleBulletList` | 无序列表。 |
| `orderedList` | `@tiptap/extension-ordered-list` | Bridge: `editor.toggleOrderedList` | 有序列表。 |
| `listItem` | `@tiptap/extension-list-item` | 列表命令内部使用 | 列表项。 |
| `taskList` | `@tiptap/extension-task-list` | Bridge: `editor.toggleTaskList` | 任务列表容器。 |
| `taskItem` | `@tiptap/extension-task-item` | 任务列表命令内部使用 | 任务项。 |
| `image` | `@tiptap/extension-image` | Schema 已注册；当前 Bridge 未暴露 | 支持图片节点本体；当前运行入口未提供图片 UI。 |
| `imageUpload` | 自定义 `ImageUploadNode` | Schema 已注册；当前 Bridge 未暴露 | 上传占位节点，配置 `accept=image/*`、`limit=3`、`maxSize=MAX_FILE_SIZE`。 |
| `table` | `TableKit` | Bridge: `editor.insertTable` | 表格，默认 Bridge 插入 3x3 且带表头。 |
| `tableRow` | `TableKit` | 表格命令内部使用 | 表格行。 |
| `tableHeader` | `TableKit` | 表格命令内部使用 | 表头单元格。 |
| `tableCell` | 自定义 `extension-table-cell` | 表格命令内部使用 | 扩展了 `backgroundColor` 属性。 |
| `horizontalRule` | 自定义 `extension-horizontal-rule` | Bridge: `editor.setHorizontalRule` | 分割线。 |

## 当前运行编辑器已注册的 Mark

| Mark | 来源 | 当前插入/切换入口 | 说明 |
| --- | --- | --- | --- |
| `bold` | `@tiptap/extension-bold` | Bridge: `editor.toggleBold` | 粗体。 |
| `italic` | `@tiptap/extension-italic` | Bridge: `editor.toggleItalic` | 斜体。 |
| `underline` | `@tiptap/extension-underline` | Bridge: `editor.toggleUnderline` | 下划线。 |
| `strike` | `@tiptap/extension-strike` | Bridge: `editor.toggleStrike` | 删除线。 |
| `code` | `@tiptap/extension-code` | Bridge: `editor.toggleCode` | 行内代码。 |
| `link` | `@tiptap/extension-link` | Schema 已注册；当前 Bridge 未暴露 | 链接 Mark，`openOnClick` 使用扩展默认行为。 |
| `highlight` | `@tiptap/extension-highlight` | Schema 已注册；当前 Bridge 未暴露 | 高亮 Mark，当前注册未开启 Notion-like 中的 `multicolor` 配置。 |
| `textStyle` | `@tiptap/extension-text-style` | Schema 已注册；当前 Bridge 未暴露 | 文本样式承载 Mark。 |
| `color` | `@tiptap/extension-text-style` 的 `Color` | Schema 已注册；当前 Bridge 未暴露 | 通过 `textStyle` 写入文字颜色。 |
| `backgroundColor` | `@tiptap/extension-text-style` 的 `BackgroundColor` | Schema 已注册；当前 Bridge 未暴露 | 通过 `textStyle` 写入背景色。 |
| `subscript` | `@tiptap/extension-subscript` | Schema 已注册；当前 Bridge 未暴露 | 下标。 |
| `superscript` | `@tiptap/extension-superscript` | Schema 已注册；当前 Bridge 未暴露 | 上标。 |

## 当前 Native Bridge 暴露的能力

`web/src/bridge/editor-handlers.ts` 当前向原生侧声明并注册这些编辑器能力：

### 内容与焦点

- `editor.setContent`
- `editor.flushContent`
- `editor.focus`
- `editor.blur`

### Mark 切换

- `editor.toggleBold`
- `editor.toggleItalic`
- `editor.toggleUnderline`
- `editor.toggleStrike`
- `editor.toggleCode`

### Node 插入/切换

- `editor.setParagraph`
- `editor.toggleHeading`，参数 `level` 仅允许 1-5
- `editor.toggleBulletList`
- `editor.toggleOrderedList`
- `editor.toggleTaskList`
- `editor.toggleBlockquote`
- `editor.toggleCodeBlock`
- `editor.setHorizontalRule`
- `editor.insertTable`

### 排版属性

- `editor.setTextAlign`，允许 `left`、`center`、`right`、`justify`

## 当前入口没有直接暴露的已注册能力

这些能力在当前 `SimpleEditor` 的 schema 中存在，但没有通过当前 Bridge 暴露，也没有在当前入口挂载对应 Web UI：

- 图片本体：`image`
- 图片上传占位：`imageUpload`
- 链接：`link`
- 文本颜色：`color` / `textStyle`
- 文本背景色：`backgroundColor` / `textStyle`
- 高亮：`highlight`
- 上标/下标：`superscript` / `subscript`
- Heading 6：扩展默认可用，但 Bridge 参数只允许 1-5

## Notion-like 模板里额外实现但当前入口未使用的能力

`web/src/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor.tsx` 额外注册或挂载了更多能力，包括：

- Slash 菜单可插入/切换：Text、Heading 1/2/3、Bullet List、Numbered List、To-do List、Blockquote、Code Block、Mention、Emoji、Table、Separator、Table of contents、Image。
- 目录节点：`tocNode`，命令为 `insertTocNode`。
- Mention：`mention`。
- Emoji：`emoji`。
- Mathematics：数学扩展。
- 表格增强：表格句柄、选择覆盖层、行列增删改、合并拆分、排序、适配宽度等。
- 节点背景色：`nodeBackground`。
- 节点对齐：`nodeAlignment`。
- 缩进：`indent`。
- 协作：`Collaboration`、`CollaborationCaret`。
- 目录数据：`TableOfContents`。
- 唯一 ID：`UniqueID`。

注意：这些能力已经在仓库内实现，但除非把入口从 `SimpleEditor` 切到 `NotionEditor`，或者把对应扩展/UI/Bridge 补到 `SimpleEditor`，否则不能算当前运行编辑器的直接可用入口。

## 主要源码索引

- 当前入口：`web/src/App.tsx`
- 当前编辑器：`web/src/tiptap-editor/components/tiptap-templates/simple/simple-editor.tsx`
- 当前基础扩展集合：`web/src/tiptap-editor/extensions/index.ts`
- Bridge 能力：`web/src/bridge/editor-handlers.ts`
- 自定义标题节点：`web/src/tiptap-editor/extensions/extension-title/index.ts`
- 自定义文档结构：`web/src/tiptap-editor/extensions/extension-document/index.ts`
- 自定义代码块：`web/src/tiptap-editor/extensions/extension-code-block/index.ts`
- 自定义分割线：`web/src/tiptap-editor/extensions/extension-horizontal-rule/index.ts`
- 自定义表格单元格：`web/src/tiptap-editor/extensions/extension-table-cell/index.ts`
- 图片上传节点：`web/src/tiptap-editor/components/tiptap-node/image-upload-node/image-upload-node-extension.ts`
- Notion-like 编辑器：`web/src/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor.tsx`
- Slash 菜单：`web/src/tiptap-editor/components/tiptap-ui/slash-dropdown-menu/use-slash-dropdown-menu.ts`
