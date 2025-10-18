import { Router } from "express";
import { sendNotification } from "../controllers/notificationsController";
import { sendNotificationSchema } from "../validators/notificationValidator";
import { validateBody } from "../middleware/validate";

import { subscribeNotification } from "../controllers/notificationsController";



const router = Router();

router.post("/send", validateBody(sendNotificationSchema), sendNotification);
router.post("/subscribe", subscribeNotification);
router.post("/subscribe", subscribeNotification);
router.post("/subscribe", (req, res) => {
  // Logica iscrizione (da implementare)
  res.status(201).json({ message: "Notifica iscrizione ricevuta!" });
});

export default router;