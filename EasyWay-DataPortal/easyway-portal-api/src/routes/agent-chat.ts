import express, { Request, Response } from 'express';
import { AgentChatService } from '../services/agent-chat.service';
import { validateAgentInput } from '../middleware/security';

const router = express.Router();
const chatService = new AgentChatService();

/**
 * GET /api/agents
 * List all available agents
 */
router.get('/agents', async (req: Request, res: Response) => {
  try {
    const agents = await chatService.listAgents();
    res.json({ agents });
  } catch (error: any) {
    res.status(500).json({
      error: 'internal_server_error',
      message: error.message
    });
  }
});

/**
 * GET /api/agents/:agentId/info
 * Get detailed info for specific agent
 */
router.get('/agents/:agentId/info', async (req: Request, res: Response) => {
  try {
    const { agentId } = req.params;
    const info = await chatService.getAgentInfo(agentId);

    if (!info) {
      return res.status(404).json({
        error: 'agent_not_found',
        message: `Agent ${agentId} not found`
      });
    }

    res.json(info);
  } catch (error: any) {
    res.status(500).json({
      error: 'internal_server_error',
      message: error.message
    });
  }
});

/**
 * POST /api/agents/:agentId/chat
 * Send a message to an agent
 * 
 * Security: Input validation via middleware
 * Rate limiting: Applied via middleware (TODO)
 */
router.post('/agents/:agentId/chat',
  validateAgentInput,  // Security Layer 1 - validates input for prompt injection
  async (req: Request, res: Response) => {
    try {
      const { agentId } = req.params;
      const { message, conversationId, context } = req.body;

      // TODO: Get user from auth middleware
      const userId = (req as any).user?.id || 'anonymous';

      const response = await chatService.sendMessage({
        agentId,
        message,
        conversationId: conversationId || null,
        context: context || {},
        userId
      });

      res.json(response);
    } catch (error: any) {
      if (error.code === 'RATE_LIMIT') {
        return res.status(429).json({
          error: 'rate_limit_exceeded',
          message: 'Too many messages. Please try again later.',
          retryAfter: error.retryAfter
        });
      }

      if (error.code === 'AGENT_NOT_FOUND') {
        return res.status(404).json({
          error: 'agent_not_found',
          message: error.message
        });
      }

      res.status(500).json({
        error: 'internal_server_error',
        message: error.message
      });
    }
  }
);

/**
 * GET /api/agents/:agentId/conversations
 * List conversations for an agent (for current user)
 */
router.get('/agents/:agentId/conversations', async (req: Request, res: Response) => {
  try {
    const { agentId } = req.params;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;

    // TODO: Get user from auth middleware
    const userId = (req as any).user?.id || 'anonymous';

    const result = await chatService.getConversations({
      agentId,
      userId,
      limit,
      offset
    });

    res.json(result);
  } catch (error: any) {
    res.status(500).json({
      error: 'internal_server_error',
      message: error.message
    });
  }
});

/**
 * GET /api/agents/:agentId/conversations/:conversationId
 * Get detailed conversation with messages
 */
router.get('/agents/:agentId/conversations/:conversationId', async (req: Request, res: Response) => {
  try {
    const { agentId, conversationId } = req.params;

    // TODO: Get user from auth middleware
    const userId = (req as any).user?.id || 'anonymous';

    const conversation = await chatService.getConversation({
      agentId,
      conversationId,
      userId
    });

    if (!conversation) {
      return res.status(404).json({
        error: 'conversation_not_found',
        message: 'Conversation not found'
      });
    }

    res.json(conversation);
  } catch (error: any) {
    res.status(500).json({
      error: 'internal_server_error',
      message: error.message
    });
  }
});

/**
 * DELETE /api/agents/:agentId/conversations/:conversationId
 * Delete a conversation (soft delete)
 */
router.delete('/agents/:agentId/conversations/:conversationId', async (req: Request, res: Response) => {
  try {
    const { agentId, conversationId } = req.params;

    // TODO: Get user from auth middleware
    const userId = (req as any).user?.id || 'anonymous';

    await chatService.deleteConversation({
      agentId,
      conversationId,
      userId
    });

    res.status(204).send();
  } catch (error: any) {
    if (error.code === 'NOT_FOUND') {
      return res.status(404).json({
        error: 'conversation_not_found',
        message: 'Conversation not found'
      });
    }

    res.status(500).json({
      error: 'internal_server_error',
      message: error.message
    });
  }
});

export default router;
