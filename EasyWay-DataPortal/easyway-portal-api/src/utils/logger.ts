// easyway-portal-api/src/utils/logger.ts
import winston from "winston";
import fs from "fs";
import path from "path";

// Livello di log parametrico via env: 'debug', 'info', 'warn', 'error'
const logLevel = process.env.LOG_LEVEL || "info";

// Assicurati che la cartella di log esista (parametrizzabile via env LOG_DIR)
const logsDir = path.resolve(process.cwd(), process.env.LOG_DIR || "logs");
try { if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir, { recursive: true }); } catch {}

const logger = winston.createLogger({
  level: logLevel,
  format: winston.format.json(),
  transports: [
    new winston.transports.Console({
      format: winston.format.simple(), // Per ambiente dev/test
    }),
    // Log business/errore su file in formato JSON (facile upload su Datalake o forward)
    new winston.transports.File({
      filename: path.join(logsDir, "business.log.json"),
      level: "info", // Solo info/warn/error, non debug
      maxsize: 10485760, // 10MB
      maxFiles: 7
    }),
    new winston.transports.File({
      filename: path.join(logsDir, "error.log.json"),
      level: "error",
      maxsize: 10485760, // 10MB
      maxFiles: 7
    }),
  ]
});

export { logger };
