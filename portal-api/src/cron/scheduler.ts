import cron from "node-cron";
import { logger } from "../utils/logger";
import { runInfraDriftCheck } from "./jobs/infra-drift";
import { runOpenApiValidate } from "./jobs/openapi-validate";
import { runSprintReport } from "./jobs/sprint-report";

const TIMEZONE = process.env.CRON_TIMEZONE || "Europe/Rome";

export function startScheduler(): void {
  logger.info("[scheduler] Starting autonomous cron scheduler");

  // Infra drift check: every 6 hours
  cron.schedule("0 */6 * * *", async () => {
    try { await runInfraDriftCheck(); }
    catch (err: any) { logger.error(`[scheduler] infra-drift error: ${err.message}`); }
  }, { timezone: TIMEZONE });

  // OpenAPI validation: every Monday at 09:00
  cron.schedule("0 9 * * 1", async () => {
    try { await runOpenApiValidate(); }
    catch (err: any) { logger.error(`[scheduler] openapi-validate error: ${err.message}`); }
  }, { timezone: TIMEZONE });

  // Sprint report: every Monday at 08:00
  cron.schedule("0 8 * * 1", async () => {
    try { await runSprintReport(); }
    catch (err: any) { logger.error(`[scheduler] sprint-report error: ${err.message}`); }
  }, { timezone: TIMEZONE });

  logger.info("[scheduler] Scheduled: infra-drift (*/6h), openapi-validate (Mon 09:00), sprint-report (Mon 08:00)");
}
