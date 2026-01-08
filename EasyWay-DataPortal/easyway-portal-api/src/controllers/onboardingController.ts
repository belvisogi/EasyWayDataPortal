import { Request, Response, NextFunction } from "express";
import { getOnboardingRepo } from "../repositories";
import { logger } from "../utils/logger";

export async function onboarding(req: Request, res: Response, next: NextFunction) {
  const startTime = Date.now();

  // Recupero header conversational/agent-aware
  const origin = req.headers["x-origin"] || "api"; // user, agent, ams, api...
  const agent_id = req.headers["x-agent-id"] || null;
  const conversation_id = req.headers["x-conversation-id"] || null;

  try {
    const {
      tenant_name,
      user_email,
      display_name,
      profile_id,
      ext_attributes = {}
    } = req.body;

    const repo = getOnboardingRepo();
    const result = await repo.registerTenantAndUser((req as any).tenantId ?? '', {
      tenant_name,
      user_email,
      display_name,
      profile_id,
      ext_attributes
    });

    const executionTime = Date.now() - startTime;

    // Logging conversational/agent-aware
    logger.info("Onboarding completato", {
      intent: "ONBOARDING_TENANT_USER",
      origin,
      agent_id,
      user_id: (result?.[0]?.user_id) || null,
      tenant_id: (result?.[0]?.tenant_id) || null,
      conversation_id,
      esito: "success",
      executionTime,
      context: { ...ext_attributes, source_ip: req.ip }
    });

    // Risposta standard conversational/agent-aware
    res.status(201).json({
      status: "success",
      message: "Onboarding completato",
      data: result,
      intent: "ONBOARDING_TENANT_USER",
      esito: "success",
      conversation_id,
      origin
    });

  } catch (err: any) {
    logger.error("Errore onboarding", {
      intent: "ONBOARDING_TENANT_USER",
      origin,
      agent_id,
      conversation_id,
      user_email: req.body.user_email,
      tenant_name: req.body.tenant_name,
      esito: "error",
      error: err.message,
      context: { ...req.body.ext_attributes, source_ip: req.ip }
    });

    next(err);
  }
}
