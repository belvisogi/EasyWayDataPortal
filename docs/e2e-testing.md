# E2E Testing Guide - EasyWay Core Frontend

> **Purpose**: Complete workflow for E2E testing with Playwright, including setup, execution, troubleshooting, and debugging.

---

## Table of Contents

1. [Why E2E Tests](#why-e2e-tests)
2. [Setup](#setup)
3. [Running Tests](#running-tests)
4. [Writing Tests](#writing-tests)
5. [Troubleshooting](#troubleshooting)
6. [Debugging Step-by-Step](#debugging-step-by-step)
7. [CI/CD Integration](#cicd-integration)

---

## Why E2E Tests

**Purpose**: Verify that the entire application works from the user's perspective.

**Benefits**:
- ✅ Confidence in deployments (no regressions)
- ✅ Catch integration bugs (not just unit bugs)
- ✅ Document user flows (tests as living documentation)
- ✅ Prevent breaking changes (automated regression testing)

**When to Run**:
- Before every deployment
- After major changes
- In CI/CD pipeline (automated)

---

## Setup

### 1. Install Playwright

```bash
cd apps/portal-frontend
npm install -D @playwright/test
```

### 2. Install Browsers

```bash
npx playwright install chromium
```

**Note**: Chromium is ~170MB. Firefox and WebKit are optional.

### 3. Install TypeScript Types

```bash
npm install -D @types/node
```

### 4. Verify Installation

```bash
npx playwright --version
# Should output: Version 1.48.0 (or later)
```

---

## Running Tests

### Local Development

```bash
# Run all tests (headless)
npm run test:e2e

# Run with UI (interactive)
npm run test:e2e:ui

# Run in debug mode (step-by-step)
npm run test:e2e:debug

# View last test report
npm run test:e2e:report
```

### Production Testing

```bash
# Test against production server
BASE_URL=http://80.225.86.168 npm run test:e2e
```

### Single Test File

```bash
npx playwright test tests/e2e/navigation.spec.ts
```

### Single Test

```bash
npx playwright test tests/e2e/navigation.spec.ts -g "should load home page"
```

---

## Writing Tests

### Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    // Setup before each test
    await page.goto('/');
  });

  test('should do something', async ({ page }) => {
    // Arrange
    await page.goto('/demo');
    
    // Act
    await page.click('button');
    
    // Assert
    await expect(page.locator('h1')).toBeVisible();
  });
});
```

### Best Practices

#### 1. **Use Specific Selectors**

```typescript
// ✅ Good: Specific, semantic
await page.locator('input[name="email"]')
await page.locator('button[type="submit"]')
await page.locator('[data-testid="login-button"]')

// ❌ Bad: Fragile, generic
await page.locator('input')
await page.locator('.btn')
await page.locator('div > div > button')
```

#### 2. **Wait for Elements**

```typescript
// ✅ Good: Explicit wait
await expect(page.locator('form')).toBeVisible({ timeout: 10000 });

// ❌ Bad: No wait (flaky)
await page.click('button');
```

#### 3. **Test User Flows, Not Implementation**

```typescript
// ✅ Good: User perspective
test('user can submit contact form', async ({ page }) => {
  await page.goto('/demo');
  await page.fill('input[name="email"]', 'test@example.com');
  await page.click('button[type="submit"]');
  await expect(page.locator('.success-message')).toBeVisible();
});

// ❌ Bad: Implementation details
test('form calls submitForm() function', async ({ page }) => {
  // Testing internal functions, not user behavior
});
```

#### 4. **Avoid Hard-Coded Waits**

```typescript
// ✅ Good: Wait for condition
await expect(page.locator('.spinner')).toBeHidden();

// ❌ Bad: Arbitrary timeout
await page.waitForTimeout(5000);
```

---

## Troubleshooting

### Common Issues

#### Issue 1: "All tests fail immediately"

**Symptoms**: Tests fail before even loading the page.

**Causes**:
- Dev server not starting
- Port already in use
- Timeout too short

**Solutions**:

1. **Check if dev server is running**:
   ```bash
   # In separate terminal
   npm run dev
   
   # Then run tests
   npm run test:e2e
   ```

2. **Check port availability**:
   ```bash
   # Windows
   netstat -ano | findstr :5173
   
   # Kill process if needed
   taskkill /PID <PID> /F
   ```

3. **Increase timeout in `playwright.config.ts`**:
   ```typescript
   webServer: {
     timeout: 120 * 1000, // 2 minutes
   }
   ```

---

#### Issue 2: "Element not found"

**Symptoms**: `Error: locator.click: Target closed` or `Timeout 30000ms exceeded`

**Causes**:
- Selector doesn't match actual HTML
- Element not visible yet (dynamic rendering)
- Element inside shadow DOM

**Solutions**:

1. **Inspect actual HTML**:
   ```bash
   npm run test:e2e:ui
   # Click on failed test
   # Click "Pick Locator" button
   # Click on element in page
   # Copy correct selector
   ```

2. **Add explicit wait**:
   ```typescript
   await expect(page.locator('sovereign-header')).toBeVisible({ timeout: 10000 });
   ```

3. **Check for shadow DOM**:
   ```typescript
   // If element is inside web component shadow DOM
   const header = page.locator('sovereign-header');
   const link = header.locator('a[href="/demo"]');
   ```

---

#### Issue 3: "Tests pass locally but fail in CI"

**Causes**:
- Different screen size
- Different timezone
- Race conditions (timing)

**Solutions**:

1. **Set viewport in config**:
   ```typescript
   use: {
     viewport: { width: 1280, height: 720 },
   }
   ```

2. **Use retry logic**:
   ```typescript
   retries: process.env.CI ? 2 : 0,
   ```

3. **Add screenshots on failure**:
   ```typescript
   use: {
     screenshot: 'only-on-failure',
     video: 'retain-on-failure',
   }
   ```

---

#### Issue 4: "Form submission doesn't work"

**Causes**:
- Form validation blocking submit
- Submit button disabled
- Form action not configured

**Solutions**:

1. **Fill all required fields**:
   ```typescript
   await page.fill('input[name="firstName"]', 'Test');
   await page.fill('input[name="lastName"]', 'User');
   await page.fill('input[name="email"]', 'test@example.com');
   await page.check('input[name="consent"]');
   ```

2. **Check validation state**:
   ```typescript
   const isValid = await page.locator('input[name="email"]')
     .evaluate((el: HTMLInputElement) => el.validity.valid);
   expect(isValid).toBe(true);
   ```

---

## Debugging Step-by-Step

### Step 1: Run with UI Mode

```bash
npm run test:e2e:ui
```

**What you see**:
- List of all tests
- Pass/fail status
- Screenshots/videos of failures

**Actions**:
1. Click on failed test
2. See error message
3. View screenshot/video
4. Identify what went wrong

---

### Step 2: Use Debug Mode

```bash
npm run test:e2e:debug
```

**What you see**:
- Browser opens
- Test runs step-by-step
- Pauses on each action

**Actions**:
1. Press F10 to step through
2. Inspect page state
3. Check console for errors

---

### Step 3: Use Pick Locator

```bash
npm run test:e2e:ui
# Click "Pick Locator" button
# Click on element in page
# Copy generated selector
```

**What you get**:
- Correct selector for element
- Multiple selector options (CSS, XPath, text)

---

### Step 4: Add Console Logs

```typescript
test('debug test', async ({ page }) => {
  await page.goto('/demo');
  
  // Log page title
  console.log('Title:', await page.title());
  
  // Log element count
  const forms = await page.locator('form').count();
  console.log('Forms found:', forms);
  
  // Log element text
  const text = await page.locator('h1').textContent();
  console.log('H1 text:', text);
});
```

---

### Step 5: Take Screenshots Manually

```typescript
test('debug with screenshots', async ({ page }) => {
  await page.goto('/demo');
  
  // Screenshot before action
  await page.screenshot({ path: 'before.png' });
  
  await page.click('button');
  
  // Screenshot after action
  await page.screenshot({ path: 'after.png' });
});
```

---

### Step 6: Check Network Requests

```typescript
test('debug network', async ({ page }) => {
  // Listen to all requests
  page.on('request', request => {
    console.log('Request:', request.url());
  });
  
  // Listen to all responses
  page.on('response', response => {
    console.log('Response:', response.url(), response.status());
  });
  
  await page.goto('/demo');
});
```

---

### Step 7: Simplify Test & Use Proven Strategy

If test is complex and failing, verify using the **Golden Strategy**:

```typescript
test('robust test', async ({ page }) => {
  await page.goto('/demo');
  
  // 1. Wait for Network Idle (ensure assets loaded)
  await page.waitForLoadState('networkidle');
  
  // 2. Explicitly wait for key elements (ensure rendering complete)
  // Essential for dynamic content / web components
  await page.waitForSelector('sovereign-header', { state: 'attached' });
  await page.waitForSelector('form', { state: 'visible' });
  
  // 3. Assert
  await expect(page.locator('form')).toBeVisible();
});
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '22'
      
      - name: Install dependencies
        run: npm ci
        working-directory: apps/portal-frontend
      
      - name: Install Playwright Browsers
        run: npx playwright install --with-deps chromium
        working-directory: apps/portal-frontend
      
      - name: Run E2E tests
        run: npm run test:e2e
        working-directory: apps/portal-frontend
      
      - name: Upload test report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: apps/portal-frontend/playwright-report/
```

---

## Test Coverage

### Current Tests

**Navigation** (5 tests):
- ✅ Home page loads
- ✅ Demo page loads directly
- ✅ Manifesto page loads directly
- ✅ Pricing page loads directly
- ✅ Demo-components page loads directly

**Form Validation** (4 tests):
- ✅ All required fields present
- ✅ Empty fields show validation
- ✅ Invalid email format rejected
- ✅ Valid email format accepted

**Total**: 9 tests

---

## Known Issues

### Issue: Dynamic Navigation Links

**Problem**: Navigation links are rendered dynamically after manifest loads.

**Impact**: Cannot reliably test navigation clicks.

**Workaround**: Test direct page loads instead of navigation clicks.

**Future Fix**: Add `data-testid` attributes to navigation links for stable selectors.

---

### Issue: Form Submission

**Problem**: Form submission behavior not fully implemented.

**Impact**: Cannot test end-to-end form submission flow.

**Workaround**: Test form validation only (required fields, email format).

**Future Fix**: Implement form submission handler and success message.

---

## Resources

- [Playwright Documentation](https://playwright.dev/)
- [Best Practices](https://playwright.dev/docs/best-practices)
- [Debugging Guide](https://playwright.dev/docs/debug)
- [Selectors Guide](https://playwright.dev/docs/selectors)

---

## Next Steps

1. **Fix Current Tests**: Debug why all tests are failing
2. **Add More Tests**: Cover more user flows (pricing, memory, etc.)
3. **CI/CD Integration**: Add E2E tests to deployment pipeline
4. **Visual Regression**: Add screenshot comparison tests
5. **Accessibility**: Add a11y tests with @axe-core/playwright

---

**Last Updated**: 2026-02-02  
**Maintainer**: team-frontend
