import express, { Request, Response } from 'express';
import rateLimit from "express-rate-limit";
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

function requireAuthContext(req: Request): { userId: string; tenantId: string } {
  const userId = (req as any).user?.id;
  const tenantId = (req as any).tenantId;

  if (!userId || !tenantId) {
    const err: any = new Error("Missing auth context");
    err.code = "AUTH_REQUIRED";
    throw err;
  }

  return { userId, tenantId };
}

const chatRateWindowMs = parseInt(process.env.AGENT_CHAT_RATE_LIMIT_WINDOW_MS || "60000", 10);
const chatRateMax = parseInt(process.env.AGENT_CHAT_RATE_LIMIT_MAX || "60", 10);
const chatRateLimiter = rateLimit({
  windowMs: chatRateWindowMs,
  max: chatRateMax,
  keyGenerator: (req: any) => `${req.tenantId || "unknown"}:${req.user?.id || req.ip || "unknown"}`,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req: any, res: any) => {
    res.status(429).json({
      error: 'rate_limit_exceeded',
      message: 'Too many chat messages. Please try again later.',
      requestId: req.requestId || null,
      correlationId: req.correlationId || null
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
  chatRateLimiter,
  async (req: Request, res: Response) => {
    try {
      const { agentId } = req.params;
      const { message, conversationId, context } = req.body;

      const { userId, tenantId } = requireAuthContext(req);

      const response = await chatService.sendMessage({
        agentId,
        message,
        conversationId: conversationId || null,
        context: context || {},
        userId,
        tenantId
      });

      res.json(response);
    } catch (error: any) {
      if (error.code === 'OUTPUT_BLOCKED') {
        return res.status(502).json({
          error: 'output_blocked',
          message: 'Agent output blocked by policy',
          violations: error.violations || []
        });
      }

      if (error.code === 'INTENT_NOT_ALLOWED') {
        return res.status(403).json({
          error: 'intent_not_allowed',
          message: error.message,
          allowedIntents: error.allowedIntents || []
        });
      }

      if (error.code === 'APPROVAL_REQUIRED') {
        return res.status(428).json({
          error: 'approval_required',
          message: 'Approval required before apply execution',
          executionMode: error.executionMode || 'apply'
        });
      }

      if (error.code === 'APPROVAL_INVALID') {
        return res.status(422).json({
          error: 'approval_invalid',
          message: 'Approval ticket invalid',
          approvalId: error.approvalId || null
        });
      }

      if (error.code === 'AUTH_REQUIRED') {
        return res.status(401).json({
          error: 'unauthorized',
          message: 'Authentication required'
        });
      }

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

    const { userId, tenantId } = requireAuthContext(req);

    const result = await chatService.getConversations({
      agentId,
      userId,
      tenantId,
      limit,
      offset
    });

    res.json(result);
  } catch (error: any) {
    if (error.code === 'AUTH_REQUIRED') {
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Authentication required'
      });
    }

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

    const { userId, tenantId } = requireAuthContext(req);

    const conversation = await chatService.getConversation({
      agentId,
      conversationId,
      userId,
      tenantId
    });

    if (!conversation) {
      return res.status(404).json({
        error: 'conversation_not_found',
        message: 'Conversation not found'
      });
    }

    res.json(conversation);
  } catch (error: any) {
    if (error.code === 'AUTH_REQUIRED') {
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Authentication required'
      });
    }

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

    const { userId, tenantId } = requireAuthContext(req);

    await chatService.deleteConversation({
      agentId,
      conversationId,
      userId,
      tenantId
    });

    res.status(204).send();
  } catch (error: any) {
    if (error.code === 'AUTH_REQUIRED') {
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Authentication required'
      });
    }

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
