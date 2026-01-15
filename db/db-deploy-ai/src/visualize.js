#!/usr/bin/env node
import { writeFile } from 'fs/promises';
import { generateERDiagram, generateD2Diagram, generateHTMLDocs } from './visualizer.js';
import chalk from 'chalk';

const blueprintPath = process.argv[2] || '../schema/easyway-portal.blueprint.json';
const format = process.argv[3] || 'mermaid';

console.log(chalk.cyan(`📊 Generating ${format} visualization from blueprint...\n`));

try {
    let output;
    let filename;

    switch (format) {
        case 'mermaid':
            output = await generateERDiagram(blueprintPath);
            filename = 'schema-diagram.mmd';
            console.log(chalk.green('✅ Mermaid ER Diagram generated!'));
            console.log(chalk.dim('   View at: https://mermaid.live'));
            break;

        case 'd2':
            output = await generateD2Diagram(blueprintPath);
            filename = 'schema-diagram.d2';
            console.log(chalk.green('✅ D2 Diagram generated!'));
            console.log(chalk.dim('   Render with: d2 schema-diagram.d2 schema.svg'));
            break;

        case 'html':
            output = await generateHTMLDocs(blueprintPath);
            filename = 'schema-docs.html';
            console.log(chalk.green('✅ HTML Documentation generated!'));
            console.log(chalk.dim('   Open in browser: schema-docs.html'));
            break;

        default:
            console.error(chalk.red(`Unknown format: ${format}`));
            console.log('Available formats: mermaid, d2, html');
            process.exit(1);
    }

    await writeFile(filename, output);
    console.log(chalk.bold(`\nSaved to: ${filename}\n`));

    // Also output to stdout for piping
    console.log(output);

} catch (error) {
    console.error(chalk.red('Error:'), error.message);
    process.exit(1);
}
