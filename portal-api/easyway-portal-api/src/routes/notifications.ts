import { Router } from "express";
import { sendNotification, subscribeNotification } from "../controllers/notificationsController";
import { sendNotificationSchema } from "../validators/notificationValidator";
import { validateBody } from "../middleware/validate";
import { requireAccessFromEnv } from "../middleware/authorize";
import { auditAccess } from "../middleware/audit";
const router = Router();

router.use(auditAccess("api.notifications"));
router.use(requireAccessFromEnv({
  rolesEnv: "NOTIFY_ROLES",
  scopesEnv: "NOTIFY_SCOPES",
  defaultRoles: ["portal_admin", "portal_governance", "portal_ops"]
}));

router.post("/send", validateBody(sendNotificationSchema), sendNotification);
router.post("/subscribe", subscribeNotification);

export default router;
