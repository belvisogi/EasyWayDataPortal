import sql from 'mssql';

/**
 * Reverse Engineer Database to Blueprint JSON
 */
export async function generateBlueprint(config) {
    const { connection, options = {} } = config;
    let pool;

    try {
        console.log(`Connecting to ${connection.server}/${connection.database}...`);

        pool = await sql.connect({
            server: connection.server,
            database: connection.database,
            user: connection.auth.username,
            password: connection.auth.password,
            options: {
                encrypt: true,
                trustServerCertificate: true // Dev friendly
            }
        });

        // 1. Get Tables
        const tablesResult = await pool.request().query(`
            SELECT 
                t.TABLE_SCHEMA, 
                t.TABLE_NAME,
                ep.value as [Description]
            FROM INFORMATION_SCHEMA.TABLES t
            LEFT JOIN sys.extended_properties ep ON 
                ep.major_id = OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME) 
                AND ep.minor_id = 0 
                AND ep.name = 'MS_Description'
            WHERE t.TABLE_TYPE = 'BASE TABLE'
            ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME
        `);

        const blueprint = {
            metadata: {
                name: connection.database,
                version: "1.0.0",
                generated_at: new Date().toISOString(),
                compatibility_level: 150
            },
            tables: []
        };

        for (const row of tablesResult.recordset) {
            const schema = row.TABLE_SCHEMA;
            const table = row.TABLE_NAME;
            const description = row.Description || "";

            // 2. Get Columns
            const columnsResult = await pool.request()
                .input('schema', sql.NVarChar, schema)
                .input('table', sql.NVarChar, table)
                .query(`
                SELECT 
                    COLUMN_NAME, 
                    DATA_TYPE, 
                    CHARACTER_MAXIMUM_LENGTH,
                    IS_NULLABLE, 
                    COLUMN_DEFAULT
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @table
                ORDER BY ORDINAL_POSITION
            `);

            // 3. Get Indexes & Constraints
            const indexesResult = await pool.request()
                .input('schema', sql.NVarChar, schema)
                .input('table', sql.NVarChar, table)
                .query(`
                SELECT 
                    i.name AS index_name,
                    i.is_unique,
                    i.is_primary_key,
                    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS columns
                FROM sys.indexes i
                JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
                JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                JOIN sys.objects o ON i.object_id = o.object_id
                JOIN sys.schemas s ON o.schema_id = s.schema_id
                WHERE s.name = @schema AND o.name = @table
                GROUP BY i.name, i.is_unique, i.is_primary_key
            `);

            const columns = columnsResult.recordset.map(col => ({
                name: col.COLUMN_NAME,
                type: formatType(col.DATA_TYPE, col.CHARACTER_MAXIMUM_LENGTH),
                nullable: col.IS_NULLABLE === 'YES',
                default: col.COLUMN_DEFAULT ? cleanDefault(col.COLUMN_DEFAULT) : undefined,
                primary_key: indexesResult.recordset.some(idx => idx.is_primary_key && idx.columns === col.COLUMN_NAME)
            }));

            const indexes = indexesResult.recordset
                .filter(idx => !idx.is_primary_key) // PKs handled in columns
                .map(idx => ({
                    name: idx.index_name,
                    unique: idx.is_unique,
                    columns: idx.columns.split(', ')
                }));

            blueprint.tables.push({
                schema,
                name: table,
                description,
                columns,
                indexes: indexes.length > 0 ? indexes : undefined
            });
        }

        return blueprint;

    } finally {
        if (pool) await pool.close();
    }
}

// Helpers
function formatType(dataType, maxLength) {
    if (['nvarchar', 'varchar', 'char', 'nchar'].includes(dataType)) {
        return `${dataType}(${maxLength === -1 ? 'MAX' : maxLength})`;
    }
    return dataType;
}

function cleanDefault(def) {
    // Remove parens ((0)) -> 0
    let clean = def;
    while (clean.startsWith('(') && clean.endsWith(')')) {
        clean = clean.substring(1, clean.length - 1);
    }
    return clean;
}
