// easyway-portal-api/src/app.ts
import express from "express";
import dotenv from "dotenv";
import path from "path";
import helmet from "helmet";
import cors from "cors";
import compression from "compression";
import rateLimit from "express-rate-limit";
import { v4 as uuidv4 } from "uuid";
import { logger } from "./utils/logger";
import { authenticateJwt } from "./middleware/auth";
import { extractTenantId } from "./middleware/tenant";
import { errorHandler, notFoundHandler } from "./middleware/errorHandler";
import healthRoutes from "./routes/health";
import portalRoutes from "./routes/portal";
import brandingRoutes from "./routes/branding";
import configRoutes from "./routes/config";
import usersRoutes from "./routes/users";
import onboardingRoutes from "./routes/onboarding";
import notificationsRoutes from "./routes/notifications";
import docsRoutes from "./routes/docs";
import dbRoutes from "./routes/db";

// Carica variabili di ambiente (.env) e fallback opzionale .env.local
dotenv.config();
dotenv.config({ path: path.resolve(__dirname, "../.env.local"), override: false });

const app = express();
// Trust proxy if behind load balancer
if ((process.env.TRUST_PROXY || "").toLowerCase() === "true") {
  app.set("trust proxy", 1);
}

// Public Portal (static-like) before auth (parametrized base path)
const PORTAL_BASE_PATH = process.env.PORTAL_BASE_PATH || "/portal";
app.use(PORTAL_BASE_PATH, portalRoutes);

// Security & performance middleware
app.use(helmet());

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "http://localhost:3000").split(",").map(o => o.trim());
app.use(cors({
  origin: (origin, cb) => {
    if (!origin) return cb(null, true);
    return allowedOrigins.includes(origin) ? cb(null, true) : cb(new Error("CORS not allowed"));
  },
  credentials: true
}));

app.use(compression());
app.use(express.json({ limit: process.env.BODY_LIMIT || "1mb" }));

// Request/Correlation IDs + logging baseline
app.use((req, res, next) => {
  const reqId = (req.header("x-request-id") || uuidv4()).toString();
  const corrId = (req.header("x-correlation-id") || reqId).toString();
  (req as any).requestId = reqId;
  (req as any).correlationId = corrId;
  res.setHeader("X-Request-Id", reqId);
  res.setHeader("X-Correlation-Id", corrId);
  logger.info(`[${req.method}] ${req.originalUrl}`);
  next();
});

// Auth + Tenant extraction from token claims
app.use(authenticateJwt);
app.use(extractTenantId);

// Rate limit per tenant (steady + burst) for API routes
const tenantWindowMs = parseInt(process.env.TENANT_RATE_LIMIT_WINDOW_MS || "60000", 10);
const tenantMax = parseInt(process.env.TENANT_RATE_LIMIT_MAX || "600", 10);
const burstWindowMs = parseInt(process.env.TENANT_BURST_WINDOW_MS || "10000", 10);
const burstMax = parseInt(process.env.TENANT_BURST_MAX || "120", 10);
const tenantKey = (req: any) => req.tenantId || req.ip || "unknown";
const rateLimitHandler = (req: any, res: any) => {
  res.status(429).json({
    error: { code: "rate_limit", message: "Too many requests" },
    requestId: req.requestId || null,
    correlationId: req.correlationId || null
  });
};
const tenantLimiter = rateLimit({
  windowMs: tenantWindowMs,
  max: tenantMax,
  keyGenerator: tenantKey,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler
});
const tenantBurstLimiter = rateLimit({
  windowMs: burstWindowMs,
  max: burstMax,
  keyGenerator: tenantKey,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler
});
app.use("/api", tenantLimiter, tenantBurstLimiter);

// Rotte API
app.use("/api/health", healthRoutes);
app.use("/api/branding", brandingRoutes);
app.use("/api/config", configRoutes);
app.use("/api/users", usersRoutes);
app.use("/api/onboarding", onboardingRoutes);
app.use("/api/notifications", notificationsRoutes);
app.use("/api/docs", docsRoutes);
app.use("/api/db", dbRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
