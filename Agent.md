# Agent 项目指南

本文件用于帮助 AI Agent 在本仓库中安全、准确地完成开发任务。执行修改前先理解受影响的 iOS、Web 和 JS Bridge 边界；优先做小而完整的改动，不顺手重构无关代码。

## 项目概览

“一页”是一个本地优先、隐私优先的个人笔记应用。原生层负责应用外壳、数据和系统能力，Web 层专注富文本编辑。

- 原生应用：SwiftUI + SwiftData，支持 iPhone 和 macOS。
- 数据同步：SwiftData 使用私有 CloudKit 容器；macOS 缺少 CloudKit entitlement 时会降级为本地存储。
- 编辑器：React 19 + TypeScript + Tiptap 3 + Vite 7。
- 跨端通信：基于 `WKScriptMessageHandler` 与 `evaluateJavaScript` 的自研 JS Bridge。
- Web 资源：生产构建会复制到 `iOS/note/doc.bundle`，由 App 内置加载。

当前部署目标：iOS 18.2、macOS 14.0，Swift 5.0。Web 包管理器固定为 pnpm 10.13.1。

## 跨平台与复用原则

- 所有功能默认同时考虑移动端（iPhone）与 PC 端（macOS）；需求未明确限定平台时，不得只实现或只验证其中一端。
- 优先复用业务模型、服务、ViewModel、Bridge 协议、编辑器 extension 和无平台差异的 SwiftUI View，避免维护两套等价逻辑。
- 平台分支只用于确实不同的系统能力或交互，例如 UIKit/AppKit、键盘、窗口、导航、照片选择和文件导入。
- 使用 `#if os(iOS)` / `#if os(macOS)` 时，将分支限制在最小边界；公共状态与业务流程应提取到分支外。
- PC 与移动端可以采用不同布局和交互，但必须共享同一数据语义、保存流程、Bridge 方法和内容格式。
- Web 编辑器优先采用响应式布局、共享组件与能力检测，不通过复制页面分别维护 mobile/desktop 版本。
- 抽取复用代码时保持职责清晰；不要为了“复用”制造包含大量平台判断的万能组件。

## 目录职责

```text
iOS/note/
  account/       CloudKit 账号状态与提示
  bridge/        Native Bridge 协议、权限、消息和处理器
  container/     WKWebView 宿主与内置资源加载
  data/          SwiftData 模型、CloudKit 配置、附件服务
  editor/        原生编辑页、工具栏和状态
  list/          笔记列表、搜索及首页组件
  main/          iOS/macOS 应用主界面
  doc.bundle/    Web 构建产物，不应手工编辑
web/src/
  bridge/        Web Bridge SDK、类型和编辑器处理器
  tiptap-editor/ Tiptap 扩展、模板、节点、控件和样式
docs/            产品、架构、数据模型和 Bridge 设计文档
script/          Web 资源同步脚本
```

关键入口：

- `iOS/note/NoteApp.swift`：SwiftData/CloudKit 容器及平台入口。
- `iOS/note/editor/EditorView.swift`：原生编辑器生命周期、保存、附件和工具栏。
- `iOS/note/container/SLWebView.swift`：WebView 配置、运行时模式和 Bridge 接入。
- `web/src/App.tsx`：根据原生运行时配置选择 simple/notion 编辑器。
- `web/src/bridge/types.ts`：Web 侧 Bridge 公共类型。
- `docs/js-bridge-design.md`：跨端协议设计依据。

## 架构边界

- iOS 管理导航、SwiftData、CloudKit、附件文件、照片选择和平台 UI；不要把这些职责下沉到 Web。
- Web 管理 Tiptap 文档、编辑命令、选区/工具状态和内容快照；不要从 Web 直接访问原生数据存储。
- 两端只能通过公开的 Bridge namespace/method 通信，不要直接操作对方内部对象。
- Bridge 消息必须保持 JSON 可序列化、参数对象化、错误可识别，并考虑未 ready、超时和页面重载。
- 修改 Bridge 方法或 payload 时，同步检查 Web 类型/handler、Native message/handler、调用点和 `docs/js-bridge-design.md`。
- 笔记正文的权威格式是 Tiptap JSON，不要引入 Markdown 双写。
- SwiftData 当前核心模型是 `Folder`、`Document`、`DocumentContent`、`Attachment`；模型变更必须考虑现有持久化数据和 CloudKit 兼容性。

## 本地开发

Web 开发：

```bash
cd web
pnpm install
pnpm dev
```

Debug 下，macOS 和 iOS 模拟器会从 `http://127.0.0.1:5173/` 加载编辑器，因此联调前应启动 Vite。真机及 Release 使用内置 `doc.bundle`。

Web 校验与打包：

```bash
cd web
pnpm lint
pnpm build
```

`pnpm build` 会先执行 TypeScript 构建和 Vite 打包，然后通过 `script/sync-doc-bundle.sh` 用 `web/dist` 完整替换 `iOS/note/doc.bundle`。因此构建后应检查并提交必要的 bundle 变更，不能只提交 Web 源码。

原生构建示例：

```bash
xcodebuild -project iOS/note.xcodeproj -scheme note -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project iOS/note.xcodeproj -scheme note -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

若本机缺少对应 Simulator Runtime、签名或 CloudKit entitlement，应明确报告环境限制，不要以此掩盖源码编译错误。

## 编码约定

### Swift

- 延续 SwiftUI + SwiftData 的现有模式；平台差异使用 `#if os(iOS)` / `#if os(macOS)` 明确隔离。
- 新功能先识别可共享的 model、service、view model 和 view，再为 iPhone/macOS 添加薄的平台适配层。
- UI 状态更新和 Bridge 回调注意主线程；异步任务避免产生悬空回调或重复保存。
- 业务逻辑优先放到 service、model 或 view model，不继续膨胀大型 View。
- 新增用户可见控件时补充可访问性标签，并同时检查 iPhone 与 macOS 行为。
- 不硬编码新的 CloudKit 容器标识、签名信息或用户本机路径。

### TypeScript / React

- 保持 TypeScript strict，通过 `@/*` 引用 `web/src/*`。
- 遵循现有 Prettier：单引号、无分号、2 空格、140 列；import 由 `simple-import-sort` 管理。
- 复用已有 Tiptap extension、hook 和 UI primitive，避免复制近似组件。
- 组件应同时适配移动端窄视口和 PC 端宽视口，并正确处理鼠标、触控、键盘与 hover/focus 差异。
- React effect 必须清理 Bridge 注册、监听器和定时器；避免在渲染过程中执行编辑器副作用。
- 不直接修改 `web/dist` 或 `iOS/note/doc.bundle` 中的压缩文件。

## 修改与验证原则

1. 修改前阅读调用链，不只改报错所在文件。
2. 保留用户已有的未提交改动，不执行破坏性 Git 操作。
3. Web 改动至少运行 `pnpm lint`；涉及类型、资源或编辑器运行时的改动再运行 `pnpm build`。
4. Swift 改动至少构建受影响平台；公共数据层或 Bridge 改动应尽量构建 iOS 和 macOS 两端。
5. UI 或交互改动应分别检查 iPhone 窄屏/触控/软键盘，以及 macOS 窗口缩放/鼠标/实体键盘场景。
6. 跨端功能应验证 ready、打开文档、内容变化/保存、选区状态以及错误路径。
7. 数据模型、协议或用户行为变化时更新 `docs/` 中对应文档。
8. 仓库目前没有独立自动化测试套件；不要声称“测试通过”，应准确列出执行过的 lint、build 和手动验证。

## 高风险区域

- SwiftData/CloudKit schema：随意改名、删除字段或改变默认值可能导致现有数据不可读或同步失败。
- 自动保存：需防止旧快照覆盖新内容、退出前未 flush、空文档误创建。
- Bridge 生命周期：导航重载后要重置状态，handler 注册/回调必须避免重复和泄漏。
- 附件：正文只保存稳定 attachment ID；文件解析、清理和图片选择失败都要有可恢复错误。
- 内置 Web 资源：`base` 必须保持相对路径，以便自定义 URL scheme/本地 bundle 正确加载。

## 完成标准

交付说明应包含：修改内容、复用了哪些已有能力、iPhone/macOS 的适配情况、涉及的平台或边界、实际运行的验证命令、任何未验证项或环境限制。只有双端行为、源码、生成资源和相关文档保持一致，任务才算完成。
