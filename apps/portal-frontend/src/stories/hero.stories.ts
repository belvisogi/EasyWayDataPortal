import type { Meta, StoryObj } from '@storybook/html';
import type { HeroSectionSpec } from '../types/runtime-pages';

// Mock content for demo
const mockContent = {
    'hero.title': 'Sovereign Intelligence',
    'hero.subtitle': 'Smetti di affittare l\'intelligenza. Costruisci la tua.',
    'hero.cta': 'Richiedi Demo',
};

function getContentValue(key: string): string {
    return mockContent[key as keyof typeof mockContent] || key;
}

// Render function from pages-renderer.ts
function renderHeroSection(spec: HeroSectionSpec): string {
    const title = getContentValue(spec.titleKey);
    const subtitle = spec.subtitleKey ? getContentValue(spec.subtitleKey) : '';
    const cta = spec.ctaKey ? getContentValue(spec.ctaKey) : '';
    const ctaHref = spec.ctaHref || '#';

    return `
    <section class="hero">
      <h1 class="h1 text-gradient">${title}</h1>
      ${subtitle ? `<p class="hero-subtitle">${subtitle}</p>` : ''}
      ${cta ? `<a href="${ctaHref}" class="btn btn-primary">${cta}</a>` : ''}
    </section>
  `;
}

const meta: Meta<HeroSectionSpec> = {
    title: 'Sections/Hero',
    tags: ['autodocs'],
    render: (args) => {
        const container = document.createElement('div');
        container.innerHTML = renderHeroSection(args);
        return container;
    },
    argTypes: {
        titleKey: { control: 'text' },
        subtitleKey: { control: 'text' },
        ctaKey: { control: 'text' },
        ctaHref: { control: 'text' },
    },
};

export default meta;
type Story = StoryObj<HeroSectionSpec>;

export const Default: Story = {
    args: {
        type: 'hero',
        titleKey: 'hero.title',
        subtitleKey: 'hero.subtitle',
        ctaKey: 'hero.cta',
        ctaHref: '/demo',
    },
};

export const WithoutCTA: Story = {
    args: {
        type: 'hero',
        titleKey: 'hero.title',
        subtitleKey: 'hero.subtitle',
    },
};

export const MinimalTitle: Story = {
    args: {
        type: 'hero',
        titleKey: 'hero.title',
    },
};
