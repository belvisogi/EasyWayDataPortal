
import { test, expect } from '@playwright/test';

test.describe('The Grid (Sovereign Datagrid)', () => {

    test.beforeEach(async ({ page }) => {
        await page.goto('/test-grid.html');
    });

    test('should render headers', async ({ page }) => {
        const grid = page.locator('#grid');
        await expect(grid).toBeVisible();
        await expect(grid.getByText('Agent Name')).toBeVisible();
        await expect(grid.getByText('Status')).toBeVisible();
    });

    test('should render rows', async ({ page }) => {
        const grid = page.locator('#grid');
        await expect(grid.getByText('Cortex')).toBeVisible();
        await expect(grid.getByText('Legacy Bot')).toBeVisible();
    });

    test('should sort by name', async ({ page }) => {
        const grid = page.locator('#grid');
        const header = grid.locator('th[data-field="name"]');

        // Initial order: Cortex (ID 1) before Legacy Bot (ID 4)
        // Let's click sort. Default is Asc.
        // C - G - A - L - V - S (Sort by Name ID) -> Architect, Cortex, GEDI, Legacy Bot, Scribe, Vision

        await header.click();

        // Check if Architect is first row content
        // locator('tbody tr').first().locator('td').nth(1) => Name column
        const firstRowName = grid.locator('tbody tr').first().locator('td').nth(1);
        await expect(firstRowName).toHaveText('Architect');

        // Click again -> Descending -> Vision should be first
        await header.click();
        await expect(firstRowName).toHaveText('Vision');
    });

    test('should sort by id (numeric)', async ({ page }) => {
        const grid = page.locator('#grid');
        const header = grid.locator('th[data-field="id"]');

        await header.click(); // Asc
        const firstRowId = grid.locator('tbody tr').first().locator('td').nth(0);
        await expect(firstRowId).toHaveText('1');

        await header.click(); // Desc
        await expect(firstRowId).toHaveText('6');
    });

    test('should render custom HTML (chips)', async ({ page }) => {
        const grid = page.locator('#grid');
        const activeChip = grid.locator('.status-chip.status-active').first();
        await expect(activeChip).toBeVisible();
        await expect(activeChip).toHaveText('Active');
    });

});
