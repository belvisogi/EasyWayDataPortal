import { FormEvent, useCallback, useMemo, useState } from 'react'
import { sendAgentChatMessage, AgentChatError, ExecutionMode } from '../api/agentChat'
import { useUserFriendlyError } from '../legacy_components/hooks/useUserFriendlyError'

export default function AgentChatPage() {
  const [agentId, setAgentId] = useState('agent_governance')
  const [message, setMessage] = useState('')
  const [executionMode, setExecutionMode] = useState<ExecutionMode>('plan')
  const [approved, setApproved] = useState(false)
  const [approvalId, setApprovalId] = useState('')
  const [approvalError, setApprovalError] = useState<string | null>(null)
  const [response, setResponse] = useState<string | null>(null)
  const [pendingApproval, setPendingApproval] = useState(false)
  const [lastPayload, setLastPayload] = useState<{ agentId: string; message: string } | null>(null)
  const { error, handleError, clearError, hasError } = useUserFriendlyError()

  const canSubmit = useMemo(() => message.trim().length > 0, [message])
  const canApprove = useMemo(() => approvalId.trim().length > 0, [approvalId])

  const submit = useCallback(async (payload: { agentId: string; message: string }, overrideApproved?: boolean) => {
    const ctxApproved = overrideApproved ?? approved
    const ctxApprovalId = ctxApproved ? approvalId.trim() : undefined

    try {
      clearError()
      setApprovalError(null)
      setPendingApproval(false)
      const res = await sendAgentChatMessage({
        agentId: payload.agentId,
        message: payload.message,
        context: {
          executionMode,
          approved: ctxApproved,
          approvalId: ctxApprovalId || undefined
        }
      })
      setResponse(res.message)
    } catch (err) {
      handleError(err as AgentChatError)
      if ((err as AgentChatError).code === 'APPROVAL_REQUIRED') {
        setPendingApproval(true)
      }
    }
  }, [approvalId, approved, clearError, executionMode, handleError])

  const onSubmit = useCallback((event: FormEvent) => {
    event.preventDefault()
    if (!canSubmit) return
    const payload = { agentId, message }
    setLastPayload(payload)
    submit(payload)
  }, [agentId, canSubmit, message, submit])

  const requestApproval = useCallback(() => {
    if (!lastPayload) return
    if (!canApprove) {
      setApprovalError('Inserisci un ticket di approvazione valido.')
      return
    }
    setApproved(true)
    submit(lastPayload, true)
  }, [canApprove, lastPayload, submit])

  return (
    <div className="app">
      <header className="app__header">
        <h1>Agent Chat</h1>
        <p>Routing demo con approval gate e ticket di approvazione.</p>
      </header>

      <main className="app__main">
        <form className="chat" onSubmit={onSubmit}>
          <label className="field">
            <span>Agent ID</span>
            <input value={agentId} onChange={(e) => setAgentId(e.target.value)} />
          </label>

          <label className="field">
            <span>Message</span>
            <textarea
              rows={4}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="intent: predeploy-checklist"
            />
          </label>

          <div className="row">
            <label className="field">
              <span>Execution mode</span>
              <select value={executionMode} onChange={(e) => setExecutionMode(e.target.value as ExecutionMode)}>
                <option value="plan">plan</option>
                <option value="apply">apply</option>
              </select>
            </label>

            <label className="field field--inline">
              <input
                type="checkbox"
                checked={approved}
                onChange={(e) => setApproved(e.target.checked)}
              />
              <span>Approved</span>
            </label>

            <label className="field">
              <span>Approval Ticket</span>
              <input
                value={approvalId}
                onChange={(e) => setApprovalId(e.target.value)}
                placeholder="CAB-2026-0001"
              />
            </label>
          </div>

          <div className="row row--actions">
            <button type="submit" disabled={!canSubmit}>Send</button>
          </div>
        </form>

        {pendingApproval && (
          <section className="panel panel--warn">
            <h2>Approvazione necessaria</h2>
            <p>Questa richiesta richiede un ticket di approvazione per procedere in modalita apply.</p>
            <div className="row row--actions">
              <label className="field">
                <span>Ticket approvazione</span>
                <input
                  value={approvalId}
                  onChange={(e) => setApprovalId(e.target.value)}
                  placeholder="CAB-2026-0001"
                />
              </label>
              <button type="button" className="secondary" onClick={requestApproval} disabled={!canApprove}>
                Conferma approvazione
              </button>
            </div>
            {approvalError && <p className="hint">{approvalError}</p>}
          </section>
        )}

        <section className="panel">
          <h2>Response</h2>
          {response ? <pre>{response}</pre> : <p>Nessuna risposta.</p>}
        </section>

        {hasError && error && (
          <section className="panel panel--warn">
            <h2>{error.title}</h2>
            <p>{error.message}</p>
            {error.action?.handler === 'requestApproval' && (
              <button type="button" className="secondary" onClick={requestApproval}>
                Richiedi approvazione
              </button>
            )}
          </section>
        )}
      </main>
    </div>
  )
}
