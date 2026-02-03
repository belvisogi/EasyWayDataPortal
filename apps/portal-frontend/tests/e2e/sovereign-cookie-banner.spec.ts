
import { test, expect } from '@playwright/test';

test.describe('The Gatekeeper (Sovereign Cookie Banner)', () => {

    test.beforeEach(async ({ page }) => {
        // Clear local storage before each test to simulate fresh visit
        await page.goto('/test-cookie.html'); // Need to load a page to access context storage? 
        // Actually, clearer to use addInitScript or just clear after load if the banner logic handles updates? 
        // Better: Clear storage, then reload.
        await page.evaluate(() => localStorage.clear());
        await page.reload();
    });

    test('should show banner on fresh visit', async ({ page }) => {
        // Banner extends HTMLElement, shadow root?
        const banner = page.locator('sovereign-cookie-banner');
        const header = banner.getByText('Sovereign Privacy'); // Playwright pierces shadow? Yes usually.

        await expect(header).toBeVisible();
    });

    test('should accept all and save to storage', async ({ page }) => {
        const banner = page.locator('sovereign-cookie-banner');

        await banner.getByRole('button', { name: 'Accept All' }).click();

        // Banner should disappear
        await expect(banner.getByText('Sovereign Privacy')).toBeHidden();

        // Check storage
        const consent = await page.evaluate(() => JSON.parse(localStorage.getItem('sovereign-consent') || '{}'));
        expect(consent.analytics).toBe(true);
        expect(consent.marketing).toBe(true);

        // Check visual indicator on test page
        const analyticsIndicator = page.locator('#status-analytics .indicator');
        await expect(analyticsIndicator).toHaveClass(/on/);
    });

    test('should reject all', async ({ page }) => {
        const banner = page.locator('sovereign-cookie-banner');
        await banner.getByRole('button', { name: 'Reject All' }).click();

        const consent = await page.evaluate(() => JSON.parse(localStorage.getItem('sovereign-consent') || '{}'));
        expect(consent.analytics).toBe(false);
        expect(consent.marketing).toBe(false);
    });

    test('should customize preferences', async ({ page }) => {
        const banner = page.locator('sovereign-cookie-banner');
        await banner.getByRole('button', { name: 'Customize' }).click();

        // Check toggles (checkboxes)
        // Note: They are in shadow DOM.
        // Let's assume we want to enable Analytics but not Marketing.

        // Find the checkbox for analytics. It's inside label .switch
        // IDs: chk-analytics
        const chkAnalytics = banner.locator('#chk-analytics');
        await chkAnalytics.check(); // Set to true

        const chkMarketing = banner.locator('#chk-marketing');
        await expect(chkMarketing).not.toBeChecked();

        await banner.getByRole('button', { name: 'Save Preferences' }).click();

        const consent = await page.evaluate(() => JSON.parse(localStorage.getItem('sovereign-consent') || '{}'));
        expect(consent.analytics).toBe(true);
        expect(consent.marketing).toBe(false);
    });

});
