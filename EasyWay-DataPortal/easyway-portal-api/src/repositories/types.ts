export interface UserRecord {
  user_id: string;
  tenant_id: string;
  email: string;
  display_name?: string | null;
  profile_id?: string | null;
  is_active?: boolean;
  updated_at?: string;
}

export interface UsersRepo {
  list(tenantId: string): Promise<UserRecord[]>;
  create(tenantId: string, data: { email: string; display_name?: string | null; profile_id?: string | null }): Promise<UserRecord | any>;
  update(
    tenantId: string,
    user_id: string,
    data: {
      email?: string | null,
      display_name?: string | null,
      profile_id?: string | null,
      is_active?: boolean | null,
      updated_by?: string | null
    }
  ): Promise<UserRecord | any>;
  softDelete(tenantId: string, user_id: string): Promise<void>;
}

export interface OnboardingInput {
  tenant_name: string;
  user_email: string;
  display_name?: string | null;
  profile_id?: string | null;
  ext_attributes?: any;
}

export interface OnboardingRepo {
  registerTenantAndUser(tenantId: string, input: OnboardingInput): Promise<any>;
}

export interface NotificationInput {
  user_id: string;
  category: string;
  channel: string;
  message: string;
  ext_attributes?: Record<string, any>;
}

export interface NotificationsRepo {
  send(tenantId: string, input: NotificationInput): Promise<void>;
}

export interface AgentChatMessageRecord {
  event_time: string;
  role: 'user' | 'agent' | 'system';
  content: string;
  payload_json?: string | null;
}

export interface AgentChatConversationRecord {
  conversationId: string;
  lastEventTime: string;
  lastMessage?: string | null;
}

export interface AgentChatRepo {
  logMessage(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
    role: 'user' | 'agent' | 'system';
    content: string;
    metadata?: any;
  }): Promise<void>;

  listConversations(tenantId: string, input: {
    actor: string;
    agentId: string;
    limit: number;
    offset: number;
  }): Promise<{ conversations: AgentChatConversationRecord[]; total: number }>;

  getConversation(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
  }): Promise<{ deleted: boolean; messages: AgentChatMessageRecord[] }>;

  deleteConversation(tenantId: string, input: {
    actor: string;
    agentId: string;
    conversationId: string;
  }): Promise<void>;
}
