import { test, expect } from '@playwright/test';
import { getPages } from './utils/pages';

test.describe('Visual Guardian 👁️', () => {
    const pages = getPages();

    for (const pageInfo of pages) {
        test(`${pageInfo.id} should match snapshot`, async ({ page }) => {
            const url = pageInfo.route;
            console.log(`📸 Taking snapshot for: ${url}`);

            await page.goto(url);
            await page.waitForLoadState('networkidle');

            // Wait for fonts or animations safely
            await page.waitForTimeout(500);

            await expect(page).toHaveScreenshot(`${pageInfo.id}.png`, { fullPage: true });
        });
    }
});
