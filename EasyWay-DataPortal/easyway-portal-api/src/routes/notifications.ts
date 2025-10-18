import { Router } from "express";
import { sendNotification, subscribeNotification } from "../controllers/notificationsController";
import { sendNotificationSchema } from "../validators/notificationValidator";
import { validateBody } from "../middleware/validate";
const router = Router();

router.post("/send", validateBody(sendNotificationSchema), sendNotification);
router.post("/subscribe", subscribeNotification);

export default router;
