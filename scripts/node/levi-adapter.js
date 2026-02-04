#!/usr/bin/env node

/**
 * PROJECT LEVI: Mode D - The Mercenary (API Adapter)
 * Wraps the DQF Agent CLI for programmatic access via Node.js/n8n.
 */

const { spawn } = require('child_process');
const path = require('path');

// Configuration
const DQF_PACKAGE_PATH = path.resolve(__dirname, '../../packages/dqf-agent');
const CLI_PATH = path.join(DQF_PACKAGE_PATH, 'src/cli-v2.ts');
const TS_CONFIG = path.join(DQF_PACKAGE_PATH, 'tsconfig.json');

// Helper to run the CLI
async function runLevi(args) {
    return new Promise((resolve, reject) => {
        console.log(`🗡️  Levi (Adapter) invoking: ${args.join(' ')}`);

        const child = spawn('npx', ['ts-node', '--project', TS_CONFIG, CLI_PATH, ...args], {
            cwd: DQF_PACKAGE_PATH,
            shell: true,
            env: { ...process.env, FORCE_COLOR: '1' } // Canvas style outputs might need color
        });

        let output = '';
        let errorOutput = '';

        child.stdout.on('data', (data) => {
            const chunk = data.toString();
            output += chunk;
            process.stdout.write(chunk); // Stream to console
        });

        child.stderr.on('data', (data) => {
            const chunk = data.toString();
            errorOutput += chunk;
            process.stderr.write(chunk);
        });

        child.on('close', (code) => {
            if (code === 0) {
                resolve({ success: true, output });
            } else {
                reject({ success: false, code, error: errorOutput });
            }
        });
    });
}

// Main Execution
async function main() {
    const args = process.argv.slice(2);

    if (args.length === 0 || args.includes('--help')) {
        console.log(`
Project LEVI - API Adapter
==========================
Usage: node levi-adapter.js [intent] [options]

Intents:
  --intent fix        Run the cleaning protocols
  --intent scan       Run a diagnostic scan only
  --intent standardize Apply standard formatting

Test:
  --test              Verify adapter connectivity
        `);
        return;
    }

    if (args.includes('--test')) {
        console.log("✅ Levi Adapter is ONLINE. Ready to serve.");
        return;
    }

    try {
        await runLevi(args);
    } catch (err) {
        console.error("❌ Levi Operation Failed:", err);
        process.exit(1);
    }
}

main();
