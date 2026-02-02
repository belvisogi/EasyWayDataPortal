import { test, expect } from '@playwright/test';

/**
 * E2E Tests: Form Validation
 * 
 * Purpose: Verify form fields are present and basic validation works
 * 
 * Simplified tests focusing on form presence and field validation
 */

test.describe('Form Validation', () => {
    test.beforeEach(async ({ page }) => {
        // Navigate to demo page before each test
        await page.goto('/demo');
        await expect(page.locator('form')).toBeVisible({ timeout: 10000 });
    });

    test('should have all required form fields', async ({ page }) => {
        // Verify all expected fields exist
        await expect(page.locator('input[name="firstName"]')).toBeVisible();
        await expect(page.locator('input[name="lastName"]')).toBeVisible();
        await expect(page.locator('input[name="company"]')).toBeVisible();
        await expect(page.locator('input[name="email"]')).toBeVisible();
        await expect(page.locator('input[name="jobTitle"]')).toBeVisible();
        await expect(page.locator('select[name="companySize"]')).toBeVisible();
        await expect(page.locator('select[name="interest"]')).toBeVisible();
        await expect(page.locator('textarea[name="description"]')).toBeVisible();
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
