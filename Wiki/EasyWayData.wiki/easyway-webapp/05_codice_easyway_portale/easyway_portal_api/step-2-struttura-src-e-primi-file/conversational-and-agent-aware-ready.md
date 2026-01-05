---
id: ew-conversational-and-agent-aware-ready
title: conversational and agent aware ready
tags: [domain/frontend, layer/spec, audience/dev, privacy/internal, language/it]
owner: team-platform
summary: Esempi di controller/logging/response agent-aware con header e campi di tracing.
status: draft
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
*   **Header “x-origin”, “x-agent-id”, “x-conversation-id”**  
    → Permettono tracing, correlazione, audit, e collegamento con chatbot/AMS/agent.
    
*   **Logging con intent, origin, esito**  
    → I log sono già formattati per essere letti da BI, AMS, AI.
    
*   **Risposta standardizzata**  
    → Tutti i consumer (umani, bot, sistemi) capiscono esito, intent, contesto.

### **. Controller**


```sql
import { Request, Response } from "express";
import sql from "mssql";
import { logger } from "../utils/logger";

export async function onboarding(req: Request, res: Response) {
  const startTime = Date.now();
  const pool = await sql.connect(process.env.DB_CONN_STRING!);

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
```sql

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?








