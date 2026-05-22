# Web 端自定义插件开发规范

## Tiptap 扩展目录

Web 端自定义 Tiptap 扩展统一放在 `web/src/tiptap-editor/extensions` 下。

每个自定义节点或扩展使用独立目录，例如：

```text
web/src/tiptap-editor/extensions/extension-title/
  index.ts
  plugin/
    index.ts
  title-wrpper/
    index.tsx
    index.module.scss
```

## 插件归属

归属于某个自定义节点的 ProseMirror/Tiptap 插件，必须放在该节点扩展目录下的 `plugin/` 文件夹中。

例如，属于 `title` 节点的键盘、粘贴、输入法、DOM event 等插件逻辑，应放在：

```text
web/src/tiptap-editor/extensions/extension-title/plugin/
```

`extension-title/index.ts` 只负责声明节点 schema、HTML 解析渲染、NodeView 注册，并从 `./plugin` 引入插件：

```ts
addProseMirrorPlugins() {
  return [createTitlePlugin(this.name)]
}
```

不要把归属于具体节点的大段插件逻辑直接写在 `index.ts` 中。

## 内容约束

节点是否允许某类子节点，优先通过 schema 的 `content` 表达式约束。

例如 `title` 不允许 `hardBreak`，应使用：

```ts
content: 'text*'
```

不要使用过宽的 `inline*`，除非该节点确实允许所有 inline 节点。
