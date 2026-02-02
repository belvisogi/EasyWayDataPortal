import { test, expect } from '@playwright/test';

/**
 * E2E Tests: Form Validation (Hardened)
 * 
 * Verified Strategy:
 * 1. Wait for networkidle (assets loaded)
 * 2. Explicitly wait for form element (dynamic rendering)
 * 3. Verify HTML5 validation state
 */

test.describe('Form Validation', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/demo');
        await page.waitForLoadState('networkidle');
        await page.waitForSelector('form', { state: 'visible', timeout: 30000 });
        // Explicitly wait for the first field to ensure inner rendering is complete
        await page.waitForSelector('input[name="firstName"]', { state: 'visible', timeout: 30000 });
    });

    test('should have all required form fields', async ({ page }) => {
        // Verify all expected fields exist
        // Using generic selectors that match the rendered output structure
        await expect(page.locator('input[name="firstName"]')).toBeVisible();
        await expect(page.locator('input[name="lastName"]')).toBeVisible();
        await expect(page.locator('input[name="company"]')).toBeVisible();
        await expect(page.locator('input[name="email"]')).toBeVisible();
        await expect(page.locator('input[name="consent"]')).toBeVisible();
        await expect(page.locator('button[type="submit"]')).toBeVisible();
    });

    test('should show validation for empty required fields', async ({ page }) => {
        // Try to submit empty form
        const submitButton = page.locator('button[type="submit"]');
        await submitButton.click();

        // Check if browser validation kicks in (HTML5 required attribute)
        const firstNameInput = page.locator('input[name="firstName"]');
        const isInvalid = await firstNameInput.evaluate((el: HTMLInputElement) => !el.validity.valid);

        expect(isInvalid).toBe(true);
    });

    test('should validate email format', async ({ page }) => {
        // Fill with invalid email
        await page.fill('input[name="email"]', 'invalid-email');
        await page.press('input[name="email"]', 'Tab'); // Trigger blur if needed

        // Check if email validation fails
        const emailInput = page.locator('input[name="email"]');
        const isInvalid = await emailInput.evaluate((el: HTMLInputElement) => !el.validity.valid);

        expect(isInvalid).toBe(true);
    });

    test('should accept valid email format', async ({ page }) => {
        // Fill with valid email
        await page.fill('input[name="email"]', 'test@example.com');

        // Check if email validation passes
        const emailInput = page.locator('input[name="email"]');
        const isValid = await emailInput.evaluate((el: HTMLInputElement) => el.validity.valid);

        expect(isValid).toBe(true);
    });
});
