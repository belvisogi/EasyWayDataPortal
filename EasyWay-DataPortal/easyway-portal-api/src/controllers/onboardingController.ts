import { Request, Response } from "express";
import sql from "mssql";
import { getPool } from "../utils/db";
import { logger } from "../utils/logger";

export async function onboarding(req: Request, res: Response) {
  const startTime = Date.now();
  const pool = await getPool();

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

    // Chiamata store procedure di onboarding
    const result = await pool.request()
      .input("tenant_name", sql.NVarChar, tenant_name)
      .input("user_email", sql.NVarChar, user_email)
      .input("display_name", sql.NVarChar, display_name)
      .input("profile_id", sql.NVarChar, profile_id)
      .input("ext_attributes", sql.NVarChar, JSON.stringify(ext_attributes))
      .execute("PORTAL.sp_debug_register_tenant_and_user");

    const executionTime = Date.now() - startTime;

    // Logging conversational/agent-aware
    logger.info("Onboarding completato", {
      intent: "ONBOARDING_TENANT_USER",
      origin,
      agent_id,
      user_id: result.recordset[0]?.user_id || null,
      tenant_id: result.recordset[0]?.tenant_id || null,
      conversation_id,
      esito: "success",
      executionTime,
      context: { ...ext_attributes, source_ip: req.ip }
    });

    // Risposta standard conversational/agent-aware
    res.status(201).json({
      status: "success",
      message: "Onboarding completato",
      data: result.recordset,
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

    res.status(500).json({
      status: "error",
      message: err.message,
      intent: "ONBOARDING_TENANT_USER",
      esito: "error",
      conversation_id,
      origin
    });
  }
}
