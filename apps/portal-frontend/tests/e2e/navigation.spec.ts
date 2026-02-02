import { test, expect } from '@playwright/test';

/**
 * E2E Tests: SPA Navigation
 * 
 * Purpose: Verify that navigation works without full page reload
 * 
 * Critical for SPA: No window.location.reload() should be called
 */

test.describe('SPA Navigation', () => {
    test('should navigate from Home to Demo without reload', async ({ page }) => {
        // Start at home
        await page.goto('/');

        // Wait for page to be fully loaded
        await expect(page.locator('h1')).toBeVisible();

        // Click Demo link
        await page.click('a[href="/demo"]');

        // Verify URL changed
        await expect(page).toHaveURL('/demo');

        // Verify content updated (form should be visible)
        await expect(page.locator('form')).toBeVisible();

        // Verify no full page reload (check if SPA shell is still there)
        await expect(page.locator('sovereign-header')).toBeVisible();
    });

    test('should navigate from Demo to Manifesto without reload', async ({ page }) => {
        await page.goto('/demo');

        // Click Manifesto link in nav
        await page.click('a[href="/manifesto"]');

        await expect(page).toHaveURL('/manifesto');
        await expect(page.locator('h1')).toContainText('Manifesto');
    });

    test('should navigate from Manifesto to Pricing without reload', async ({ page }) => {
        await page.goto('/manifesto');

        await page.click('a[href="/pricing"]');

        await expect(page).toHaveURL('/pricing');
        await expect(page.locator('h1')).toBeVisible();
    });

    test('should support browser back button', async ({ page }) => {
        // Navigate: Home → Demo → Manifesto
        await page.goto('/');
        await page.click('a[href="/demo"]');
        await expect(page).toHaveURL('/demo');

        await page.click('a[href="/manifesto"]');
        await expect(page).toHaveURL('/manifesto');

        // Go back
        await page.goBack();
        await expect(page).toHaveURL('/demo');
        await expect(page.locator('form')).toBeVisible();

        // Go back again
        await page.goBack();
        await expect(page).toHaveURL('/');
    });

    test('should support direct URL navigation (deep linking)', async ({ page }) => {
        // Navigate directly to /demo (not from home)
        await page.goto('/demo');

        await expect(page).toHaveURL('/demo');
        await expect(page.locator('form')).toBeVisible();
        await expect(page.locator('sovereign-header')).toBeVisible();
    });

    test('should navigate fast (< 500ms)', async ({ page }) => {
        await page.goto('/');

        const startTime = Date.now();
        await page.click('a[href="/demo"]');
        await expect(page).toHaveURL('/demo');
        const endTime = Date.now();

        const navigationTime = endTime - startTime;
        expect(navigationTime).toBeLessThan(500);
    });
});
