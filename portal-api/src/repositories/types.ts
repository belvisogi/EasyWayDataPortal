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

export interface AppointmentRecord {
  appointment_id: string;
  tenant_id: string;
  customer_name: string;
  customer_email: string;
  scheduled_at: string;
  status: 'CONFIRMED' | 'PENDING' | 'CANCELLED';
  notes?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface AppointmentsRepo {
  list(tenantId: string): Promise<AppointmentRecord[]>;
  create(tenantId: string, data: {
    customer_name: string;
    customer_email: string;
    scheduled_at: string;
    notes?: string | null;
  }): Promise<AppointmentRecord>;
  update(tenantId: string, appointment_id: string, data: {
    status?: 'CONFIRMED' | 'PENDING' | 'CANCELLED';
    notes?: string | null;
    scheduled_at?: string;
  }): Promise<AppointmentRecord>;
  cancel(tenantId: string, appointment_id: string): Promise<void>;
}

export interface QuoteRecord {
  quote_id: string;
  tenant_id: string;
  customer_name: string;
  customer_email: string;
  total_amount: number;
  status: 'DRAFT' | 'SENT' | 'ACCEPTED' | 'REJECTED';
  valid_until?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface QuotesRepo {
  list(tenantId: string): Promise<QuoteRecord[]>;
  create(tenantId: string, data: {
    customer_name: string;
    customer_email: string;
    total_amount: number;
    valid_until?: string | null;
  }): Promise<QuoteRecord>;
  update(tenantId: string, quote_id: string, data: {
    status?: 'DRAFT' | 'SENT' | 'ACCEPTED' | 'REJECTED';
    total_amount?: number;
    valid_until?: string | null;
  }): Promise<QuoteRecord>;
}

export interface AgentRecord {
  agent_id: string;
  name: string;
  level: string;
  description?: string | null;
  status: string;
  last_run?: string | null;
}

export interface AgentsRepo {
  list(): Promise<AgentRecord[]>;
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
