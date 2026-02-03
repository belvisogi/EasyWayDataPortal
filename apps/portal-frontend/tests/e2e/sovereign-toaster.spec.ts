
import { test, expect } from '@playwright/test';

test.describe('The Herald (Sovereign Toaster)', () => {

    test.beforeEach(async ({ page }) => {
        await page.goto('/test-toaster.html');
    });

    test('should show success toast', async ({ page }) => {
        const toaster = page.locator('sovereign-toaster');

        await page.click('button.btn-success');

        // Check inside shadow DOM
        // Note: Playwright locators automatically pierce shadow roots, but let's be specific for clarity if needed.
        // Or just look for text.
        const toast = toaster.locator('.toast.success');
        await expect(toast).toBeVisible();
        await expect(toast).toContainText('Operation completed successfully!');
    });

    test('should show error toast', async ({ page }) => {
        const toaster = page.locator('sovereign-toaster');
        await page.click('button.btn-error');
        const toast = toaster.locator('.toast.error');
        await expect(toast).toBeVisible();
    });

    test('should show action toast and handle click', async ({ page }) => {
        const toaster = page.locator('sovereign-toaster');

        // Define dialog handler before triggering alert
        page.on('dialog', dialog => {
            expect(dialog.message()).toBe('Installing update...');
            dialog.accept();
        });

        await page.click('button.btn-warning');

        const actionBtn = toaster.locator('.action-btn');
        await expect(actionBtn).toBeVisible();
        await actionBtn.click();

        // Toast should disappear after action (logic in component)
        const toast = toaster.locator('.toast.warning');
        // It animates out, having class 'hiding' first.
        // Eventually it should be detached.
        await expect(toast).not.toBeVisible();
    });

    test('should stack multiple toasts', async ({ page }) => {
        const toaster = page.locator('sovereign-toaster');

        // Click multiple times
        await page.click('button.btn-success');
        await page.click('button.btn-error');

        // Should have 2 toasts
        await expect(toaster.locator('.toast')).toHaveCount(2);
    });

});
