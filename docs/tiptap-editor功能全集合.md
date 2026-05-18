# tiptap-editor 功能全集合

## 1. 盘点范围与口径

- 盘点目录：`/tiptap-editor`
- 代码文件规模：
  - 总文件数：440
  - TS/TSX 文件数：385
- 统计口径：
  - 以“可被用户感知的功能能力”为主线，覆盖编辑器模板、扩展、节点、菜单、hooks、contexts、工具库。
  - 纯样式（`.scss`）与图标（`tiptap-icons`）不单独列功能，但已纳入存在性核对。

---

## 2. 模块地图（按职责）

- `components/tiptap-templates/notion-like`
  - 编辑器入口、布局、顶部工具区、浮动工具区、协作用户区、加载与错误态。
- `components/tiptap-templates/simple`
  - 轻量模板入口、单行工具栏、移动端二级工具栏（高亮/链接）、主题切换与示例内容。
- `components/tiptap-extension`
  - 自定义扩展：缩进、列表归一化、节点背景色、节点对齐、UI 状态。
- `components/tiptap-node`
  - 复杂节点：表格、图片、图片上传、目录节点、分割线。
- `components/tiptap-ui`
  - 功能按钮与菜单：AI、格式、颜色、链接、触发器、复制/删除/移动等。
- `components/tiptap-ui/heading-dropdown-menu` + `components/tiptap-ui/list-dropdown-menu`
  - 标题与列表的下拉组合组件（含可复用 hook）。
- `components/tiptap-ui-primitive` + `components/tiptap-ui-utils`
  - 通用 UI 原语与建议菜单基础设施。
- `contexts` + `hooks` + `lib`
  - 协作/AI/用户状态、编辑器状态同步、能力判断、URL 与选择工具函数。

---

## 3. 编辑器内核能力

### 3.1 编辑器装配与运行形态

- 当前有两套模板入口：
  - `NotionEditor`：组合 Provider（`UserProvider -> AppProvider -> CollabProvider -> AiProvider -> TocProvider`）。
  - `SimpleEditor`：轻量本地编辑器，不接入协作/AI/TOC Provider 链路。
- 支持协作与 AI 的“可选启用”：
  - URL 参数 `noCollab=1` 可关闭协作。
  - URL 参数 `noAi=1` 可关闭 AI。
- 协作或 AI token 缺失时，自动降级到本地非协作/非 AI 模式（不中断编辑）。
- 初始化期间有 `LoadingSpinner`；配置异常场景有 `SetupErrorMessage`。

### 3.2 注册的核心扩展（实际启用）

- Notion-like 模板：
  - 基础与文本：`StarterKit`、`TextStyle`、`Color`、`Highlight(multicolor)`、`Typography`。
  - 块与排版：`TextAlign`、`HorizontalRule`、`Indent`、`NodeAlignment`、`NodeBackground`。
  - 结构化内容：`TaskList`、`TaskItem`、`TableKit`、`TocNode`、`TableOfContents`。
  - 富内容：`Image`、`ImageUploadNode`、`Mention`、`Emoji`、`Mathematics`、`Superscript`、`Subscript`。
  - 协作：`Collaboration`、`CollaborationCaret`（条件启用）。
  - AI：`Ai`（条件启用）。
  - 交互增强：`Selection`、`UiState`、`ListNormalizationExtension`、`TableHandleExtension`、`UniqueID`。
- Simple 模板：
  - 基础与文本：`StarterKit`（关闭内置 `horizontalRule`，定制 `link` 交互）、`Highlight(multicolor)`、`Typography`。
  - 块与排版：`HorizontalRule`、`TextAlign(heading,paragraph)`。
  - 结构化内容：`TaskList`、`TaskItem(nested)`。
  - 富内容：`Image`（`@tiptap/extension-image`）与 `ImageUploadNode`（`accept=image/*`、`limit=3`、`maxSize=MAX_FILE_SIZE`）。
  - 交互增强：`Selection`、`Superscript`、`Subscript`。

---

## 4. 文本与块级编辑能力

### 4.1 文本样式与段落能力

- 行内样式：粗体、斜体、下划线、删除线、行内代码、上标、下标。
- 文本颜色与高亮颜色（含最近使用颜色）。
- 段落与标题：Text、Heading1~Heading6。
- 列表：无序、有序、任务列表。
- 引用块、代码块、分割线。
- 链接：设置、编辑、移除、打开（URL 安全清洗）。

### 4.2 Turn Into（块类型转换）

- 支持在可转换块之间切换：
  - Paragraph
  - Heading 1/2/3
  - Bullet / Ordered / Task List
  - Blockquote
  - Code Block
- 针对 NodeSelection 与 TextSelection 都有处理逻辑，尽量保留可编辑光标落点。

### 4.3 缩进与列表归一化

- 缩进扩展：
  - `indent/outdent/setIndent/unsetIndent`
  - 支持 `Tab / Shift+Tab`
  - 在空行 Enter、行首 Backspace 场景触发反缩进
  - 列表场景自动委托到 `sinkListItem/liftListItem`
- 拖拽后缩进归一化：根据上下文块自动修正缩进层级。
- 列表归一化：
  - Backspace 删除两段同类型列表之间的空段落时，自动合并列表，消除“卡住的空白间距”。

---

## 5. AI 能力集合

### 5.1 AI 触发入口

- `Ask AI` 按钮与快捷键触发。
- `Improve` 下拉菜单触发。
- Slash 菜单项触发（Continue Writing / Ask AI）。
- 拖拽上下文菜单触发。

### 5.2 AI 指令能力

- 文本改写：
  - 修正语法拼写
  - 扩写
  - 缩写
  - 简化
  - Emojify
  - Complete sentence
  - Summarize
- 风格与语言：
  - 多种 Tone 调整
  - 多语言翻译（包含中英日韩西俄法葡德等）
- Continue Writing：
  - 根据光标上文自动拼接上下文 prompt 并流式续写。

### 5.3 AI 交互状态与生命周期

- UI 状态：`aiGenerationActive / aiGenerationIsLoading / aiGenerationHasMessage / aiGenerationIsSelection`。
- 菜单支持：
  - Prompt 输入框
  - Tone 选择
  - 结果动作 Accept / Reject / Stop
- 锚点策略：支持基于选区或节点锚定 AI 浮层，流式生成期间动态追踪位置。

---

## 6. 协作能力集合

- Yjs 文档协同（`TiptapCollabProvider`）。
- 协作者光标与身份色（`CollaborationCaret`）。
- 协作用户头像组与列表展示。
- 用户身份本地持久化：用户名、颜色、ID 写入 `localStorage`。
- token 获取失败时自动降级到本地模式。

---

## 7. 表格能力全集

### 7.1 插入与基础结构

- 表格插入：网格选择器（默认 8x8，动态选择行列）。
- 自定义 Table NodeView：
  - `table-container`
  - 控件层 `table-controls`
  - 选择覆盖层 `table-selection-overlay-container`
- 列宽可调整（column resizing）。

### 7.2 行/列/单元格操作

- 行列新增：上/下/左/右插入。
- 行列删除。
- 行列复制。
- 行列移动（上/下/左/右）。
- 行列排序（升序/降序）：
  - 表头保持原位置
  - 空值统一置底
  - 合并单元格场景有保护逻辑
- 行列内容清空（可重置属性）。
- 表头行/列表头切换。

### 7.3 单元格增强

- 单元格合并 / 拆分。
- 文本对齐（左中右）与垂直对齐（上中下）。
- 节点背景色（作为单元格背景色能力）。

### 7.4 表格操作交互层

- 行列 Handle 悬浮显示。
- 行列 Handle 菜单（按行/列上下文动态渲染可用动作）。
- 行列拖拽重排（`moveTableRow/moveTableColumn`）。
- 拖拽过程有 dropcursor 视觉反馈与拖影。
- 末尾扩展按钮：
  - 点击快速新增行/列
  - 拖动连续增减行/列
  - 删除时仅允许移除尾部空行/空列（安全策略）
- 选区覆盖层：
  - CellSelection 可视化
  - 四角 resize handle
  - resize 中通过 rAF 同步 overlay 位置
- 表格适配：`Fit to width` 自动重算列宽。

### 7.5 表格快捷与细节

- 表格单元格内 `Mod+a` 优化为优先选中当前单元格内容。
- 句柄菜单打开时支持冻结/解冻句柄，避免交互冲突。

---

## 8. 图片能力全集

### 8.1 图片上传节点（ImageUploadNode）

- 可插入上传占位节点。
- 支持点击选择与拖拽上传。
- 上传参数控制：`accept`、`limit`、`maxSize`。
- 支持并发上传、进度展示、失败处理。
- 支持单文件取消、批量清空。
- 上传成功后自动将 upload 节点替换为 image 节点（可一次插入多图）。

### 8.2 图片节点（Image）

- 属性：`src / alt / title / width / height / data-align / showCaption`。
- 支持 figure + figcaption 渲染与解析。
- 支持显示/编辑 caption。
- 支持左右拖拽调整宽度。
- 支持对齐（left/center/right）。
- 保留 NodeSelection 体验（在部分操作后恢复图片节点选中状态）。

### 8.3 图片相关动作

- 插入图片上传节点。
- 开启图片 caption。
- 图片对齐切换。
- 图片下载：
  - 同源直接下载
  - 跨域尝试 fetch 下载
  - 失败回退新标签页打开
  - URL 安全清洗

---

## 9. 目录（TOC）能力全集

- `TableOfContents` 扩展监听标题变化并同步目录数据。
- `TocNode` 可插入文内目录块，支持属性：
  - `topOffset`
  - `maxShowCount`
  - `showTitle`
- `TocSidebar` 侧边目录：
  - 活跃标题高亮
  - 点击滚动定位
  - 首屏 hash 恢复
  - 手动点击激活态与滚动激活态协调
- 支持复制锚点链接（依赖 `UniqueID`），并可从 hash 回滚定位节点。

---

## 10. 菜单与交互入口

### 10.1 Slash 菜单（`/`）

- 分组：AI / Style / Insert / Upload。
- 内置项：
  - AI：Continue Writing、Ask AI
  - Style：Text、H1/H2/H3、Bullet/Numbered/To-do、Blockquote、Code Block
  - Insert：Mention、Emoji、Table、Separator、TOC
  - Upload：Image

### 10.2 Mention / Emoji 建议菜单

- `@` 触发 mention 列表并插入 mention 节点。
- `:` 触发表情建议并插入 emoji。
- 提供独立触发按钮与快捷键。

### 10.3 工具栏与上下文菜单

- 顶部栏：Undo/Redo、主题切换、协作者展示。
- 浮动工具栏：Improve、Turn Into、Mark、链接、颜色、图片操作、文本对齐、缩进。
- 拖拽上下文菜单：
  - Turn Into
  - 颜色/对齐
  - 表格操作入口
  - 复制/复制链接/复制到剪贴板/删除
  - AI Ask
- 表格 Handle 菜单与 Cell 菜单（详见表格章节）。
- 移动端工具栏已实现，但当前产品定位为 PC，默认不会在 PC 宽度下出现。

### 10.4 新增下拉菜单组件（本轮新增）

- `HeadingDropdownMenu`：
  - 由 `useHeadingDropdownMenu` 提供状态（`isVisible`、`activeLevel`、`canToggle`、`Icon`）。
  - 支持 `levels` 配置（默认 1~6）与 `hideWhenUnavailable`。
  - 触发图标按当前激活标题等级动态变化，未激活时回退 `HeadingIcon`。
- `ListDropdownMenu`：
  - 由 `useListDropdownMenu` 提供状态（`isVisible`、`activeType`、`canToggleAny`、`filteredLists`、`Icon`）。
  - 支持 `types` 配置（默认 bullet/ordered/task）与 `hideWhenUnavailable`。
  - 基于 schema 能力与当前可执行性动态显示/禁用。
- 两者都已接入 `SimpleEditor` 工具栏：
  - 标题等级入口：`Heading 1~4`
  - 列表入口：`Bullet / Ordered / Task`

---

## 11. 快捷键矩阵（核心）

- 通用编辑：
  - Undo：`mod+z`
  - Redo：`mod+shift+z`
  - Reset formatting：`mod+r`
  - Copy to clipboard（编辑器自定义）：`mod+c`
  - Duplicate node：`mod+d`
  - Delete node：`backspace`
  - Move node up/down：`mod+shift+ArrowUp` / `mod+shift+ArrowDown`
- 结构触发：
  - Slash trigger：`mod+/`
  - Mention trigger：`mod+shift+2`
  - Emoji trigger：`mod+shift+e`
- 文本样式：
  - Bold / Italic / Underline / Strike / Code：`mod+b / mod+i / mod+u / mod+shift+s / mod+e`
  - Superscript / Subscript：`mod+. / mod+,`
- 段落与块：
  - Text：`mod+alt+0`
  - Heading 1~6：`ctrl+alt+1..6`
  - Code block：`mod+alt+c`
  - Blockquote：`mod+shift+b`
  - Bullet / Ordered / Task list：`mod+shift+8 / mod+shift+7 / mod+shift+9`
- 对齐与缩进：
  - Text align left/center/right/justify：`mod+shift+l/e/r/j`
  - Indent / Outdent：`Tab / Shift+Tab`
  - Image align left/center/right：`alt+shift+l/e/r`
- 颜色与媒体：
  - Text color：`mod+shift+t`
  - Highlight：`mod+shift+h`
  - Image upload：`mod+shift+i`
  - Image download：`mod+shift+d`
- AI：
  - Ask AI：`mod+j`

---

## 12. 状态、健壮性与边界处理

- 覆盖关键状态：
  - loading：初始化、协作/AI token 等待
  - success：正常进入编辑
  - disabled：大量动作基于 `can*` 精确禁用
  - error：上传失败、token 拉取失败、URL 非法等
- URL 安全：链接与图片下载统一走 `sanitizeUrl`。
- 锚点能力：依赖 `UniqueID` 统一生成/解析 anchor id。
- 浮动工具栏防误触：通过 `hideFloatingToolbar` transaction meta 做显隐控制。

---

## 13. 预留/半接入能力说明

- `AppContext` 内存在 `threadBubbles` 相关结构，体现评论/线程 UI 预留能力。
- `UiState` 中有 `commentInputVisible` 状态，但当前模板未看到完整评论输入面板闭环。

---

## 14. 一句话结论

`tiptap-editor` 当前形成“双模板能力层”：`Notion-like` 负责协作 + AI + 表格 + TOC 的完整富文本体验，`Simple` 负责低门槛、轻依赖的本地编辑体验；二者共享大量 UI 原子能力，并通过可见性/可执行性判定保障交互一致性。

---

## 15. 本轮新增代码补充说明（增量）

### 15.1 新增模板：`SimpleEditor`

- 新增路径：`components/tiptap-templates/simple/*`。
- 工具栏能力：
  - Undo/Redo
  - Heading 下拉（1~4）
  - List 下拉（Bullet/Ordered/Task）
  - Blockquote、Code Block
  - Bold/Italic/Strike/Code/Underline
  - Highlighter、Link（移动端切换二级面板）
  - Superscript/Subscript
  - Text Align（left/center/right/justify）
  - Image Upload
  - Theme Toggle（浅色/深色）
- 移动端交互：
  - `mobileView: main | highlighter | link`
  - 结合 `useCursorVisibility` 动态抬升工具栏，规避软键盘遮挡。
- 初始内容：`data/content.json` 提供完整示例文档（标题、链接、代码块、引用、图片、任务列表等）。

### 15.2 新增图标与样式

- 新增图标：`HeadingIcon`，用于标题下拉触发器默认图标。
- 新增样式：`simple-editor.scss`，包含字体、滚动条、布局与主题变量切换（`.dark` 类）。

### 15.3 能力边界（Simple vs Notion-like）

- `SimpleEditor` 当前不接入：
  - AI 生成与改写能力
  - 协作（Yjs/caret/用户列表）
  - TOC 侧栏与 TocNode
  - 表格与对应 handle/overlay 体系
  - Mention / Emoji / Slash 命令体系
- 适用场景：
  - 需要快速集成、低复杂度富文本能力的页面
  - 对协作/AI/复杂结构化编辑暂时无要求的业务模块
