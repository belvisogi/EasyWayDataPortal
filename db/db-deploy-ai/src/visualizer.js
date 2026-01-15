import { readFile } from 'fs/promises';

/**
 * Generate Mermaid ER Diagram from Blueprint
 */
export async function generateERDiagram(blueprintPath) {
    const blueprint = JSON.parse(await readFile(blueprintPath, 'utf-8'));

    let mermaid = 'erDiagram\n\n';

    // Add table definitions
    for (const table of blueprint.tables || []) {
        const tableName = `${table.schema}_${table.name}`;

        mermaid += `  ${tableName} {\n`;

        for (const column of table.columns || []) {
            const type = column.type.replace(/\(.*\)/, ''); // Remove size
            const pk = column.primary_key ? ' PK' : '';
            const fk = column.name.endsWith('_id') && !column.primary_key ? ' FK' : '';
            const nullable = column.nullable === false ? ' "NOT NULL"' : '';

            mermaid += `    ${type} ${column.name}${pk}${fk}${nullable}\n`;
        }

        mermaid += `  }\n\n`;
    }

    // Add relationships (inferred from foreign keys)
    for (const table of blueprint.tables || []) {
        const tableName = `${table.schema}_${table.name}`;

        // Infer relationships from column names
        for (const column of table.columns || []) {
            if (column.name.endsWith('_id') && !column.primary_key) {
                const refTable = column.name.replace('_id', '').toUpperCase();
                const refTableFull = `${table.schema}_${refTable}`;

                // Check if referenced table exists
                const exists = blueprint.tables.some(
                    t => t.name === refTable || t.name === refTable + 'S'
                );

                if (exists) {
                    const actualRef = blueprint.tables.find(
                        t => t.name === refTable || t.name === refTable + 'S'
                    );
                    const actualRefName = `${actualRef.schema}_${actualRef.name}`;

                    // Determine relationship type
                    const isUnique = table.indexes?.some(
                        idx => idx.unique && idx.columns.includes(column.name)
                    );

                    const relType = isUnique ? '||--||' : '}o--||';
                    mermaid += `  ${actualRefName} ${relType} ${tableName} : "has"\n`;
                }
            }
        }
    }

    return mermaid;
}

/**
 * Generate D2 Diagram (alternative to Mermaid)
 */
export async function generateD2Diagram(blueprintPath) {
    const blueprint = JSON.parse(await readFile(blueprintPath, 'utf-8'));

    let d2 = '# Database Schema\n\n';

    for (const table of blueprint.tables || []) {
        const tableName = `${table.schema}.${table.name}`;

        d2 += `${tableName}: {\n`;
        d2 += `  shape: sql_table\n`;

        for (const column of table.columns || []) {
            const constraint = column.primary_key ? ' 🔑' :
                column.nullable === false ? ' *' : '';
            d2 += `  ${column.name}: ${column.type}${constraint}\n`;
        }

        d2 += `}\n\n`;
    }

    // Add relationships
    for (const table of blueprint.tables || []) {
        const tableName = `${table.schema}.${table.name}`;

        for (const column of table.columns || []) {
            if (column.name.endsWith('_id') && !column.primary_key) {
                const refTable = column.name.replace('_id', '').toUpperCase();
                const actualRef = blueprint.tables.find(
                    t => t.name === refTable || t.name === refTable + 'S'
                );

                if (actualRef) {
                    const refName = `${actualRef.schema}.${actualRef.name}`;
                    d2 += `${refName} -> ${tableName}: ${column.name}\n`;
                }
            }
        }
    }

    return d2;
}

/**
 * Generate HTML Table Documentation
 */
export async function generateHTMLDocs(blueprintPath) {
    const blueprint = JSON.parse(await readFile(blueprintPath, 'utf-8'));

    let html = `<!DOCTYPE html>
<html>
<head>
  <title>${blueprint.metadata.name} - Schema Documentation</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 40px; }
    h1 { color: #333; }
    h2 { color: #0066cc; margin-top: 40px; }
    table { border-collapse: collapse; width: 100%; margin: 20px 0; }
    th { background: #0066cc; color: white; padding: 12px; text-align: left; }
    td { padding: 10px; border-bottom: 1px solid #ddd; }
    .pk { color: #d4af37; font-weight: bold; }
    .fk { color: #4a90e2; }
    .nullable { color: #999; }
    .description { color: #666; font-style: italic; }
  </style>
</head>
<body>
  <h1>${blueprint.metadata.name}</h1>
  <p>${blueprint.metadata.description || ''}</p>
  <p><small>Version: ${blueprint.metadata.version} | Compatibility: SQL Server ${blueprint.metadata.compatibility_level}</small></p>
`;

    for (const table of blueprint.tables || []) {
        html += `<h2>${table.schema}.${table.name}</h2>\n`;
        html += `<p class="description">${table.description || ''}</p>\n`;
        html += `<table>\n`;
        html += `  <tr><th>Column</th><th>Type</th><th>Constraints</th><th>Description</th></tr>\n`;

        for (const column of table.columns || []) {
            const constraints = [];
            if (column.primary_key) constraints.push('<span class="pk">PRIMARY KEY</span>');
            if (column.identity) constraints.push('IDENTITY');
            if (column.nullable === false) constraints.push('NOT NULL');
            if (column.default) constraints.push(`DEFAULT ${column.default}`);
            if (column.name.endsWith('_id') && !column.primary_key) {
                constraints.push('<span class="fk">FOREIGN KEY</span>');
            }

            html += `  <tr>
    <td><strong>${column.name}</strong></td>
    <td>${column.type}</td>
    <td>${constraints.join(', ')}</td>
    <td class="description">${column.description || ''}</td>
  </tr>\n`;
        }

        html += `</table>\n`;

        // Indexes
        if (table.indexes && table.indexes.length > 0) {
            html += `<p><strong>Indexes:</strong></p><ul>\n`;
            for (const index of table.indexes) {
                const type = index.unique ? 'UNIQUE' : 'INDEX';
                html += `  <li>${type}: ${index.name} (${index.columns.join(', ')})</li>\n`;
            }
            html += `</ul>\n`;
        }
    }

    html += `</body></html>`;
    return html;
}
