
import { test, expect } from '@playwright/test';

test.describe('The Timekeeper (Sovereign Datepicker)', () => {

    test.beforeEach(async ({ page }) => {
        // Go to the isolated test page
        await page.goto('/test-datepicker.html');
    });

    test('should render the component', async ({ page }) => {
        const picker = page.locator('sovereign-datepicker');
        await expect(picker).toBeVisible();

        // Check Shadow DOM content
        // Note: Playwright automatically pierces shadow DOM for locators like getByText
        const monthTitle = picker.locator('.month-title');
        await expect(monthTitle).toBeVisible();
    });

    test('should display current month and year by default', async ({ page }) => {
        const now = new Date();
        const currentMonth = now.toLocaleString('default', { month: 'long' });
        const currentYear = now.getFullYear().toString();
        const picker = page.locator('sovereign-datepicker');

        await expect(picker.locator('.month-title')).toContainText(currentMonth);
        await expect(picker.locator('.month-title')).toContainText(currentYear);
    });

    test('should highlight today', async ({ page }) => {
        const now = new Date();
        const day = now.getDate().toString();
        const picker = page.locator('sovereign-datepicker');

        const todayCell = picker.locator(`.day.today`);
        await expect(todayCell).toBeVisible();
        await expect(todayCell).toHaveText(day);
    });

    test('should select a date and emit event', async ({ page }) => {
        const picker = page.locator('sovereign-datepicker');

        // Find a day that is NOT empty
        const dayToClick = picker.locator('.day:not(.empty)').first();
        const dayText = await dayToClick.innerText();

        await dayToClick.click();

        // Verify visual selection state
        await expect(dayToClick).toHaveClass(/selected/);

        // Verify output on the test page (which listens to the event)
        const output = page.locator('#output');
        await expect(output).toContainText('Selected:');
        // We don't check exact date string format to avoid locale flakiness in test, 
        // but the presence of "Selected:" implies the event fired.
    });

    test('should navigate to next month', async ({ page }) => {
        const picker = page.locator('sovereign-datepicker');
        const nextBtn = picker.locator('.nav-btn.next');
        const title = picker.locator('.month-title');

        const initialTitle = await title.innerText();
        await nextBtn.click();

        // Title should change
        await expect(title).not.toHaveText(initialTitle);
    });

});
