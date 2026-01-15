#!/usr/bin/env node
import { program } from 'commander';
import chalk from 'chalk';
import { applyMigrations, validateMigrations, diffSchema } from './executor.js';

program
    .name('db-deploy')
    .description('AI-friendly database migration tool')
    .version('0.1.0');

// Apply command
program
    .command('apply')
    .description('Apply SQL migrations')
    .option('-i, --input <file>', 'JSON input file with migrations')
    .option('--dry-run', 'Validate without executing')
    .action(async (options) => {
        try {
            const config = options.input
                ? JSON.parse(await fs.readFile(options.input, 'utf-8'))
                : JSON.parse(await readStdin());

            const result = await applyMigrations(config, options.dryRun);

            console.log(JSON.stringify(result, null, 2));

            if (result.status === 'success') {
                console.error(chalk.green('✅ Migrations applied successfully'));
                process.exit(0);
            } else {
                console.error(chalk.red(`❌ Error: ${result.error.message}`));
                process.exit(1);
            }
        } catch (error) {
            console.error(JSON.stringify({
                status: 'error',
                error: { message: error.message, stack: error.stack }
            }, null, 2));
            process.exit(1);
        }
    });

// Diff command
program
    .command('diff')
    .description('Compare current schema with desired state')
    .option('-i, --input <file>', 'JSON input file with desired schema')
    .action(async (options) => {
        try {
            const config = options.input
                ? JSON.parse(await fs.readFile(options.input, 'utf-8'))
                : JSON.parse(await readStdin());

            const result = await diffSchema(config);
            console.log(JSON.stringify(result, null, 2));
            process.exit(0);
        } catch (error) {
            console.error(JSON.stringify({
                status: 'error',
                error: { message: error.message }
            }, null, 2));
            process.exit(1);
        }
    });

program.parse();

// Helper to read from stdin
async function readStdin() {
    const chunks = [];
    for await (const chunk of process.stdin) chunks.push(chunk);
    return Buffer.concat(chunks).toString('utf-8');
}
