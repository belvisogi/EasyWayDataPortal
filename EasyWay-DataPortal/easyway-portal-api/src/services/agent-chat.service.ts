import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';
import * as path from 'path';

export interface AgentInfo {
    id: string;
    name: string;
    status: 'online' | 'offline' | 'busy';
    avatar?: string;
    capabilities: string[];
    description: string;
    greeting?: string;
    primaryIntents?: string[];
    knowledgeSources?: string[];
}

export interface SendMessageParams {
    agentId: string;
    message: string;
    conversationId: string | null;
    context: any;
    userId: string;
}

export interface ChatResponse {
    conversationId: string;
    message: string;
    suggestions?: Array<{
        label: string;
        action: string;
        params?: any;
    }>;
    attachments?: any[];
    timestamp: string;
    metadata?: any;
}

export interface ConversationListResponse {
    conversations: any[];
    total: number;
    hasMore: boolean;
}

/**
 * Agent Chat Service
 * Handles agent interaction via chat interface
 */
export class AgentChatService {

    private agentsBasePath = path.resolve(__dirname, '../../../agents');

    /**
     * List all available agents from agents/ * /manifest.json
     */
    async listAgents(): Promise<AgentInfo[]> {
        const agents: AgentInfo[] = [];
        try {
            const agentDirs = await fs.readdir(this.agentsBasePath, { withFileTypes: true });

            for (const dir of agentDirs) {
                if (!dir.isDirectory() || dir.name.startsWith('.')) continue;

                const manifestPath = path.join(this.agentsBasePath, dir.name, 'manifest.json');

                try {
                    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
                    const manifest = JSON.parse(manifestContent);

                    agents.push({
                        id: dir.name,
                        name: manifest.name || dir.name,
                        status: 'online', // TODO: Check actual status
                        capabilities: manifest.domains || [],
                        description: manifest.description || '',
                        avatar: `/avatars/${dir.name}.png`
                    });
                } catch (error: any) {
                    console.warn(`Skipping agent ${dir.name}: ${error.message}`);
                }
            }
        } catch (err) {
            console.warn("Could not list agents directory", err);
        }

        return agents;
    }

    /**
     * Get detailed info for a specific agent
     */
    async getAgentInfo(agentId: string): Promise<AgentInfo | null> {
        const manifestPath = path.join(this.agentsBasePath, agentId, 'manifest.json');

        try {
            const manifestContent = await fs.readFile(manifestPath, 'utf-8');
            const manifest = JSON.parse(manifestContent);

            return {
                id: agentId,
                name: manifest.name || agentId,
                status: 'online',
                capabilities: manifest.domains || [],
                description: manifest.description || '',
                greeting: manifest.greeting || `Hi! I'm ${manifest.name}. How can I help you?`,
                primaryIntents: manifest.primary_intents || [],
                knowledgeSources: manifest.knowledge_sources || []
            };
        } catch (error) {
            return null;
        }
    }

    /**
     * Send a message to an agent and get response
     */
    async sendMessage(params: SendMessageParams): Promise<ChatResponse> {
        const { agentId, message, conversationId, context, userId } = params;

        // Generate or use existing conversation ID
        const convId = conversationId || `conv-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

        // TODO: Actual agent invocation
        // For now, return mock response
        const mockResponse = await this.invokeAgentMock(agentId, message, context);

        // TODO: Save conversation to database
        await this.saveMessage({
            conversationId: convId,
            agentId,
            userId,
            role: 'user',
            content: message
        });

        await this.saveMessage({
            conversationId: convId,
            agentId,
            userId,
            role: 'agent',
            content: mockResponse.message,
            metadata: mockResponse.metadata
        });

        return {
            conversationId: convId,
            message: mockResponse.message,
            suggestions: mockResponse.suggestions,
            attachments: mockResponse.attachments,
            timestamp: new Date().toISOString(),
            metadata: mockResponse.metadata
        };
    }

    /**
     * MOCK: Invoke agent (replace with actual orchestrator call)
     */
    private async invokeAgentMock(agentId: string, message: string, context: any): Promise<any> {
        if (agentId === 'agent_dba') {
            return {
                message: `Per creare una tabella:\n1. Usa Flyway migration\n2. Naming: PORTAL.{ENTITY}\n3. Sequence per NDG\n4. Include tenant_id per RLS`,
                suggestions: [
                    {
                        label: 'Genera DDL',
                        action: 'generate',
                        params: { intent: 'db-table:create' }
                    },
                    {
                        label: 'Spiega RLS',
                        action: 'explain',
                        params: { topic: 'rls' }
                    }
                ],
                attachments: [],
                metadata: {
                    confidence: 0.9,
                    sourceRecipes: ['kb-portal-create-user-001']
                }
            };
        }

        return {
            message: `I received your message: "${message}". I'm ${agentId} and I can help with that.`,
            suggestions: [],
            attachments: [],
            metadata: {
                confidence: 0.5
            }
        };
    }

    /**
     * Get conversation list for user + agent
     */
    async getConversations(params: {
        agentId: string;
        userId: string;
        limit: number;
        offset: number;
    }): Promise<ConversationListResponse> {
        // TODO: Implement database query
        return {
            conversations: [],
            total: 0,
            hasMore: false
        };
    }

    /**
     * Get specific conversation with messages
     */
    async getConversation(params: {
        agentId: string;
        conversationId: string;
        userId: string;
    }): Promise<any | null> {
        // TODO: Implement database query
        return null;
    }

    /**
     * Delete conversation (soft delete)
     */
    async deleteConversation(params: {
        agentId: string;
        conversationId: string;
        userId: string;
    }): Promise<void> {
        // TODO: Implement database soft delete
    }

    /**
     * Save message to database
     */
    private async saveMessage(message: {
        conversationId: string;
        agentId: string;
        userId: string;
        role: 'user' | 'agent';
        content: string;
        metadata?: any;
    }): Promise<void> {
        // TODO: Save to DB
        // console.log('TODO: Save message to DB', message);
    }
}
