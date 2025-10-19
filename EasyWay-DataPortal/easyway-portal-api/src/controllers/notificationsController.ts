import { Request, Response } from "express";
import sql from "mssql";
import { getPool, withTenantContext } from "../utils/db";
import { logger } from "../utils/logger";


export async function subscribeNotification(req: Request, res: Response) {
  // Placeholder: logica reale la aggiungi dopo
  res.status(201).json({ message: "Notifica iscrizione ricevuta!" });
}

export async function sendNotification(req: Request, res: Response) {
  const tenantId = (req as any).tenantId;
  const { recipients, category, channel, message, ext_attributes = {} } = req.body;

  try {
    // Per ogni destinatario, chiama la SP (o batch, secondo design DB)
    await withTenantContext(tenantId, async (tx) => {
      for (const user_id of recipients) {
        await new sql.Request(tx)
          .input("tenant_id", sql.NVarChar, tenantId)
          .input("user_id", sql.NVarChar, user_id)
          .input("category", sql.NVarChar, category)
          .input("channel", sql.NVarChar, channel)
          .input("message", sql.NVarChar, message)
          .input("ext_attributes", sql.NVarChar, JSON.stringify(ext_attributes))
          .query("EXEC PORTAL.sp_send_notification @tenant_id, @user_id, @category, @channel, @message, @ext_attributes");
      }
    });

    logger.info("Notification sent", {
      tenantId,
      recipientsCount: recipients.length,
      category,
      channel,
      event: "NOTIFY_SEND",
      time: new Date().toISOString()
    });

    res.status(200).json({ ok: true, sent: recipients.length });

  } catch (err: any) {
    logger.error("Send notification failed", {
      tenantId,
      error: err.message,
      event: "NOTIFY_SEND_ERROR",
      time: new Date().toISOString()
    });
    res.status(500).json({ error: err.message });
  }
}
