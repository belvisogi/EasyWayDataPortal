# Storybook Setup Guide - Runtime Pages Framework

> **Comprehensive guide**: What, Why, How  
> **Audience**: Developers contributing to the framework  
> **Last Updated**: 2026-02-02

---

## Table of Contents
1. [What is Storybook?](#what-is-storybook)
2. [Why We Use Storybook](#why-we-use-storybook)
3. [Setup Instructions](#setup-instructions)
4. [Creating Stories](#creating-stories)
5. [Troubleshooting](#troubleshooting)
6. [N8N Automation](#n8n-automation)
7. [Deployment](#deployment)

---

## What is Storybook?

### Definition
Storybook is an **interactive catalog** of UI components. It allows developers to:
- View components in isolation (without running the full app)
- Test different component states (with/without props)
- Document component APIs visually
- Share component examples with designers/stakeholders

### Analogy
Think of Storybook as an **IKEA catalog** for your UI components:
- IKEA catalog shows furniture in different configurations
- Storybook shows components in different states

### Example
**Without Storybook**:
```
To see Hero section:
1. Start dev server
2. Navigate to homepage
3. Scroll to hero
4. Change props → edit JSON → rebuild → refresh
```

**With Storybook**:
```
1. Open http://localhost:6006
2. Click "Hero Section"
3. Change props → see result instantly
```

---

## Why We Use Storybook

### 1. Interactive Brochure (Primary Reason)
**Problem**: Most developers don't read `.md` documentation.

**Solution**: Storybook provides a **visual, interactive** showcase of the framework.

**Impact**:
- Developer sees live examples → understands immediately
- Copy JSON from story → paste in project → done
- More GitHub stars (visual demos attract attention)

### 2. Component Documentation
**Problem**: Hard to remember all component variants.

**Solution**: Storybook documents all 5 canonical sections:
- Hero (3 variants: default, without CTA, minimal)
- Cards (3 variants: 2 cards, 3 cards, 4 cards)
- Comparison (1 variant: Shield vs Terminal)
- CTA (2 variants: default, with secondary)
- Form (2 variants: demo request, contact)

**Impact**:
- New contributors see all options
- Consistent component usage across projects

### 3. Visual Regression Testing
**Problem**: CSS changes can break components unexpectedly.

**Solution**: Storybook takes screenshots of each story → compares on every commit.

**Impact**:
- Catch visual bugs before production
- Automated QA for UI changes

### 4. Design System
**Problem**: Designers need to approve UI changes.

**Solution**: Storybook provides a shared reference for design/dev.

**Impact**:
- Designer opens Storybook → sees component → approves/rejects
- No need to deploy staging environment

---

## Setup Instructions

### Prerequisites
- Node.js 18+ installed
- npm 9+ installed
- Framework cloned locally

### Step 1: Install Storybook

**What**: Install Storybook dependencies.

**Why**: Storybook requires specific packages for HTML/Vite integration.

**How**:
```bash
cd apps/portal-frontend
npm install --save-dev storybook@8 @storybook/html-vite @storybook/addon-essentials --legacy-peer-deps
```

**Flags Explained**:
- `@8`: Use Storybook 8.x (more stable than 10.x with Vite 6)
- `--legacy-peer-deps`: Ignore peer dependency conflicts (Vite 6 not fully compatible)

**Expected Output**:
```
added 43 packages, and audited 210 packages in 15s
found 0 vulnerabilities
```

### Step 2: Create Configuration

**What**: Configure Storybook for HTML/TypeScript.

**Why**: Storybook needs to know:
- Where to find stories (`src/**/*.stories.ts`)
- What framework to use (`html-vite`)
- What addons to load (`essentials`)

**How**:
```bash
# Create .storybook directory
mkdir .storybook

# Create main.ts
cat > .storybook/main.ts << 'EOF'
import type { StorybookConfig } from '@storybook/html-vite';

const config: StorybookConfig = {
  stories: ['../src/**/*.stories.@(js|jsx|ts|tsx)'],
  addons: ['@storybook/addon-essentials'],
  framework: {
    name: '@storybook/html-vite',
    options: {},
  },
  docs: {
    autodocs: 'tag',
  },
};

export default config;
EOF
```

**Config Explained**:
- `stories`: Glob pattern to find story files
- `addons`: Essential addons (controls, actions, docs)
- `framework`: Use Vite for fast HMR
- `docs`: Auto-generate docs from stories

### Step 3: Import Framework Styles

**What**: Import existing CSS into Storybook.

**Why**: Stories need framework styles to render correctly.

**How**:
```bash
cat > .storybook/preview.ts << 'EOF'
import type { Preview } from '@storybook/html';
import '../src/theme.css';
import '../src/framework.css';
import '../src/style.css';

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/,
      },
    },
  },
};

export default preview;
EOF
```

**Imports Explained**:
- `theme.css`: CSS variables (colors, fonts)
- `framework.css`: Grid system, utilities
- `style.css`: Component-specific styles

### Step 4: Add Scripts to package.json

**What**: Add npm scripts to run Storybook.

**Why**: Convenient commands for dev/build.

**How**:
```json
{
  "scripts": {
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build"
  }
}
```

**Scripts Explained**:
- `storybook`: Start dev server on port 6006
- `build-storybook`: Build static site for deployment

### Step 5: Test Storybook

**What**: Verify Storybook starts correctly.

**Why**: Catch setup issues early.

**How**:
```bash
npm run storybook
```

**Expected Output**:
```
┌  storybook v8.x.x
│
│  Local:   http://localhost:6006/
│  Network: http://192.168.1.x:6006/
│
└  Storybook started successfully
```

**If Errors**: See [Troubleshooting](#troubleshooting) section.

---

## Creating Stories

### Story Anatomy

**What**: A story is a single state of a component.

**Why**: Each story shows one use case (e.g., "Hero with CTA", "Hero without CTA").

**Structure**:
```typescript
import type { Meta, StoryObj } from '@storybook/html';
import type { HeroSection } from '../types/runtime-pages';

// 1. Mock content (simulates content.json)
const mockContent = {
  'hero.title': 'Sovereign Intelligence',
};

// 2. Render function (converts spec → HTML)
function renderHero(spec: HeroSection): string {
  return `<section class="hero">...</section>`;
}

// 3. Meta (story configuration)
const meta: Meta<HeroSection> = {
  title: 'Sections/Hero',
  render: (args) => {
    const container = document.createElement('div');
    container.innerHTML = renderHero(args);
    return container;
  },
};

export default meta;

// 4. Stories (variants)
export const Default: StoryObj<HeroSection> = {
  args: {
    type: 'hero',
    titleKey: 'hero.title',
  },
};
```

### Example: Hero Section Story

**File**: `src/stories/hero.stories.ts`

**What**: Documents Hero section with 3 variants.

**Why**: Shows all Hero use cases (with CTA, without CTA, minimal).

**Code**:
```typescript
import type { Meta, StoryObj } from '@storybook/html';
import type { HeroSection } from '../types/runtime-pages';

const mockContent = {
  'hero.title': 'Sovereign Intelligence',
  'hero.subtitle': 'Smetti di affittare l\'intelligenza. Costruisci la tua.',
  'hero.cta': 'Richiedi Demo',
};

function getContentValue(key: string): string {
  return mockContent[key as keyof typeof mockContent] || key;
}

function renderHero(spec: HeroSection): string {
  const title = getContentValue(spec.titleKey);
  const subtitle = spec.taglineKey ? getContentValue(spec.taglineKey) : '';
  const cta = spec.cta?.labelKey ? getContentValue(spec.cta.labelKey) : '';
  const ctaHref = spec.cta?.action.type === 'link' ? spec.cta.action.href : '#';

  return `
    <section class="hero">
      <h1 class="h1 text-gradient">${title}</h1>
      ${subtitle ? `<p class="hero-subtitle">${subtitle}</p>` : ''}
      ${cta ? `<a href="${ctaHref}" class="btn btn-primary">${cta}</a>` : ''}
    </section>
  `;
}

const meta: Meta<HeroSection> = {
  title: 'Sections/Hero',
  tags: ['autodocs'],
  render: (args) => {
    const container = document.createElement('div');
    container.innerHTML = renderHero(args);
    return container;
  },
};

export default meta;
type Story = StoryObj<HeroSection>;

export const Default: Story = {
  args: {
    type: 'hero',
    titleKey: 'hero.title',
    taglineKey: 'hero.subtitle',
    cta: {
      labelKey: 'hero.cta',
      action: { type: 'link', href: '/demo' }
    },
  },
};

export const WithoutCTA: Story = {
  args: {
    type: 'hero',
    titleKey: 'hero.title',
    taglineKey: 'hero.subtitle',
  },
};

export const MinimalTitle: Story = {
  args: {
    type: 'hero',
    titleKey: 'hero.title',
  },
};
```

**Story Variants Explained**:
- `Default`: Full hero (title + subtitle + CTA)
- `WithoutCTA`: Hero without call-to-action
- `MinimalTitle`: Only title (minimal variant)

---

## Troubleshooting

### Error: Package Incompatibility

**Symptom**:
```
Error: You are using Storybook 10.2.3 but you have packages which are incompatible
```

**Root Cause**: Vite 6.x not fully compatible with Storybook 10.x.

**Solution 1: Downgrade Storybook**:
```bash
npm uninstall storybook @storybook/html-vite
npm install --save-dev storybook@8 @storybook/html-vite@8 --legacy-peer-deps
```

**Solution 2: Use Doctor**:
```bash
npx storybook doctor
# Follow prompts to fix dependencies
```

**Prevention**: Pin Storybook version in `package.json`:
```json
{
  "devDependencies": {
    "storybook": "^8.0.0"
  }
}
```

### Error: TypeScript Type Mismatch

**Symptom**:
```
'HeroSectionSpec' has no exported member. Did you mean 'HeroSection'?
```

**Root Cause**: Story uses wrong type name.

**Solution**: Use correct type from `types/runtime-pages.ts`:
```typescript
// ❌ Wrong
import type { HeroSectionSpec } from '../types/runtime-pages';

// ✅ Correct
import type { HeroSection } from '../types/runtime-pages';
```

**Prevention**: Check `types/runtime-pages.ts` for exact type names.

### Error: Storybook Command Not Found

**Symptom**:
```
'storybook' is not recognized as an internal or external command
```

**Root Cause**: Storybook CLI not installed.

**Solution**:
```bash
npm install --save-dev storybook --legacy-peer-deps
```

**Verification**:
```bash
npx storybook --version
# Should output: 8.x.x
```

---

## N8N Automation

### Workflow 1: Auto-Update Stories

**What**: Automatically update Storybook when page specs change.

**Why**: Manual updates are error-prone and time-consuming.

**How**:

**N8N Workflow**:
```
1. Webhook Trigger (GitHub push to pages/*.json)
2. HTTP Request (fetch changed JSON)
3. Code Node (generate .stories.ts)
4. Git Commit (commit new story)
5. HTTP Request (trigger CI rebuild)
```

**Code Node Logic**:
```javascript
// Input: pages/pricing.json
const pageSpec = $input.item.json;

// Generate story
const story = `
import type { Meta, StoryObj } from '@storybook/html';
import type { PageSpecV1 } from '../types/runtime-pages';

export const ${pageSpec.id}: StoryObj = {
  args: ${JSON.stringify(pageSpec, null, 2)}
};
`;

// Output: src/stories/${pageSpec.id}.stories.ts
return { story, filename: \`\${pageSpec.id}.stories.ts\` };
```

**Trigger Setup**:
```bash
# GitHub webhook
URL: https://n8n.example.com/webhook/storybook-update
Events: push (filter: pages/*.json)
```

### Workflow 2: Visual Regression Check

**What**: Nightly screenshot comparison.

**Why**: Catch visual bugs before they reach production.

**How**:

**N8N Workflow**:
```
1. Cron Trigger (every night at 2 AM)
2. HTTP Request (trigger Storybook test-runner)
3. Code Node (compare screenshots)
4. Slack Notification (if differences found)
```

**Test Runner**:
```bash
# Install test-runner
npm install --save-dev @storybook/test-runner playwright

# Run tests
npm run test-storybook
```

**Comparison Logic**:
```javascript
const pixelmatch = require('pixelmatch');
const PNG = require('pngjs').PNG;

// Compare screenshots
const diff = pixelmatch(
  baseline.data,
  current.data,
  null,
  width,
  height,
  { threshold: 0.1 }
);

if (diff > 100) {
  // Send alert
  return { alert: true, diff };
}
```

---

## Deployment

### GitHub Pages (Free Hosting)

**What**: Deploy Storybook to GitHub Pages.

**Why**: Public URL for framework brochure.

**How**:

**Step 1: Build Storybook**:
```bash
npm run build-storybook
# Output: storybook-static/
```

**Step 2: Create GitHub Action**:
```yaml
# .github/workflows/deploy-storybook.yml
name: Deploy Storybook
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm ci
      - run: npm run build-storybook
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./apps/portal-frontend/storybook-static
```

**Step 3: Enable GitHub Pages**:
```
1. Go to repo Settings
2. Pages → Source: gh-pages branch
3. Save
```

**Result**: `https://yourusername.github.io/runtime-pages-framework`

### Custom Domain (Optional)

**What**: Use custom domain for Storybook.

**Why**: Professional branding (e.g., `docs.yourframework.com`).

**How**:
```bash
# Add CNAME file
echo "docs.yourframework.com" > storybook-static/CNAME

# Update DNS
# A record: @ → 185.199.108.153
# CNAME: docs → yourusername.github.io
```

---

## Best Practices

### 1. One Story Per Use Case
**Why**: Clear, focused examples.

**Example**:
```typescript
// ✅ Good: Separate stories
export const HeroWithCTA: Story = { ... }
export const HeroWithoutCTA: Story = { ... }

// ❌ Bad: One story with controls
export const Hero: Story = {
  args: { showCTA: true } // User has to toggle
}
```

### 2. Mock Content Locally
**Why**: Stories should be self-contained.

**Example**:
```typescript
// ✅ Good: Mock in story
const mockContent = { 'hero.title': '...' };

// ❌ Bad: Import from app
import { SOVEREIGN_CONTENT } from '../content';
```

### 3. Document Edge Cases
**Why**: Show what happens when data is missing.

**Example**:
```typescript
export const HeroNoSubtitle: Story = {
  args: {
    titleKey: 'hero.title',
    // No taglineKey → should render without subtitle
  },
};
```

---

## FAQ

### Q: Why Storybook instead of a demo page?
**A**: Storybook provides:
- Interactive controls (change props live)
- Auto-generated docs
- Visual regression testing
- Industry standard (more contributors)

### Q: Can I use Storybook locally without deploying?
**A**: Yes! `npm run storybook` runs on `localhost:6006`.

### Q: How do I add a new story?
**A**: 
1. Create `src/stories/[component].stories.ts`
2. Follow [Creating Stories](#creating-stories) guide
3. Refresh Storybook → story appears

### Q: What if Storybook breaks?
**A**: 
1. Check [Troubleshooting](#troubleshooting)
2. Document error in `docs/qa-log.md`
3. Ask in GitHub Discussions

---

*Guide created by Antigravity — 2026-02-02*
