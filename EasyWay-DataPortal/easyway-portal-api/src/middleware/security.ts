import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

/**
 * Security middleware for agent input validation
 * 
 * Validates user input for prompt injection, SQL injection, and other attacks
 * Based on validate-agent-input.ps1 logic
 */

interface ValidationResult {
    isValid: boolean;
    violations: string[];
    severity: 'none' | 'low' | 'medium' | 'high' | 'critical';
}

// Dangerous patterns to detect (ported from PowerShell script)
const DANGEROUS_PATTERNS = [
    // Prompt injection
    { pattern: /ignora\s+(tutte?\s+le\s+)?istruzioni/i, description: 'Instruction override (IT)' },
    { pattern: /ignore\s+(all\s+)?instructions/i, description: 'Instruction override (EN)' },
    { pattern: /override\s+(all\s+)?rules/i, description: 'Rule override' },
    { pattern: /disregard\s+previous/i, description: 'Previous instruction disregard' },
    { pattern: /forget\s+everything/i, description: 'Memory reset attempt' },

    // Privilege escalation
    { pattern: /grant\s+all\s+(to\s+)?public/i, description: 'Excessive privilege grant' },
    { pattern: /create\s+user.*admin/i, description: 'Admin user creation' },
    { pattern: /alter\s+user.*sysadmin/i, description: 'Sysadmin privilege' },

    // Hardcoded credentials
    { pattern: /password\s*=\s*['"][^'"]{3,}['"]/i, description: 'Hardcoded password' },
    { pattern: /api[_-]?key\s*=\s*['"][^'"]+['"]/i, description: 'Hardcoded API key' },
    { pattern: /secret\s*=\s*['"][^'"]+['"]/i, description: 'Hardcoded secret' },

    // Command injection
    { pattern: /;\s*exec\s*\(/i, description: 'Command execution' },
    { pattern: /\$\([^)]+\)/i, description: 'Shell command substitution' },
    { pattern: /`[^`]+`/i, description: 'Backtick execution' },

    // SQL injection
    { pattern: /';\s*drop\s+table/i, description: 'SQL DROP injection' },
    { pattern: /'\s+or\s+'1'\s*=\s*'1/i, description: 'SQL OR injection' },
    { pattern: /union\s+select/i, description: 'SQL UNION injection' },

    // Hidden instructions
    { pattern: /\[HIDDEN\]/i, description: 'Hidden marker' },
    { pattern: /<!--.*OVERRIDE.*-->/i, description: 'HTML comment override' },
];

/**
 * Validate input for prompt injection and other attacks
 */
function validateInput(text: string): ValidationResult {
    const violations: string[] = [];

    for (const { pattern, description } of DANGEROUS_PATTERNS) {
        if (pattern.test(text)) {
            violations.push(description);
        }
    }

    const severity = violations.length > 3 ? 'critical'
        : violations.length > 1 ? 'high'
            : violations.length === 1 ? 'medium'
                : 'none';

    return {
        isValid: violations.length === 0,
        violations,
        severity
    };
}

/**
 * Express middleware for agent input validation
 * 
 * Usage:
 * router.post('/chat', validateAgentInput, async (req, res) => {...})
 */
export function validateAgentInput(req: Request, res: Response, next: NextFunction) {
    try {
        // Extract message from body (adjust based on your API structure)
        const message = req.body.message || '';

        if (!message) {
            return next(); // No message to validate, proceed
        }

        // Validate input
        const result = validateInput(message);

        if (!result.isValid) {
            // Log security event
            logger.warn({
                event: 'input_validation_failed',
                severity: result.severity,
                violations: result.violations,
                requestId: (req as any).requestId,
                path: req.path,
                ip: req.ip
            });

            // Block if critical or high severity
            if (result.severity === 'critical' || result.severity === 'high') {
                return res.status(400).json({
                    error: {
                        code: 'security_violation',
                        message: 'Input rejected due to security concerns',
                        severity: result.severity
                    },
                    requestId: (req as any).requestId || null
                });
            }

            // For medium/low, log but proceed (with warning)
            (req as any).securityWarning = {
                violations: result.violations,
                severity: result.severity
            };
        }

        next();
    } catch (error: any) {
        logger.error({
            event: 'input_validation_error',
            error: error.message,
            requestId: (req as any).requestId
        });

        // Fail secure: if validation errors, block the request
        return res.status(500).json({
            error: {
                code: 'validation_error',
                message: 'Input validation failed'
            },
            requestId: (req as any).requestId || null
        });
    }
}

/**
 * Validate output for compliance
 * (For use in service layer, not middleware)
 */
export function validateAgentOutput(output: any): ValidationResult {
    const violations: string[] = [];
    const outputStr = JSON.stringify(output);

    // Check for hardcoded credentials
    if (/password\s*=\s*['"][^'"]{3,}['"]/i.test(outputStr) && !/<KEYVAULT/i.test(outputStr)) {
        violations.push('Hardcoded password detected (use Key Vault)');
    }

    if (/api[_-]?key\s*=\s*['"][^'"]+['"]/i.test(outputStr) && !/<KEYVAULT/i.test(outputStr)) {
        violations.push('Hardcoded API key detected');
    }

    // Check for excessive privileges
    if (/GRANT\s+ALL.*TO.*PUBLIC/i.test(outputStr)) {
        violations.push('Excessive privilege grant detected');
    }

    const severity = violations.length > 0 ? 'high' : 'none';

    return {
        isValid: violations.length === 0,
        violations,
        severity
    };
}
