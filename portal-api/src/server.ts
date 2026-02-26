// easyway-portal-api/src/server.ts
import { initSecrets } from "./utils/secrets";

(async () => {
  try {
    // 1. Load Secrets (Env + KeyVault) BEFORE any other imports
    await initSecrets();

    // 2. Load Tracing (uses env vars)
    await import("./observability/tracing");

    // 3. Load App
    const { default: app } = await import("./app");

    const PORT = process.env.PORT || 3000;

    app.listen(PORT, () => {
      // eslint-disable-next-line no-console
      console.log(`EasyWay API running on port ${PORT}`);

      // 4. Start autonomous cron scheduler (only in production)
      if ((process.env.CRON_ENABLED || "false").toLowerCase() === "true") {
        import("./cron/scheduler").then(({ startScheduler }) => {
          startScheduler();
        }).catch(err => {
          // eslint-disable-next-line no-console
          console.error("Failed to start scheduler:", err);
        });
      }
    });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error("Failed to start server:", err);
    process.exit(1);
  }
})();
