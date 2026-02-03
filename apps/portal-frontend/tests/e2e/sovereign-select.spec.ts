
import { test, expect } from '@playwright/test';

test.describe('The Selector (Sovereign Select)', () => {

    test.beforeEach(async ({ page }) => {
        await page.goto('/test-select.html');
    });

    test('should render single select', async ({ page }) => {
        const select = page.locator('#single-select');
        await expect(select).toBeVisible();
    });

    test('should open dropdown on click', async ({ page }) => {
        const select = page.locator('#single-select');
        const trigger = select.locator('.select-trigger');
        const dropdown = select.locator('.dropdown');

        await trigger.click();
        await expect(dropdown).toHaveClass(/open/);
    });

    test('should close dropdown when clicking outside', async ({ page }) => {
        const select = page.locator('#single-select');
        const trigger = select.locator('.select-trigger');
        const dropdown = select.locator('.dropdown');

        await trigger.click();
        await expect(dropdown).toHaveClass(/open/);

        await page.click('body'); // Click outside
        await expect(dropdown).not.toHaveClass(/open/);
    });

    test('should select an option (Single Mode)', async ({ page }) => {
        const select = page.locator('#single-select');
        const trigger = select.locator('.select-trigger');

        await trigger.click();

        const option = select.locator('.option').filter({ hasText: 'Mars' });
        await option.click();

        // Verify value text in trigger
        await expect(trigger).toContainText('Mars');

        // Verify output event
        // The value is 'mars' (lowercase)
        await expect(page.locator('#output-single')).toContainText('Selected: mars');
    });

    test('should select multiple options (Multi Mode)', async ({ page }) => {
        const select = page.locator('#multi-select');
        const trigger = select.locator('.select-trigger');

        await trigger.click();

        // Select Garrus
        await select.locator('.option').filter({ hasText: 'Garrus' }).click();
        // Select Liara
        await select.locator('.option').filter({ hasText: 'Liara' }).click();

        // Verify chips exist
        await expect(trigger.locator('.chip')).toHaveCount(2);
        await expect(trigger).toContainText('Garrus');
        await expect(trigger).toContainText('Liara');
    });

});
