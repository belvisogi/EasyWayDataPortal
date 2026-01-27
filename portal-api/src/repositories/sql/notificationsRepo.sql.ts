import sql from "mssql";
import { withTenantContext } from "../../utils/db";
import { NotificationsRepo, NotificationInput } from "../types";

export class SqlNotificationsRepo implements NotificationsRepo {

    async send(tenantId: string, input: NotificationInput): Promise<void> {
        await withTenantContext(tenantId, async (tx) => {
            const request = new sql.Request(tx);

            request.input("tenant_id", sql.NVarChar, tenantId);
            request.input("user_id", sql.NVarChar, input.user_id);
            request.input("category", sql.NVarChar, input.category);
            request.input("channel", sql.NVarChar, input.channel);
            request.input("message", sql.NVarChar, input.message);

            const extAttrJson = input.ext_attributes ? JSON.stringify(input.ext_attributes) : null;
            request.input("ext_attributes", sql.NVarChar, extAttrJson);

            await request.execute("PORTAL.sp_send_notification");
        });
    }
}
