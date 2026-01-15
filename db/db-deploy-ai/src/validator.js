import sql from 'mssql';

/**
 * Database Best Practices Validator
 * Checks naming conventions, standards, and consistency
 */

export const RULES = {
    naming: {
        // Naming convention rules
        table_prefix: {
            severity: 'warning',
            check: (name) => /^[A-Z_]+$/.test(name),
            message: 'Table names should be UPPERCASE with underscores'
        },
        procedure_prefix: {
            severity: 'error',
            check: (name) => name.startsWith('sp_'),
            message: 'Stored procedures must start with sp_ prefix'
        },
        function_prefix: {
            severity: 'error',
            check: (name) => name.startsWith('fn_'),
            message: 'Functions must start with fn_ prefix'
        },
        parameter_prefix: {
            severity: 'error',
            check: (name) => name.startsWith('@'),
            message: 'Parameters must start with @ symbol'
        }
    },

    bestPractices: {
        // SQL Server best practices
        no_select_star: {
            severity: 'warning',
            pattern: /SELECT\s+\*/i,
            message: 'Avoid SELECT * - specify column names explicitly'
        },
        set_nocount_on: {
            severity: 'error',
            pattern: /SET\s+NOCOUNT\s+ON/i,
            required: true,
            message: 'All procedures should include SET NOCOUNT ON'
        },
        use_schema: {
            severity: 'error',
            pattern: /FROM\s+\w+\./i,
            required: true,
            message: 'Always use schema prefix (e.g., PORTAL.TABLE)'
        },
        transaction_handling: {
            severity: 'warning',
            pattern: /BEGIN\s+TRAN/i,
            requires: [/COMMIT/i, /ROLLBACK/i],
            message: 'Transactions must have both COMMIT and ROLLBACK paths'
        },
        error_handling: {
            severity: 'error',
            pattern: /BEGIN\s+TRY/i,
            requires: /BEGIN\s+CATCH/i,
            message: 'Use TRY...CATCH for error handling'
        }
    },

    consistency: {
        // Consistency checks across procedures
        return_format: {
            severity: 'warning',
            message: 'All procedures should return consistent JSON: {status, ...}'
        },
        logging: {
            severity: 'warning',
            pattern: /sp_log_stats_execution/i,
            message: 'Consider using sp_log_stats_execution for audit logging'
        },
        parameter_naming: {
            severity: 'info',
            conventions: [
                { pattern: /@tenant_id/, example: '@tenant_id NVARCHAR(50)' },
                { pattern: /@user_id/, example: '@user_id NVARCHAR(50)' },
                { pattern: /@created_by/, example: '@created_by NVARCHAR(255)' }
            ],
            message: 'Follow standard parameter naming from existing procedures'
        }
    },

    security: {
        // Security best practices
        sql_injection: {
            severity: 'critical',
            pattern: /EXEC\s*\(\s*@/i,
            message: 'Potential SQL injection risk - use sp_executesql instead of EXEC(@var)'
        },
        rls_compliance: {
            severity: 'warning',
            message: 'Ensure tenant_id filtering for multi-tenant tables'
        }
    }
};

/**
 * Validate a SQL statement against all rules
 */
export async function validateSQL(sql, type = 'procedure') {
    const violations = [];

    // Check naming conventions
    if (type === 'procedure') {
        const procMatch = sql.match(/CREATE\s+(OR\s+ALTER\s+)?PROCEDURE\s+(\w+\.)?(\w+)/i);
        if (procMatch) {
            const procName = procMatch[3];
            if (!RULES.naming.procedure_prefix.check(procName)) {
                violations.push({
                    rule: 'procedure_prefix',
                    severity: 'error',
                    message: RULES.naming.procedure_prefix.message,
                    line: findLineNumber(sql, procMatch[0])
                });
            }
        }
    }

    // Check SET NOCOUNT ON
    if (type === 'procedure') {
        if (!RULES.bestPractices.set_nocount_on.pattern.test(sql)) {
            violations.push({
                rule: 'set_nocount_on',
                severity: 'error',
                message: RULES.bestPractices.set_nocount_on.message,
                suggestion: 'Add "SET NOCOUNT ON;" at the beginning of the procedure'
            });
        }
    }

    // Check SELECT *
    const selectStarMatches = sql.matchAll(RULES.bestPractices.no_select_star.pattern);
    for (const match of selectStarMatches) {
        violations.push({
            rule: 'no_select_star',
            severity: 'warning',
            message: RULES.bestPractices.no_select_star.message,
            line: findLineNumber(sql, match[0]),
            suggestion: 'Specify column names explicitly for better performance and maintainability'
        });
    }

    // Check schema usage
    const fromClauses = sql.matchAll(/FROM\s+(\w+)\s/gi);
    for (const match of fromClauses) {
        if (!match[1].includes('.')) {
            violations.push({
                rule: 'use_schema',
                severity: 'error',
                message: RULES.bestPractices.use_schema.message,
                line: findLineNumber(sql, match[0]),
                suggestion: `Use PORTAL.${match[1]} instead of ${match[1]}`
            });
        }
    }

    // Check transaction handling
    if (RULES.bestPractices.transaction_handling.pattern.test(sql)) {
        const hasCommit = /COMMIT/i.test(sql);
        const hasRollback = /ROLLBACK/i.test(sql);

        if (!hasCommit || !hasRollback) {
            violations.push({
                rule: 'transaction_handling',
                severity: 'warning',
                message: RULES.bestPractices.transaction_handling.message,
                suggestion: 'Ensure both COMMIT and ROLLBACK are present in transaction logic'
            });
        }
    }

    // Check error handling
    const hasTry = RULES.bestPractices.error_handling.pattern.test(sql);
    const hasCatch = RULES.bestPractices.error_handling.requires.test(sql);

    if (hasTry && !hasCatch) {
        violations.push({
            rule: 'error_handling',
            severity: 'error',
            message: RULES.bestPractices.error_handling.message,
            suggestion: 'Add BEGIN CATCH...END CATCH block'
        });
    }

    // Check SQL injection risks
    if (RULES.security.sql_injection.pattern.test(sql)) {
        violations.push({
            rule: 'sql_injection',
            severity: 'critical',
            message: RULES.security.sql_injection.message,
            suggestion: 'Use sp_executesql with parameters instead of dynamic EXEC'
        });
    }

    return {
        valid: violations.filter(v => v.severity === 'error' || v.severity === 'critical').length === 0,
        violations,
        summary: {
            critical: violations.filter(v => v.severity === 'critical').length,
            errors: violations.filter(v => v.severity === 'error').length,
            warnings: violations.filter(v => v.severity === 'warning').length,
            info: violations.filter(v => v.severity === 'info').length
        }
    };
}

/**
 * Validate naming consistency across multiple procedures
 */
export function validateConsistency(procedures) {
    const violations = [];

    // Check parameter naming consistency
    const parameterPatterns = new Map();

    for (const proc of procedures) {
        const params = extractParameters(proc.sql);

        for (const param of params) {
            if (param.name === '@tenant_id' && param.type !== 'NVARCHAR(50)') {
                violations.push({
                    procedure: proc.name,
                    rule: 'parameter_consistency',
                    severity: 'warning',
                    message: `Parameter @tenant_id should be NVARCHAR(50), found ${param.type}`,
                    suggestion: 'Use consistent parameter types across procedures'
                });
            }

            if (param.name === '@created_by' && param.type !== 'NVARCHAR(255)') {
                violations.push({
                    procedure: proc.name,
                    rule: 'parameter_consistency',
                    severity: 'warning',
                    message: `Parameter @created_by should be NVARCHAR(255), found ${param.type}`
                });
            }
        }
    }

    // Check return format consistency
    const returnFormats = procedures.map(proc => detectReturnFormat(proc.sql));
    const inconsistentReturns = returnFormats.filter((fmt, idx, arr) =>
        fmt !== arr[0] && fmt !== null
    );

    if (inconsistentReturns.length > 0) {
        violations.push({
            rule: 'return_consistency',
            severity: 'warning',
            message: 'Procedures have inconsistent return formats',
            suggestion: 'Use consistent SELECT @status AS status, @error AS error pattern'
        });
    }

    return violations;
}

/**
 * Generate improvement suggestions based on violations
 */
export function generateSuggestions(violations) {
    const suggestions = [];

    const criticalCount = violations.filter(v => v.severity === 'critical').length;
    const errorCount = violations.filter(v => v.severity === 'error').length;

    if (criticalCount > 0) {
        suggestions.push({
            priority: 'high',
            action: 'Fix critical security issues immediately',
            violations: violations.filter(v => v.severity === 'critical')
        });
    }

    if (errorCount > 0) {
        suggestions.push({
            priority: 'high',
            action: 'Fix SQL best practice violations',
            violations: violations.filter(v => v.severity === 'error')
        });
    }

    // Group suggestions by rule
    const byRule = violations.reduce((acc, v) => {
        acc[v.rule] = acc[v.rule] || [];
        acc[v.rule].push(v);
        return acc;
    }, {});

    for (const [rule, viols] of Object.entries(byRule)) {
        if (viols.length > 3) {
            suggestions.push({
                priority: 'medium',
                action: `Apply consistent fix for ${rule} (${viols.length} occurrences)`,
                suggestion: viols[0].suggestion
            });
        }
    }

    return suggestions;
}

// Helper functions
function findLineNumber(text, substring) {
    const index = text.indexOf(substring);
    if (index === -1) return null;
    return text.substring(0, index).split('\n').length;
}

function extractParameters(sql) {
    const params = [];
    const paramRegex = /@(\w+)\s+(\w+(?:\(\d+(?:,\d+)?\))?)/gi;
    let match;

    while ((match = paramRegex.exec(sql)) !== null) {
        params.push({
            name: '@' + match[1],
            type: match[2]
        });
    }

    return params;
}

function detectReturnFormat(sql) {
    if (/SELECT\s+@status\s+AS\s+status/i.test(sql)) {
        return 'status_error';
    }
    if (/RETURN\s+@/i.test(sql)) {
        return 'return_value';
    }
    if (/SELECT\s+\*/i.test(sql)) {
        return 'select_star';
    }
    return null;
}
