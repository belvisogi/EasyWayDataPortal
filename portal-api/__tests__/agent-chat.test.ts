import request from 'supertest';
import { AgentChatService } from '../src/services/agent-chat.service';

// 1. Mock dependencies
jest.mock('../src/services/agent-chat.service');

jest.mock('../src/middleware/auth', () => ({
    authenticateJwt: (req: any, res: any, next: any) => {
        req.user = { id: 'test-user', role: 'user' };
        next();
    }
}));
jest.mock('../src/middleware/tenant', () => ({
    extractTenantId: (req: any, res: any, next: any) => {
        req.tenantId = 'test-tenant';
        next();
    }
}));
jest.mock('../src/middleware/security', () => ({
    validateAgentInput: (req: any, res: any, next: any) => next(),
    validateAgentOutput: () => ({ isValid: true })
}));

import app from '../src/app';

describe('Agent Chat API', () => {
    let mockChatService: any;

    beforeAll(() => {
        // Capture the instance created during app import
        const mockInstances = (AgentChatService as any).mock.instances;
        if (mockInstances.length > 0) {
            mockChatService = mockInstances[0];
        } else {
            // Should not happen if app -> agent-chat -> new AgentChatService() chain works
            console.warn("WARNING: No AgentChatService instance found in mock.instances!");
            mockChatService = new AgentChatService();
        }
    });

    beforeEach(() => {
        jest.clearAllMocks();

        // Just ensures methods are mocks (in case clearAllMocks removed them? No, it shouldn't)
        // But better to be safe and define them if missing
        if (!mockChatService.listAgents) mockChatService.listAgents = jest.fn();
        if (!mockChatService.getAgentInfo) mockChatService.getAgentInfo = jest.fn();
        if (!mockChatService.sendMessage) mockChatService.sendMessage = jest.fn();
        if (!mockChatService.getConversations) mockChatService.getConversations = jest.fn();
        if (!mockChatService.getConversation) mockChatService.getConversation = jest.fn();
        if (!mockChatService.deleteConversation) mockChatService.deleteConversation = jest.fn();
    });

    describe('GET /api/agents', () => {
        it('should return list of agents', async () => {
            const mockAgents = [{ id: 'agent_dba', name: 'DBA Agent' }];
            mockChatService.listAgents.mockResolvedValue(mockAgents);

            const res = await request(app).get('/api/agents');

            if (res.status !== 200) console.log('GET /agents failed:', res.status, res.body);
            expect(res.status).toBe(200);
            expect(res.body.agents).toHaveLength(1);
        });

        it('should handle service errors gracefully', async () => {
            mockChatService.listAgents.mockRejectedValue(new Error('Service failure'));
            const res = await request(app).get('/api/agents');
            expect(res.status).toBe(500);
        });
    });

    describe('GET /api/agents/:agentId/info', () => {
        it('should return agent info when found', async () => {
            const mockInfo = { id: 'agent_dba', name: 'DBA Agent' };
            mockChatService.getAgentInfo.mockResolvedValue(mockInfo);

            const res = await request(app).get('/api/agents/agent_dba/info');

            expect(res.status).toBe(200);
            expect(res.body.id).toBe('agent_dba');
        });

        it('should return 404 when agent not found', async () => {
            mockChatService.getAgentInfo.mockResolvedValue(null);
            const res = await request(app).get('/api/agents/unknown_agent/info');
            expect(res.status).toBe(404);
        });
    });

    describe('POST /api/agents/:agentId/chat', () => {
        const validPayload = { message: 'hello', context: {} };

        it('should return chat response on success', async () => {
            const mockResponse = {
                conversationId: 'conv-123',
                message: 'Hello there',
                suggestions: [],
                timestamp: new Date().toISOString()
            };
            mockChatService.sendMessage.mockResolvedValue(mockResponse);

            const res = await request(app)
                .post('/api/agents/agent_dba/chat')
                .send(validPayload);

            if (res.status !== 200) console.log('POST /chat failed:', res.status, res.body);
            expect(res.status).toBe(200);
            expect(res.body.message).toBe('Hello there');
        });

        it('should return 403 on INTENT_NOT_ALLOWED', async () => {
            const error: any = new Error('Intent denied');
            error.code = 'INTENT_NOT_ALLOWED';
            mockChatService.sendMessage.mockRejectedValue(error);

            const res = await request(app)
                .post('/api/agents/agent_dba/chat')
                .send(validPayload);

            expect(res.status).toBe(403);
            expect(res.body.error).toBe('intent_not_allowed');
        });
    });

    describe('GET /api/agents/:agentId/conversations', () => {
        it('should return conversations list', async () => {
            const mockList = { conversations: [], total: 0, hasMore: false };
            mockChatService.getConversations.mockResolvedValue(mockList);

            const res = await request(app).get('/api/agents/agent_dba/conversations');

            expect(res.status).toBe(200);
            expect(res.body.total).toBe(0);
        });
    });
});
