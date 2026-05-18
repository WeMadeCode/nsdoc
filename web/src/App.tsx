import { NotionEditor } from '@/tiptap-editor/components/tiptap-templates/notion-like/notion-like-editor'

const App = () => {
  return (
    <div style={{ width: '100%', height: '100vh' }}>
      <NotionEditor room={`detail-edit-123`} placeholder="开始编辑内容..." />
    </div>
  )
}

export default App
