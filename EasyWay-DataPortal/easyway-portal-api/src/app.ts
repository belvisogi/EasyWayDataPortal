// easyway-portal-api/src/app.ts
import express from "express";
import dotenv from "dotenv";
import path from "path";
import { logger } from "./utils/logger";
import { extractTenantId } from "./middleware/tenant";
import healthRoutes from "./routes/health";
import brandingRoutes from "./routes/branding";
import configRoutes from "./routes/config";
import usersRoutes from "./routes/users";
import onboardingRoutes from "./routes/onboarding";
import notificationsRoutes from "./routes/notifications";
import docsRoutes from "./routes/docs";

// Carica variabili di ambiente (.env) e fallback opzionale .env.local
dotenv.config();
dotenv.config({ path: path.resolve(__dirname, "../.env.local"), override: false });

const app = express();
app.use(express.json());

// Logging di ogni richiesta base
app.use((req, res, next) => {
  logger.info(`[${req.method}] ${req.originalUrl}`);
  next();
});

// Middleware per estrarre tenant_id da header/JWT (customizza a piacere)
app.use(extractTenantId);

// Rotte API
app.use("/api/health", healthRoutes);
app.use("/api/branding", brandingRoutes);
app.use("/api/config", configRoutes);
app.use("/api/users", usersRoutes);
app.use("/api/onboarding", onboardingRoutes);
app.use("/api/notifications", notificationsRoutes);
app.use("/api/docs", docsRoutes);

export default app;
