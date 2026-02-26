export type ErrorCode =
  | "auth_missing_token"
  | "auth_invalid_token"
  | "auth_not_configured"
  | "auth_invalid_jwks"
  | "tenant_missing"
  | "validation_error"
  | "not_found"
  | "rate_limit"
  | "cors_denied"
  | "internal_error"
  | "invalid_agent_id"
  | "no_action"
  | "knowledge_query_required"
  | "knowledge_query_too_long"
  | "knowledge_parse_error"
  | "knowledge_timeout"
  | "knowledge_error";

export class AppError extends Error {
  status: number;
  code: ErrorCode;
  details?: unknown;

  constructor(status: number, code: ErrorCode, message: string, details?: unknown) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export function toAppError(err: unknown): AppError {
  if (err instanceof AppError) return err;
  const message = err instanceof Error ? err.message : "Internal server error";
  return new AppError(500, "internal_error", message);
}
