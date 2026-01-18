import { AgentChatRepo, AgentChatConversationRecord, AgentChatMessageRecord } from "../types";

type StoredMessage = {
  tenantId: string;
  actor: string;
  agentId: string;
  conversationId: string;
  event_time: string;
  role: "user" | "agent" | "system";
  content: string;
  payload_json?: string | null;
};

export class MockAgentChatRepo implements AgentChatRepo {
  private messages: StoredMessage[] = [];
  private deleted: Set<string> = new Set(); // key tenant|actor|agent|conversation

  async logMessage(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
    role: "user" | "agent" | "system";
    content: string;
    metadata?: any;
  }): Promise<void> {
    const payload_json = JSON.stringify({
      conversationId: input.conversationId,
      agentId: input.agentId,
      role: input.role,
      content: input.content,
      metadata: input.metadata ?? null
    });

    this.messages.push({
      tenantId,
      actor: input.actor,
      agentId: input.agentId,
      conversationId: input.conversationId,
      event_time: new Date().toISOString(),
      role: input.role,
      content: input.content,
      payload_json
    });
  }

  async listConversations(tenantId: string, input: {
    actor: string;
    agentId: string;
    limit: number;
    offset: number;
  }): Promise<{ conversations: AgentChatConversationRecord[]; total: number }> {
    const all = this.messages
      .filter((m) => m.tenantId === tenantId && m.actor === input.actor && m.agentId === input.agentId)
      .reduce((acc, m) => {
        const key = `${tenantId}|${input.actor}|${input.agentId}|${m.conversationId}`;
        if (this.deleted.has(key)) return acc;
        const prev = acc.get(m.conversationId);
        if (!prev || prev.lastEventTime < m.event_time) {
          acc.set(m.conversationId, {
            conversationId: m.conversationId,
            lastEventTime: m.event_time,
            lastMessage: m.content
          });
        }
        return acc;
      }, new Map<string, AgentChatConversationRecord>());

    const list = Array.from(all.values()).sort((a, b) => (a.lastEventTime < b.lastEventTime ? 1 : -1));
    const total = list.length;
    const page = list.slice(input.offset, input.offset + input.limit);
    return { conversations: page, total };
  }

  async getConversation(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
  }): Promise<{ deleted: boolean; messages: AgentChatMessageRecord[] }> {
    const key = `${tenantId}|${input.actor}|${input.agentId}|${input.conversationId}`;
    if (this.deleted.has(key)) return { deleted: true, messages: [] };

    const rows = this.messages
      .filter((m) => m.tenantId === tenantId && m.actor === input.actor && m.agentId === input.agentId && m.conversationId === input.conversationId)
      .sort((a, b) => (a.event_time > b.event_time ? 1 : -1));

    return {
      deleted: false,
      messages: rows.map((m) => ({
        event_time: m.event_time,
        role: m.role,
        content: m.content,
        payload_json: m.payload_json ?? null
      }))
    };
  }

  async deleteConversation(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
  }): Promise<void> {
    const key = `${tenantId}|${input.actor}|${input.agentId}|${input.conversationId}`;
    if (!this.messages.some((m) => m.tenantId === tenantId && m.actor === input.actor && m.agentId === input.agentId && m.conversationId === input.conversationId)) {
      const err: any = new Error("Not found");
      err.code = "NOT_FOUND";
      throw err;
    }
    this.deleted.add(key);
  }
}

