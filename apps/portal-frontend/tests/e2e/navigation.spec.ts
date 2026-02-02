import { test, expect } from '@playwright/test';

/**
 * E2E Tests: SPA Navigation (Hardened)
 * 
 * Verified Strategy:
 * 1. Use waitForLoadState('networkidle') to ensure assets/manifests are loaded
 * 2. Check for shadow host presence first
 * 3. Verify URL changes
 */

test.describe('SPA Navigation', () => {
    test('should load home page successfully', async ({ page }) => {
        await page.goto('/');
        await page.waitForLoadState('networkidle');

        // Verify SPA shell is present (Sovereign Header is a web component)
        await expect(page.locator('sovereign-header')).toBeAttached();
        await expect(page.locator('main')).toBeVisible();
    });

    test('should load demo page directly', async ({ page }) => {
        await page.goto('/demo');
        await page.waitForLoadState('networkidle');

        await expect(page).toHaveURL(/\/demo/); // Regex allows trailing slash flexibility
        await expect(page.locator('sovereign-header')).toBeAttached();
        await expect(page.locator('form')).toBeVisible();
    });

    test('should load manifesto page directly', async ({ page }) => {
        await page.goto('/manifesto');
        await page.waitForLoadState('networkidle');

        await expect(page).toHaveURL(/\/manifesto/);
        await expect(page.locator('sovereign-header')).toBeAttached();
    });

    test('should load pricing page directly', async ({ page }) => {
        await page.goto('/pricing');
        await page.waitForLoadState('networkidle');

        await expect(page).toHaveURL(/\/pricing/);
    });

    test('should load demo-components page directly', async ({ page }) => {
        // Increase timeout for heavy page
        test.setTimeout(60000);

        await page.goto('/demo-components');
        await page.waitForLoadState('networkidle');

        await expect(page).toHaveURL(/\/demo-components/);
        await expect(page.locator('.showcase-intro')).toBeVisible({ timeout: 30000 });
    });
});
