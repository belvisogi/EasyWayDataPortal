import sql from "mssql";
import { withTenantContext } from "../../utils/db";
import { AgentChatRepo, AgentChatConversationRecord, AgentChatMessageRecord } from "../types";

export class SqlAgentChatRepo implements AgentChatRepo {
  async logMessage(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
    role: "user" | "agent" | "system";
    content: string;
    metadata?: any;
  }): Promise<void> {
    await withTenantContext(tenantId, async (tx) => {
      await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("actor", sql.NVarChar, input.actor)
        .input("agent_id", sql.NVarChar, input.agentId)
        .input("conversation_id", sql.NVarChar, input.conversationId)
        .input("role", sql.NVarChar, input.role)
        .input("content", sql.NVarChar, input.content)
        .input("metadata_json", sql.NVarChar, input.metadata ? JSON.stringify(input.metadata) : null)
        .execute("PORTAL.sp_agent_chat_log_message");
    });
  }

  async listConversations(tenantId: string, input: {
    actor: string;
    agentId: string;
    limit: number;
    offset: number;
  }): Promise<{ conversations: AgentChatConversationRecord[]; total: number }> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("actor", sql.NVarChar, input.actor)
        .input("agent_id", sql.NVarChar, input.agentId)
        .input("limit", sql.Int, input.limit)
        .input("offset", sql.Int, input.offset)
        .execute("PORTAL.sp_agent_chat_list_conversations");
    });

    const res = result as any;
    const conversations = (res.recordsets?.[0] || res.recordset || []) as any[];
    const totalRow = (res.recordsets?.[1]?.[0] || null) as any;

    return {
      conversations: conversations.map((r) => ({
        conversationId: r.conversationId,
        lastEventTime: r.lastEventTime,
        lastMessage: r.lastMessage ?? null
      })),
      total: totalRow?.total ?? 0
    };
  }

  async getConversation(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
  }): Promise<{ deleted: boolean; messages: AgentChatMessageRecord[] }> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("actor", sql.NVarChar, input.actor)
        .input("agent_id", sql.NVarChar, input.agentId)
        .input("conversation_id", sql.NVarChar, input.conversationId)
        .execute("PORTAL.sp_agent_chat_get_conversation");
    });

    const res = result as any;
    const deletedRow = (res.recordsets?.[0]?.[0] || null) as any;
    if (deletedRow && (deletedRow.deleted === true || deletedRow.deleted === 1)) {
      return { deleted: true, messages: [] };
    }

    const rows = (result.recordset || []) as any[];
    return {
      deleted: false,
      messages: rows.map((r) => ({
        event_time: r.event_time,
        role: r.role,
        content: r.content,
        payload_json: r.payload_json ?? null
      }))
    };
  }

  async deleteConversation(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
  }): Promise<void> {
    await withTenantContext(tenantId, async (tx) => {
      await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("actor", sql.NVarChar, input.actor)
        .input("agent_id", sql.NVarChar, input.agentId)
        .input("conversation_id", sql.NVarChar, input.conversationId)
        .execute("PORTAL.sp_agent_chat_delete_conversation");
    });
  }
}

