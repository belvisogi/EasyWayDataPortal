import { test, expect } from '@playwright/test';

/**
 * E2E Test: Minimal Smoke Test
 * 
 * Purpose: Verify that the application loads successfully
 * 
 * This is the MINIMAL test to verify E2E testing works.
 * Uses only the most basic assertions that should always pass.
 */

test.describe('Application Smoke Test', () => {
    test('should load home page successfully', async ({ page }) => {
        // Navigate to home page
        await page.goto('/');

        // Wait for page to load (give it plenty of time)
        await page.waitForLoadState('networkidle');

        // Verify URL is correct
        expect(page.url()).toContain('localhost:5173');

        // Verify page has a title (any title is fine)
        const title = await page.title();
        expect(title).toBeTruthy();
        expect(title.length).toBeGreaterThan(0);

        // Verify page has some content (HTML is not empty)
        const bodyText = await page.locator('body').textContent();
        expect(bodyText).toBeTruthy();
        expect(bodyText!.length).toBeGreaterThan(0);
    });
});
