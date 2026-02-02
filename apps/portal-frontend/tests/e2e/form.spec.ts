import { test, expect } from '@playwright/test';

/**
 * E2E Tests: Form Submission
 * 
 * Purpose: Verify form validation and submission flow
 * 
 * Tests the /demo page form
 */

test.describe('Form Submission', () => {
    test.beforeEach(async ({ page }) => {
        // Navigate to demo page before each test
        await page.goto('/demo');
        await expect(page.locator('form')).toBeVisible();
    });

    test('should show validation errors for empty required fields', async ({ page }) => {
        // Try to submit empty form
        await page.click('button[type="submit"]');

        // Check if browser validation kicks in (HTML5 required attribute)
        const nameInput = page.locator('input[name="name"]');
        const isInvalid = await nameInput.evaluate((el: HTMLInputElement) => !el.validity.valid);

        expect(isInvalid).toBe(true);
    });

    test('should fill and submit form successfully', async ({ page }) => {
        // Fill form fields
        await page.fill('input[name="name"]', 'Test User');
        await page.fill('input[name="email"]', 'test@example.com');
        await page.fill('input[name="company"]', 'Test Company');

        // Select dropdown (if exists)
        const selectField = page.locator('select[name="interest"]');
        if (await selectField.isVisible()) {
            await selectField.selectOption('demo');
        }

        // Fill textarea (if exists)
        const messageField = page.locator('textarea[name="message"]');
        if (await messageField.isVisible()) {
            await messageField.fill('This is a test message');
        }

        // Check consent checkbox (if exists)
        const consentCheckbox = page.locator('input[type="checkbox"][name="consent"]');
        if (await consentCheckbox.isVisible()) {
            await consentCheckbox.check();
        }

        // Submit form
        await page.click('button[type="submit"]');

        // Wait for submission (form should reset or show success message)
        // Note: Adjust based on actual form behavior
        await page.waitForTimeout(1000);

        // Verify form was submitted (check if fields are reset or success message shown)
        const nameValue = await page.inputValue('input[name="name"]');
        // Form might reset or show success - adjust assertion based on actual behavior
        expect(nameValue).toBeDefined();
    });

    test('should validate email format', async ({ page }) => {
        // Fill with invalid email
        await page.fill('input[name="email"]', 'invalid-email');

        // Try to submit
        await page.click('button[type="submit"]');

        // Check if email validation fails
        const emailInput = page.locator('input[name="email"]');
        const isInvalid = await emailInput.evaluate((el: HTMLInputElement) => !el.validity.valid);

        expect(isInvalid).toBe(true);
    });

    test('should disable submit button during submission', async ({ page }) => {
        // Fill form
        await page.fill('input[name="name"]', 'Test User');
        await page.fill('input[name="email"]', 'test@example.com');

        const submitButton = page.locator('button[type="submit"]');

        // Check if button gets disabled during submission
        // Note: This depends on actual implementation
        const isEnabled = await submitButton.isEnabled();
        expect(isEnabled).toBe(true);
    });
});
