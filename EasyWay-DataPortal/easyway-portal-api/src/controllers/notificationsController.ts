import { Request, Response, NextFunction } from "express";
import { logger } from "../utils/logger";
import { getNotificationsRepo } from "../repositories";

export async function subscribeNotification(req: Request, res: Response, _next: NextFunction) {
  // Placeholder: logica reale la aggiungi dopo (es. preferenze utente su DB)
  res.status(201).json({ message: "Notifica iscrizione ricevuta!" });
}

export async function sendNotification(req: Request, res: Response, next: NextFunction) {
  const tenantId = (req as any).tenantId;
  const { recipients, category, channel, message, ext_attributes = {} } = req.body;

  try {
    const repo = getNotificationsRepo();

    // Invia notifica a ciascun destinatario
    // Nota: idealmente fare batch insert, ma per ora loop con SP singola va bene per volumi bassi
    const promises = recipients.map((user_id: string) =>
      repo.send(tenantId, {
        user_id,
        category,
        channel,
        message,
        ext_attributes
      })
    );

    await Promise.all(promises);

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
    next(err);
  }
}
