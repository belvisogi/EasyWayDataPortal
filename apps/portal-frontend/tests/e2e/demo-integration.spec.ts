
import { test, expect } from '@playwright/test';

test.describe('Demo Page Integration', () => {

    test.beforeEach(async ({ page }) => {
        await page.goto('/demo.html');
    });

    test('should load all sovereign components', async ({ page }) => {
        await expect(page.locator('sovereign-header')).toBeVisible();
        await expect(page.locator('sovereign-footer')).toBeVisible();
        await expect(page.locator('sovereign-cookie-banner')).toBeVisible();

        // Form specific
        await expect(page.locator('#sel-company-size')).toBeVisible();
        await expect(page.locator('#sel-interest')).toBeVisible();
        await expect(page.locator('#date-demo')).toBeVisible();
    });

    test('should fill form using sovereign components and submit', async ({ page }) => {
        // 0. Handle Cookie Banner (It overlays the bottom, might block button or just be annoying)
        const banner = page.locator('sovereign-cookie-banner');
        if (await banner.isVisible()) {
            await banner.getByRole('button', { name: 'Accept All' }).click();
            await expect(banner).toBeHidden();
        }

        // 1. Fill Text Inputs
        await page.locator('input[name="firstName"]').fill('Sovereign');
        await page.locator('input[name="lastName"]').fill('Agent');
        await page.locator('input[name="company"]').fill('Valentino Inc');
        await page.locator('input[name="email"]').fill('agent@valentino.ai');
        await page.locator('input[name="jobTitle"]').fill('Architect');

        // 2. Interact with Sovereign Select (Company Size)
        const sizeSelect = page.locator('#sel-company-size');
        await sizeSelect.click(); // Open dropdown
        await sizeSelect.locator('.option').filter({ hasText: '11-50' }).click();
        await expect(sizeSelect).toContainText('11-50');

        // 3. Interact with Sovereign Select (Interest)
        const interestSelect = page.locator('#sel-interest');
        await interestSelect.click();
        await interestSelect.locator('.option').filter({ hasText: 'Vector Memory' }).click();
        await expect(interestSelect).toContainText('Vector Memory');

        // 4. Interact with Sovereign Datepicker
        const datepicker = page.locator('#date-demo');
        // Click random day
        const dayToPick = datepicker.locator('.day:not(.empty)').first();
        await dayToPick.click();

        // 5. Checkbox (Specific to form to avoid Cookie Banner toggles ambiguity)
        await page.locator('#demo-form input[type="checkbox"]').check();

        // 6. Submit
        // We mock the route to ensure success/failure is deterministic if we wanted, 
        // but the code handles 404/failure by showing a "Simulated Mode" toast.
        // So we just expect A TOAST.
        await page.click('button[type="submit"]');

        // 7. Verify Toaster
        const toaster = page.locator('sovereign-toaster');
        const toast = toaster.locator('.toast');
        await expect(toast).toBeVisible();

        // Content should signal success (either real or simulated)
        // "Success! Your request..." or "Request Recieved! (Simulated Mode)"
        await expect(toast).toContainText(/Success|Received/i);
    });

});
