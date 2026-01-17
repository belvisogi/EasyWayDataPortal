import './App.css'
import { Navigate, Route, Routes } from 'react-router-dom'
import AgentChatPage from './pages/AgentChatPage'

function App() {
  return (
    <Routes>
      <Route path="/agent-chat" element={<AgentChatPage />} />
      <Route path="*" element={<Navigate to="/agent-chat" replace />} />
    </Routes>
  )
}

export default App
