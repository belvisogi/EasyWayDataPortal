#!/usr/bin/env node
import { program } from 'commander';
import chalk from 'chalk';
import { writeFile } from 'fs/promises';
import { resolve } from 'path';
import 'dotenv/config';
import { generateBlueprint } from './blueprint-generator.js';

program
    .name('db-blueprint')
    .description('Database Blueprint Generator & Manager')
    .version('0.1.0');

program
    .command('generate')
    .description('Generate Blueprint JSON from existing database')
    .option('-o, --output <file>', 'Output JSON file', 'blueprint.json')
    .option('--server <server>', 'Database server')
    .option('--database <database>', 'Database name')
    .option('--user <user>', 'Database user')
    .option('--password <password>', 'Database password')
    .action(async (options) => {
        try {
            console.log(chalk.blue('🏗️  Starting Blueprint Generation...'));

            // Config priority: Flags > Env Vars
            const config = {
                connection: {
                    server: options.server || process.env.DB_SERVER || 'localhost',
                    database: options.database || process.env.DB_DATABASE,
                    auth: {
                        username: options.user || process.env.DB_USER,
                        password: options.password || process.env.DB_PASSWORD
                    }
                }
            };

            if (!config.connection.database) {
                console.error(chalk.red('❌ Error: Database name required (use --database or DB_DATABASE env)'));
                process.exit(1);
            }

            const blueprint = await generateBlueprint(config);

            const outputPath = resolve(process.cwd(), options.output);
            await writeFile(outputPath, JSON.stringify(blueprint, null, 2));

            console.log(chalk.green(`\n✅ Blueprint generated successfully at:`));
            console.log(chalk.bold(outputPath));

            // Statistics
            const tableCount = blueprint.tables.length;
            console.log(chalk.dim(`\nStats: ${tableCount} tables retrieved.`));

        } catch (error) {
            console.error(chalk.red(`\n❌ Fatal Error:`));
            console.error(error.message);
            process.exit(1);
        }
    });

program.parse();
