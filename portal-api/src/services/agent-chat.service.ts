import * as fs from 'fs/promises';
import * as path from 'path';
import { execFile } from 'child_process';
import { promisify } from 'util';
import { getAgentChatRepo } from '../repositories';
import { logger } from '../utils/logger';
import { validateAgentOutput } from '../middleware/security';

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
    tenantId: string;
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
    private execFileAsync = promisify(execFile);
    private chatRepo = getAgentChatRepo();
    private enforceAllowlist = (process.env.AGENT_CHAT_ENFORCE_ALLOWLIST || 'true').toLowerCase() === 'true';
    private redactEnabled = (process.env.AGENT_CHAT_REDACT || 'true').toLowerCase() === 'true';
    private maxMessageLen = parseInt(process.env.AGENT_CHAT_MAX_MESSAGE_LEN || '4000', 10);
    private maxMetadataLen = parseInt(process.env.AGENT_CHAT_MAX_METADATA_LEN || '4000', 10);
    private requireApprovalOnApply = (process.env.AGENT_CHAT_REQUIRE_APPROVAL_ON_APPLY || 'true').toLowerCase() === 'true';
    private approvalTicketPattern = process.env.APPROVAL_TICKET_PATTERN || '^CAB-\\d{4}-\\d{4}$';
    private approvalTicketValidateUrl = process.env.APPROVAL_TICKET_VALIDATE_URL || '';
    private approvalTicketValidateMethod = (process.env.APPROVAL_TICKET_VALIDATE_METHOD || 'GET').toUpperCase();
    private approvalTicketValidateHeader = process.env.APPROVAL_TICKET_VALIDATE_HEADER || '';
    private approvalTicketValidateToken = process.env.APPROVAL_TICKET_VALIDATE_TOKEN || '';

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
        const { agentId, message, conversationId, context, userId, tenantId } = params;

        // Generate or use existing conversation ID
        const convId = conversationId || `conv-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

        const sanitizedMessage = this.sanitizeText(message);
        const sanitizedContext = this.sanitizeContext(context);
        const response = await this.invokeAgent(agentId, sanitizedMessage, sanitizedContext);
        const responseMetadata = this.sanitizeResponseMetadata(response?.metadata || {});

        // Persist conversation (DB_MODE=sql -> LOG_AUDIT-backed SPs; DB_MODE=mock -> in-memory)
        await this.chatRepo.logMessage(tenantId, {
            actor: userId,
            agentId,
            conversationId: convId,
            role: 'user',
            content: sanitizedMessage,
            metadata: { context: sanitizedContext }
        });

        await this.chatRepo.logMessage(tenantId, {
            actor: userId,
            agentId,
            conversationId: convId,
            role: 'agent',
            content: this.sanitizeText(response.message),
            metadata: responseMetadata
        });

        const outputCheck = validateAgentOutput({
            message: response.message,
            metadata: response.metadata,
            suggestions: response.suggestions
        });
        if (!outputCheck.isValid) {
            logger.warn({
                event: 'agent_chat_output_blocked',
                violations: outputCheck.violations,
                severity: outputCheck.severity,
                agentId,
                userId,
                tenantId
            });
            const err: any = new Error('Agent output blocked by policy');
            err.code = 'OUTPUT_BLOCKED';
            err.violations = outputCheck.violations;
            throw err;
        }

        return {
            conversationId: convId,
            message: response.message,
            suggestions: response.suggestions,
            attachments: response.attachments,
            timestamp: new Date().toISOString(),
            metadata: response.metadata
        };
    }

    /**
     * Invoke agent via orchestrator plan (deterministic, machine-readable)
     */
    private async invokeAgent(agentId: string, message: string, context: any): Promise<any> {
        const intent = this.resolveIntent(agentId, message, context);

        if (!intent) {
            return {
                message: `Per continuare, indica un intent (es. \`intent: predeploy-checklist\`) oppure usa i pulsanti rapidi dell'agente.`,
                suggestions: this.suggestDefaultIntents(agentId),
                attachments: [],
                metadata: { confidence: 0.4, agentId }
            };
        }

        if (this.enforceAllowlist) {
            const allowlist = await this.getAgentIntentAllowlist(agentId);
            if (allowlist.length > 0 && !allowlist.includes(intent)) {
                const err: any = new Error(`Intent not allowed for agent ${agentId}`);
                err.code = 'INTENT_NOT_ALLOWED';
                err.allowedIntents = allowlist;
                throw err;
            }
        }

        const executionMode = this.getExecutionMode(context);
        if (executionMode === 'apply' && this.requireApprovalOnApply) {
            const approvalId = this.getApprovalTicketId(context);
            if (!approvalId || !this.hasApprovalFlag(context)) {
                const err: any = new Error('Approval required before execute');
                err.code = 'APPROVAL_REQUIRED';
                err.executionMode = executionMode;
                throw err;
            }
            const isValidApproval = await this.validateApprovalTicket(approvalId);
            if (!isValidApproval) {
                const err: any = new Error('Approval ticket invalid');
                err.code = 'APPROVAL_INVALID';
                err.approvalId = approvalId;
                throw err;
            }
        }

        const plan = await this.runOrchestratorPlan(intent, context);
        const summary = this.formatPlanSummary(plan);

        return {
            message: summary,
            suggestions: [
                ...(plan?.suggestion ? [{ label: 'Apri piano (JSON)', action: 'show_plan', params: { intent } }] : []),
                { label: 'Esegui via ewctl', action: 'run_ewctl', params: { engine: 'ps', intent } }
            ],
            attachments: [],
            metadata: { confidence: 0.85, intent, plan, executionMode }
        };
    }

    private resolveIntent(agentId: string, message: string, context: any): string | null {
        const explicit = this.extractExplicitIntent(message) || context?.intent || context?.intentId || null;
        if (explicit) return String(explicit);

        const text = String(message || '').toLowerCase();
        if (agentId === 'agent_governance' && text.includes('checklist')) return 'predeploy-checklist';
        if (agentId === 'agent_dba' && (text.includes('tabella') || text.includes('ddl'))) return 'db-table-create';
        if (agentId === 'agent_dba' && text.includes('drift')) return 'db-drift-check';
        if (agentId === 'agent_docs_review' && (text.includes('wiki') || text.includes('document'))) return 'wiki-normalize-review';
        if (agentId === 'agent_security' && (text.includes('security') || text.includes('rilasc') || text.includes('release'))) return 'release-preflight-security';
        return null;
    }

    private extractExplicitIntent(message: string): string | null {
        const m = String(message || '').match(/^\s*(?:intent\s*:|\/intent\s+)([A-Za-z0-9_.:-]+)\s*$/i);
        return m?.[1] ? m[1] : null;
    }

    private getExecutionMode(context: any): 'plan' | 'apply' {
        const mode = String(context?.executionMode || context?.mode || 'plan').toLowerCase();
        return mode === 'apply' ? 'apply' : 'plan';
    }

    private hasApprovalFlag(context: any): boolean {
        return context?.approved === true || context?.approval === true;
    }

    private getApprovalTicketId(context: any): string | null {
        if (typeof context?.approvalId === 'string' && context.approvalId.trim().length > 0) {
            return context.approvalId.trim();
        }
        return null;
    }

    private async validateApprovalTicket(approvalId: string): Promise<boolean> {
        if (this.approvalTicketPattern) {
            try {
                const pattern = new RegExp(this.approvalTicketPattern);
                if (!pattern.test(approvalId)) return false;
            } catch {
                return false;
            }
        }

        if (!this.approvalTicketValidateUrl) return true;

        const url = this.interpolateApprovalUrl(approvalId);
        const headers: Record<string, string> = {};
        if (this.approvalTicketValidateHeader && this.approvalTicketValidateToken) {
            headers[this.approvalTicketValidateHeader] = this.approvalTicketValidateToken;
        }

        const opts: any = {
            method: this.approvalTicketValidateMethod,
            headers
        };
        if (this.approvalTicketValidateMethod !== 'GET') {
            headers['Content-Type'] = 'application/json';
            opts.body = JSON.stringify({ ticketId: approvalId });
        }

        try {
            const res = await fetch(url, opts);
            if (!res.ok) return false;
            const data = await res.json().catch(() => null);
            if (data && typeof data.valid === 'boolean') return data.valid;
            return true;
        } catch {
            return false;
        }
    }

    private interpolateApprovalUrl(approvalId: string): string {
        if (this.approvalTicketValidateUrl.includes('{ticketId}')) {
            return this.approvalTicketValidateUrl.replace('{ticketId}', encodeURIComponent(approvalId));
        }

        if (this.approvalTicketValidateMethod === 'GET') {
            const separator = this.approvalTicketValidateUrl.includes('?') ? '&' : '?';
            return `${this.approvalTicketValidateUrl}${separator}ticketId=${encodeURIComponent(approvalId)}`;
        }

        return this.approvalTicketValidateUrl;
    }

    private async getAgentIntentAllowlist(agentId: string): Promise<string[]> {
        const manifestPath = path.join(this.agentsBasePath, agentId, 'manifest.json');
        try {
            const manifestContent = await fs.readFile(manifestPath, 'utf-8');
            const manifest = JSON.parse(manifestContent);
            const intents = Array.isArray(manifest.primary_intents) ? manifest.primary_intents : [];
            return intents.map((i: any) => String(i));
        } catch {
            return [];
        }
    }

    private sanitizeText(input: string): string {
        if (!input) return '';
        let text = String(input);
        if (this.redactEnabled) text = this.redactText(text);
        return this.truncate(text, this.maxMessageLen);
    }

    private sanitizeContext(context: any): Record<string, any> {
        if (!context || typeof context !== 'object') return {};
        const out: Record<string, any> = {};
        if (typeof context.executionMode === 'string') out.executionMode = this.getExecutionMode(context);
        if (typeof context.approved === 'boolean') out.approved = context.approved;
        if (typeof context.approvalId === 'string') out.approvalId = this.sanitizeText(context.approvalId);
        if (typeof context.branch === 'string') out.branch = this.sanitizeText(context.branch);
        if (Array.isArray(context.tags)) out.tags = context.tags.map((t: any) => this.sanitizeText(String(t)));
        if (Array.isArray(context.changedPaths)) out.changedPaths = context.changedPaths.map((p: any) => this.sanitizeText(String(p)));
        if (typeof context.intent === 'string') out.intent = this.sanitizeText(context.intent);
        if (typeof context.intentId === 'string') out.intentId = this.sanitizeText(context.intentId);
        return out;
    }

    private sanitizeResponseMetadata(metadata: any): Record<string, any> {
        if (!metadata || typeof metadata !== 'object') return {};
        const out: Record<string, any> = {};
        if (metadata.intent) out.intent = this.sanitizeText(String(metadata.intent));
        if (metadata.agentId) out.agentId = this.sanitizeText(String(metadata.agentId));
        if (metadata.confidence !== undefined) out.confidence = metadata.confidence;
        return this.truncateMetadata(out);
    }

    private truncateMetadata(obj: Record<string, any>): Record<string, any> {
        const json = JSON.stringify(obj);
        if (json.length <= this.maxMetadataLen) return obj;
        const truncated = json.slice(0, this.maxMetadataLen);
        return { _truncated: true, _json: truncated };
    }

    private truncate(text: string, maxLen: number): string {
        if (text.length <= maxLen) return text;
        return text.slice(0, maxLen);
    }

    private redactText(text: string): string {
        let out = text;
        out = out.replace(/(password|pwd|secret|api[_-]?key|token)\s*=\s*['"][^'"]+['"]/gi, '$1=\"[REDACTED]\"');
        out = out.replace(/(Password|Pwd|Secret|SharedAccessKey|AccountKey)\s*=\s*[^;\\s]+/gi, '$1=[REDACTED]');
        out = out.replace(/Bearer\\s+[A-Za-z0-9._-]+/gi, 'Bearer [REDACTED]');
        out = out.replace(/"?(password|secret|apiKey|token)"?\\s*:\\s*"[^"]+"/gi, '"$1":"[REDACTED]"');
        return out;
    }

    private suggestDefaultIntents(agentId: string): Array<{ label: string; action: string; params?: any }> {
        if (agentId === 'agent_dba') {
            return [
                { label: 'Crea tabella (db-table-create)', action: 'set_intent', params: { intent: 'db-table-create' } },
                { label: 'DB drift check (db-drift-check)', action: 'set_intent', params: { intent: 'db-drift-check' } }
            ];
        }
        if (agentId === 'agent_governance') {
            return [
                { label: 'Predeploy checklist', action: 'set_intent', params: { intent: 'predeploy-checklist' } },
                { label: 'WHAT-first lint', action: 'set_intent', params: { intent: 'whatfirst-lint' } }
            ];
        }
        return [{ label: 'Predeploy checklist', action: 'set_intent', params: { intent: 'predeploy-checklist' } }];
    }

    private async runOrchestratorPlan(intent: string, context: any): Promise<any> {
        const repoRoot = path.resolve(__dirname, '../../../');
        const orchestratorPath = path.join(repoRoot, 'agents', 'core', 'orchestrator.js');

        const args: string[] = ['--intent', intent];
        if (context?.branch) args.push('--branch', String(context.branch));
        if (Array.isArray(context?.changedPaths) && context.changedPaths.length > 0) args.push('--changedPaths', context.changedPaths.join(','));
        if (Array.isArray(context?.columns) && context.columns.length > 0) args.push('--columns', context.columns.join(','));
        if (Array.isArray(context?.tags) && context.tags.length > 0) args.push('--tags', context.tags.join(','));

        const { stdout } = await this.execFileAsync('node', [orchestratorPath, ...args], { cwd: repoRoot, timeout: 30000 });
        const parsed = JSON.parse(stdout);
        return parsed?.plan || parsed;
    }

    private formatPlanSummary(plan: any): string {
        const intent = plan?.intent || '(unknown)';
        const recipeId = plan?.recipeId || null;
        const checklist = Array.isArray(plan?.checklistSuggestions) ? plan.checklistSuggestions : [];

        const lines: string[] = [];
        lines.push(`Piano generato per intent: ${intent}${recipeId ? ` (recipe: ${recipeId})` : ''}`);

        if (plan?.suggestion?.action) {
            lines.push(`Suggerimento: ${plan.suggestion.action}${plan.suggestion.reason ? ` — ${plan.suggestion.reason}` : ''}`);
        }

        const top = checklist.slice(0, 3).map((c: any) => c?.name || c?.id).filter(Boolean);
        if (top.length > 0) {
            lines.push(`Checklist consigliate: ${top.join(', ')}`);
        }

        lines.push(`Esempio comando: pwsh scripts/ewctl.ps1 --engine ps --intent ${intent}`);
        return lines.join('\n');
    }

    /**
     * Get conversation list for user + agent
     */
    async getConversations(params: {
        agentId: string;
        userId: string;
        tenantId: string;
        limit: number;
        offset: number;
    }): Promise<ConversationListResponse> {
        const { agentId, userId, tenantId, limit, offset } = params;
        const res = await this.chatRepo.listConversations(tenantId, { actor: userId, agentId, limit, offset });
        return {
            conversations: res.conversations,
            total: res.total,
            hasMore: (offset + limit) < res.total
        };
    }

    /**
     * Get specific conversation with messages
     */
    async getConversation(params: {
        agentId: string;
        conversationId: string;
        userId: string;
        tenantId: string;
    }): Promise<any | null> {
        const { agentId, conversationId, userId, tenantId } = params;
        const res = await this.chatRepo.getConversation(tenantId, { actor: userId, agentId, conversationId });
        if (res.deleted) return null;
        return {
            conversationId,
            agentId,
            userId,
            messages: res.messages
        };
    }

    /**
     * Delete conversation (soft delete)
     */
    async deleteConversation(params: {
        agentId: string;
        conversationId: string;
        userId: string;
        tenantId: string;
    }): Promise<void> {
        const { agentId, conversationId, userId, tenantId } = params;
        await this.chatRepo.deleteConversation(tenantId, { actor: userId, agentId, conversationId });
    }
}
