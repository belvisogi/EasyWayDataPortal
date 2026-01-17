export type ExecutionMode = 'plan' | 'apply';

export interface AgentChatContext {
  executionMode?: ExecutionMode;
  approved?: boolean;
  approvalId?: string;
  [key: string]: unknown;
}

export interface AgentChatRequest {
  agentId: string;
  message: string;
  conversationId?: string | null;
  context?: AgentChatContext;
}

export interface AgentChatResponse {
  conversationId: string;
  message: string;
  suggestions?: Array<{
    label: string;
    action: string;
    params?: Record<string, unknown>;
  }>;
  attachments?: Array<unknown>;
  timestamp?: string;
  metadata?: Record<string, unknown>;
}

export interface AgentChatError extends Error {
  status?: number;
  code?: string;
  payload?: Record<string, unknown>;
}

async function parseJsonSafe(response: Response): Promise<Record<string, unknown>> {
  try {
    return await response.json();
  } catch {
    return {};
  }
}

export async function sendAgentChatMessage({
  agentId,
  message,
  conversationId = null,
  context = {}
}: AgentChatRequest): Promise<AgentChatResponse> {
  const response = await fetch(`/api/agents/${encodeURIComponent(agentId)}/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message,
      conversationId,
      context
    })
  });

  if (!response.ok) {
    const payload = await parseJsonSafe(response);
    const err: AgentChatError = new Error((payload.message as string) || 'Agent chat error');
    err.status = response.status;
    err.payload = payload;

    if (response.status === 428 || payload.error === 'approval_required') {
      err.code = 'APPROVAL_REQUIRED';
      err.message = 'Approval required before apply execution';
      throw err;
    }

    if (response.status === 422 || payload.error === 'approval_invalid') {
      err.code = 'APPROVAL_INVALID';
      err.message = 'Approval ticket invalid';
      throw err;
    }

    if (payload.error === 'intent_not_allowed') {
      err.code = 'INTENT_NOT_ALLOWED';
    }

    if (payload.error === 'output_blocked') {
      err.code = 'OUTPUT_BLOCKED';
    }

    throw err;
  }

  return response.json();
}
