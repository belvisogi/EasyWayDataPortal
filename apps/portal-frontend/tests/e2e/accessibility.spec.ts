import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { getPages } from './utils/pages';

test.describe('Inclusive Guardian ♿', () => {

    async function checkAccessibility(page, pageName) {

        await page.waitForLoadState('networkidle');

        // Inject axe-core and run analysis
        const accessibilityScanResults = await new AxeBuilder({ page })
            .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
            .analyze();

        // Log violations to console for easy debugging
        if (accessibilityScanResults.violations.length > 0) {
            console.log(`\n⚠️ ${pageName} Accessibility Violations:`);
            accessibilityScanResults.violations.forEach(violation => {
                console.log(`\n🔴 RULE: ${violation.id} (Impact: ${violation.impact})`);
                console.log(`   HELP: ${violation.help}`);
                violation.nodes.forEach(node => {
                    console.log(`   TARGET: ${node.target}`);
                    console.log(`   HTML: ${node.html.trim().substring(0, 100)}...`);
                });
            });
        }

        expect(accessibilityScanResults.violations).toEqual([]);
    }

    const pages = getPages();

    for (const pageInfo of pages) {
        test(`${pageInfo.id} should not have any automatically detectable accessibility issues`, async ({ page }) => {
            const url = pageInfo.route;
            console.log(`♿ Checking Accessibility for: ${url}`);
            await page.goto(url);
            await checkAccessibility(page, pageInfo.id);
        });
    }
});
