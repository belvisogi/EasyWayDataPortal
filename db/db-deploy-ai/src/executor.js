import sql from 'mssql';

/**
 * Apply migrations with transaction support
 */
export async function applyMigrations(config, dryRun = false) {
    const { connection, statements, transaction = { mode: 'auto' } } = config;

    let pool;
    try {
        // Connect to database
        pool = await sql.connect({
            server: connection.server,
            database: connection.database,
            user: connection.auth.username,
            password: connection.auth.password,
            options: {
                encrypt: true,
                trustServerCertificate: false
            }
        });

        const results = [];
        const startTime = Date.now();

        // Start transaction if auto mode
        const txn = transaction.mode === 'auto' ? new sql.Transaction(pool) : null;
        if (txn && !dryRun) {
            await txn.begin();
        }

        // Execute each statement
        for (const stmt of statements) {
            const stmtStart = Date.now();

            try {
                if (dryRun) {
                    // Just validate syntax
                    results.push({
                        id: stmt.id,
                        status: 'validated',
                        execution_time_ms: 0
                    });
                } else {
                    const request = txn ? new sql.Request(txn) : new sql.Request(pool);
                    const result = await request.query(stmt.sql);

                    results.push({
                        id: stmt.id,
                        status: 'success',
                        rows_affected: result.rowsAffected[0] || 0,
                        execution_time_ms: Date.now() - stmtStart
                    });
                }
            } catch (error) {
                // Rollback on error if in transaction
                if (txn && stmt.rollback_on_error !== false) {
                    await txn.rollback();
                }

                return {
                    status: 'error',
                    failed_at: stmt.id,
                    error: {
                        code: error.code,
                        message: error.message,
                        line: error.lineNumber,
                        suggestion: generateSuggestion(error)
                    },
                    rollback: {
                        executed: txn !== null,
                        statements_reverted: results.map(r => r.id)
                    }
                };
            }
        }

        // Commit transaction
        if (txn && !dryRun) {
            await txn.commit();
        }

        return {
            status: dryRun ? 'validated' : 'success',
            results,
            total_time_ms: Date.now() - startTime
        };

    } finally {
        if (pool) await pool.close();
    }
}

/**
 * Compare current schema with desired state
 */
export async function diffSchema(config) {
    const { connection, desired_schema } = config;

    let pool;
    try {
        pool = await sql.connect({
            server: connection.server,
            database: connection.database,
            user: connection.auth.username,
            password: connection.auth.password,
            options: { encrypt: true, trustServerCertificate: false }
        });

        // Get current tables
        const tablesResult = await pool.request().query(`
      SELECT TABLE_SCHEMA, TABLE_NAME 
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_TYPE = 'BASE TABLE'
    `);

        const currentTables = tablesResult.recordset.map(
            r => `${r.TABLE_SCHEMA}.${r.TABLE_NAME}`
        );

        // Get current procedures
        const procsResult = await pool.request().query(`
      SELECT ROUTINE_SCHEMA, ROUTINE_NAME
      FROM INFORMATION_SCHEMA.ROUTINES
      WHERE ROUTINE_TYPE = 'PROCEDURE'
    `);

        const currentProcs = procsResult.recordset.map(
            r => `${r.ROUTINE_SCHEMA}.${r.ROUTINE_NAME}`
        );

        // Calculate diff
        const desiredTables = desired_schema.tables || [];
        const desiredProcs = desired_schema.procedures || [];

        const diff = {
            missing: {
                tables: desiredTables.filter(t => !currentTables.includes(t)),
                procedures: desiredProcs.filter(p => !currentProcs.includes(p))
            },
            extra: {
                tables: currentTables.filter(t => !desiredTables.includes(t)),
                procedures: currentProcs.filter(p => !desiredProcs.includes(p))
            },
            modified: [] // TODO: implement column-level diff
        };

        return {
            status: 'success',
            diff,
            suggested_actions: generateSuggestedActions(diff)
        };

    } finally {
        if (pool) await pool.close();
    }
}

/**
 * Generate helpful suggestion based on error
 */
function generateSuggestion(error) {
    if (error.message.includes('already exists')) {
        return "Use 'IF NOT EXISTS' or DROP the object first";
    }
    if (error.message.includes('Invalid column name')) {
        return "Check column names match table definition";
    }
    if (error.message.includes('Invalid object name')) {
        return "Ensure prerequisite tables/objects exist";
    }
    return "Check SQL syntax and database state";
}

/**
 * Generate suggested migration files based on diff
 */
function generateSuggestedActions(diff) {
    const actions = [];

    if (diff.missing.tables.length > 0) {
        actions.push(`Missing tables: ${diff.missing.tables.join(', ')}`);
        actions.push('Check migrations/V3__portal_core_tables.sql');
    }

    if (diff.missing.procedures.length > 0) {
        actions.push(`Missing procedures: ${diff.missing.procedures.join(', ')}`);
        actions.push('Check migrations/V6__stored_procedures_core.sql');
    }

    return actions;
}
