import { NotificationsRepo, NotificationInput } from "../types";
import { logger } from "../../utils/logger";

export class MockNotificationsRepo implements NotificationsRepo {
    async send(tenantId: string, input: NotificationInput): Promise<void> {
        logger.info(`[MOCK] Sending notification to ${input.user_id} via ${input.channel}: ${input.message}`, { tenantId, input });
        // In a real mock, we might write to a file or in-memory array
        return Promise.resolve();
    }
}
