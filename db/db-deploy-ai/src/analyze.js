#!/usr/bin/env node
import { readFile, readdir } from 'fs/promises';
import { join } from 'path';
import chalk from 'chalk';
import { validateSQL, validateConsistency, generateSuggestions } from './validator.js';

async function main() {
    console.log(chalk.bold.cyan('🔍 Analyzing Database Stored Procedures\n'));

    const migrationsDir = join(process.cwd(), '..', 'migrations');
    const files = await readdir(migrationsDir);
    const sqlFiles = files.filter(f => f.endsWith('.sql'));

    const allProcedures = [];
    const allViolations = [];

    // Analyze each file
    for (const file of sqlFiles) {
        const filePath = join(migrationsDir, file);
        const content = await readFile(filePath, 'utf-8');

        // Extract procedures from file
        const procMatches = content.matchAll(/CREATE\s+(OR\s+ALTER\s+)?PROCEDURE\s+(\w+\.)(\w+)([\s\S]*?)(?=CREATE\s+(OR\s+ALTER\s+)?PROCEDURE|$)/gi);

        for (const match of procMatches) {
            const procName = match[3];
            const procSQL = match[0];

            console.log(chalk.dim(`Analyzing ${procName}...`));

            const result = await validateSQL(procSQL, 'procedure');

            allProcedures.push({
                name: procName,
                file,
                sql: procSQL
            });

            if (result.violations.length > 0) {
                allViolations.push({
                    procedure: procName,
                    file,
                    violations: result.violations
                });
            }
        }
    }

    console.log('\n' + '='.repeat(60));
    console.log(chalk.bold('📊 ANALYSIS REPORT\n'));

    // Summary
    const totalProcs = allProcedures.length;
    const procsWithIssues = allViolations.length;
    const totalIssues = allViolations.reduce((sum, p) => sum + p.violations.length, 0);

    console.log(chalk.bold('Summary:'));
    console.log(`  Total Procedures: ${totalProcs}`);
    console.log(`  Procedures with issues: ${chalk.yellow(procsWithIssues)}`);
    console.log(`  Total issues found: ${chalk.red(totalIssues)}\n`);

    // Issue breakdown by severity
    const allIssues = allViolations.flatMap(p => p.violations);
    const critical = allIssues.filter(v => v.severity === 'critical').length;
    const errors = allIssues.filter(v => v.severity === 'error').length;
    const warnings = allIssues.filter(v => v.severity === 'warning').length;
    const info = allIssues.filter(v => v.severity === 'info').length;

    console.log(chalk.bold('By Severity:'));
    if (critical > 0) console.log(`  ${chalk.red.bold('CRITICAL')}: ${critical}`);
    if (errors > 0) console.log(`  ${chalk.red('ERROR')}: ${errors}`);
    if (warnings > 0) console.log(`  ${chalk.yellow('WARNING')}: ${warnings}`);
    if (info > 0) console.log(`  ${chalk.blue('INFO')}: ${info}\n`);

    // Detailed violations
    if (allViolations.length > 0) {
        console.log(chalk.bold('\n📋 Detailed Issues:\n'));

        for (const proc of allViolations) {
            console.log(chalk.bold.yellow(`${proc.procedure}`) + chalk.dim(` (${proc.file})`));

            for (const violation of proc.violations) {
                const severityColor = {
                    critical: chalk.red.bold,
                    error: chalk.red,
                    warning: chalk.yellow,
                    info: chalk.blue
                }[violation.severity] || chalk.gray;

                console.log(`  ${severityColor(`[${violation.severity.toUpperCase()}]`)} ${violation.message}`);
                if (violation.line) {
                    console.log(`    └─ Line ${violation.line}`);
                }
                if (violation.suggestion) {
                    console.log(`    💡 ${chalk.dim(violation.suggestion)}`);
                }
            }
            console.log('');
        }
    }

    // Consistency check
    console.log(chalk.bold('\n🔗 Consistency Analysis:\n'));
    const consistencyViolations = validateConsistency(allProcedures);

    if (consistencyViolations.length === 0) {
        console.log(chalk.green('✅ All procedures follow consistent patterns\n'));
    } else {
        for (const violation of consistencyViolations) {
            console.log(`  ${chalk.yellow('[WARNING]')} ${violation.message}`);
            if (violation.procedure) {
                console.log(`    └─ Procedure: ${violation.procedure}`);
            }
            if (violation.suggestion) {
                console.log(`    💡 ${chalk.dim(violation.suggestion)}`);
            }
        }
        console.log('');
    }

    // Generate suggestions
    console.log(chalk.bold('\n💡 Recommendations:\n'));
    const suggestions = generateSuggestions(allIssues);

    for (const suggestion of suggestions) {
        const priorityColor = {
            high: chalk.red,
            medium: chalk.yellow,
            low: chalk.blue
        }[suggestion.priority] || chalk.gray;

        console.log(`${priorityColor(`[${suggestion.priority.toUpperCase()}]`)} ${suggestion.action}`);
        if (suggestion.suggestion) {
            console.log(`  └─ ${chalk.dim(suggestion.suggestion)}`);
        }
    }

    // Generate JSON report
    const report = {
        timestamp: new Date().toISOString(),
        summary: {
            total_procedures: totalProcs,
            procedures_with_issues: procsWithIssues,
            total_issues: totalIssues,
            by_severity: { critical, errors, warnings, info }
        },
        violations: allViolations,
        consistency: consistencyViolations,
        suggestions
    };

    console.log(chalk.dim(`\n\nFull report saved to: analysis-report.json\n`));

    await writeFile(
        join(process.cwd(), 'analysis-report.json'),
        JSON.stringify(report, null, 2)
    );

    // Exit code
    process.exit(critical > 0 || errors > 0 ? 1 : 0);
}

main().catch(console.error);
