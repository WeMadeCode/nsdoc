import { SimpleEditor } from '@/tiptap-editor/components/tiptap-templates/simple/simple-editor'

const App = () => {
  console.log('App did start')

  return (
    <div style={{ width: '100%', height: '100vh' }}>
      <SimpleEditor />
    </div>
  )
}

export default App
