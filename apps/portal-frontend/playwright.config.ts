import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright Configuration for EasyWay Core Frontend
 * 
 * Antifragile Patterns:
 * - Environment-aware base URL (dev/prod)
 * - Automatic retry on failure (flaky network resilience)
 * - Screenshots on failure (debugging)
 * - Minimal browser matrix (Chromium only for speed)
 */

export default defineConfig({
    testDir: './tests/e2e',

    // Run tests in files in parallel
    fullyParallel: true,

    // Fail the build on CI if you accidentally left test.only in the source code
    forbidOnly: !!process.env.CI,

    // Retry on CI only (antifragile: tolerate flaky tests)
    retries: process.env.CI ? 2 : 0,

    // Opt out of parallel tests on CI
    workers: process.env.CI ? 1 : undefined,

    // Reporter to use
    reporter: 'html',

    // Shared settings for all the projects below
    use: {
        // Base URL (environment-aware)
        baseURL: process.env.BASE_URL || 'http://localhost:5173',

        // Collect trace when retrying the failed test
        trace: 'on-first-retry',

        // Screenshot on failure (debugging)
        screenshot: 'only-on-failure',

        // Video on failure (optional, can be heavy)
        video: 'retain-on-failure',
    },

    // Configure projects for major browsers
    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },

        // Uncomment for cross-browser testing
        // {
        //   name: 'firefox',
        //   use: { ...devices['Desktop Firefox'] },
        // },
        // {
        //   name: 'webkit',
        //   use: { ...devices['Desktop Safari'] },
        // },
    ],

    // Run your local dev server before starting the tests
    webServer: {
        command: 'npm run dev',
        url: 'http://localhost:5173',
        reuseExistingServer: !process.env.CI,
        timeout: 120 * 1000, // 2 minutes for Vite to start
    },
});
