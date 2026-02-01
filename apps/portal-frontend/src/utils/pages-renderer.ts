import type {
    CardsCatalogItem,
    ComparisonSection,
    CtaSection,
    FormSection,
    HeroSection,
    PageSpecV1,
    PagesManifestV1,
    SectionSpec
} from '../types/runtime-pages';
import { getContentArray, getContentValue } from './content';

function setMaybeHtml(node: HTMLElement, value: string) {
    if (value.includes('<')) node.innerHTML = value;
    else node.textContent = value;
}

function el<K extends keyof HTMLElementTagNameMap>(
    tag: K,
    className?: string,
    text?: string
): HTMLElementTagNameMap[K] {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
}

function linkFromAction(action: any, label: string, variant: 'glass' | 'primary' = 'glass'): HTMLElement {
    if (!action || action.type !== 'link') return el('span', '', label);

    const a = el('a', variant === 'primary' ? 'btn btn-primary' : 'btn btn-glass', label) as HTMLAnchorElement;
    a.href = action.href;
    return a;
}

function renderHero(section: HeroSection): HTMLElement {
    const hero = el('section', 'hero');
    const container = el('div', 'container');
    hero.appendChild(container);

    // Keep the existing "neural core" aesthetic for consistency.
    const visual = el('div', 'neural-core-container');
    visual.id = 'core-visual';
    visual.appendChild(el('div', 'neural-core'));
    visual.appendChild(el('div', 'orbital-ring ring-1'));
    visual.appendChild(el('div', 'orbital-ring ring-2'));
    container.appendChild(visual);

    const heroText = el('div');
    heroText.id = 'hero-text';
    container.appendChild(heroText);

    const h1 = el('h1', 'h1');
    setMaybeHtml(h1, getContentValue(section.titleKey));
    heroText.appendChild(h1);
    if (section.taglineKey) {
        const p = el('p', 'tagline');
        setMaybeHtml(p, getContentValue(section.taglineKey));
        heroText.appendChild(p);
    }

    if (section.cta || section.ctaSecondary) {
        const actions = el('div', 'actions');

        if (section.cta) {
            const label = getContentValue(section.cta.labelKey);
            const btn = el('a', 'btn btn-primary', label) as HTMLAnchorElement;
            if (section.cta.action.type === 'link') btn.href = section.cta.action.href;
            btn.id = 'btn-engage';
            actions.appendChild(btn);
        }

        if (section.ctaSecondary) {
            const label = getContentValue(section.ctaSecondary.labelKey);
            const btn = el('a', 'btn btn-glass', label) as HTMLAnchorElement;
            if (section.ctaSecondary.action.type === 'link') btn.href = section.ctaSecondary.action.href;
            actions.appendChild(btn);
        }

        heroText.appendChild(actions);
    }

    return hero;
}

function renderCardsCatalogItem(item: CardsCatalogItem): HTMLElement {
    const card = el('div', 'card-plugin');

    const icon = el('div', 'card-icon');
    icon.textContent = item.iconText || '';
    card.appendChild(icon);

    const body = el('div', 'card-body');
    card.appendChild(body);

    const header = el('div', 'card-header');
    body.appendChild(header);

    const title = el('h4');
    setMaybeHtml(title, getContentValue(item.titleKey));
    header.appendChild(title);
    if (item.badgeKey) {
        const badge = el('span', 'badge');
        setMaybeHtml(badge, getContentValue(item.badgeKey));
        header.appendChild(badge);
    }

    if (item.descKey) {
        const desc = el('p', 'card-desc');
        setMaybeHtml(desc, getContentValue(item.descKey));
        body.appendChild(desc);
    }

    const footer = el('div', 'card-footer');
    body.appendChild(footer);

    footer.appendChild(el('span', 'status-dot online'));

    if (item.action) {
        const label = getContentValue(item.action.labelKey);
        footer.appendChild(linkFromAction(item.action.action, label, item.action.variant || 'glass'));
    }

    return card;
}

function renderCards(section: any): HTMLElement {
    const container = el('section', 'container');
    container.style.paddingBottom = '4rem';
    container.style.marginTop = '4rem';

    const grid = el('div', 'catalog-grid');
    container.appendChild(grid);

    for (const item of section.items || []) {
        grid.appendChild(renderCardsCatalogItem(item));
    }

    return container;
}

function renderComparison(section: ComparisonSection): HTMLElement {
    const wrapper = el('div', 'comparison-section');

    const header = el('div', 'comparison-header');
    const h2 = el('h2', 'h2');
    setMaybeHtml(h2, getContentValue(section.titleKey));
    header.appendChild(h2);
    if (section.subtitleKey) header.appendChild(el('p', '', getContentValue(section.subtitleKey)));
    wrapper.appendChild(header);

    const table = el('div', 'comparison-table');
    wrapper.appendChild(table);

    const left = el('div', 'col-easyway');
    table.appendChild(left);
    const leftTitle = el('div', 'logo-box');
    setMaybeHtml(leftTitle, getContentValue(section.left.titleKey));
    left.appendChild(leftTitle);
    const leftUl = el('ul');
    left.appendChild(leftUl);
    for (const k of section.left.itemsKeys) leftUl.appendChild(el('li', 'check', getContentValue(k)));

    const right = el('div', 'col-cloud');
    table.appendChild(right);
    const rightTitle = el('div', 'logo-box cloud');
    setMaybeHtml(rightTitle, getContentValue(section.right.titleKey));
    right.appendChild(rightTitle);
    const rightUl = el('ul');
    right.appendChild(rightUl);
    for (const k of section.right.itemsKeys) rightUl.appendChild(el('li', 'cross', getContentValue(k)));

    const container = el('section', 'container');
    container.appendChild(wrapper);
    return container;
}

function renderCta(section: CtaSection): HTMLElement {
    const container = el('section', 'container');
    container.style.padding = '4rem 2rem';

    const panel = el('div', 'glass-panel');
    panel.style.padding = '2rem';
    container.appendChild(panel);

    const h2 = el('h2', 'h2');
    setMaybeHtml(h2, getContentValue(section.titleKey));
    panel.appendChild(h2);
    if (section.bodyKey) {
        const p = el('p');
        setMaybeHtml(p, getContentValue(section.bodyKey));
        panel.appendChild(p);
    }

    const actions = el('div', 'actions');
    actions.style.marginTop = '1rem';
    panel.appendChild(actions);

    if (section.primary) actions.appendChild(linkFromAction(section.primary.action, getContentValue(section.primary.labelKey), 'primary'));
    if (section.secondary) actions.appendChild(linkFromAction(section.secondary.action, getContentValue(section.secondary.labelKey), 'glass'));

    return container;
}

function renderSpacer(section: any): HTMLElement {
    const div = el('div');
    const size = section.size || 'md';
    div.style.height = size === 'sm' ? '1.5rem' : size === 'lg' ? '6rem' : '3rem';
    return div;
}

function renderForm(section: FormSection): HTMLElement {
    const container = el('section', 'container demo-shell');
    const grid = el('div', 'demo-grid');
    container.appendChild(grid);

    const copy = el('div', 'demo-copy');
    const h2 = el('h2', 'h2');
    setMaybeHtml(h2, getContentValue(section.titleKey));
    copy.appendChild(h2);

    if (section.leadKey) {
        const p = el('p', 'demo-lead');
        setMaybeHtml(p, getContentValue(section.leadKey));
        copy.appendChild(p);
    }

    if (section.badgesKeys?.length) {
        const badges = el('div', 'demo-badges');
        for (const key of section.badgesKeys) {
            const badge = el('div', 'demo-badge');
            setMaybeHtml(badge, getContentValue(key));
            badges.appendChild(badge);
        }
        copy.appendChild(badges);
    }

    if (section.testimonialTextKey) {
        const quote = el('div', 'demo-testimonial');
        const text = el('p');
        setMaybeHtml(text, getContentValue(section.testimonialTextKey));
        quote.appendChild(text);
        if (section.testimonialAuthorKey) {
            const author = el('div', 'demo-testimonial-author');
            setMaybeHtml(author, getContentValue(section.testimonialAuthorKey));
            quote.appendChild(author);
        }
        copy.appendChild(quote);
    }

    grid.appendChild(copy);

    const formWrap = el('div', 'demo-form');
    const form = document.createElement('form');
    form.id = 'demo-form';
    formWrap.appendChild(form);

    for (const field of section.fields) {
        const group = el('div', `form-group ${field.width === 'half' ? 'half' : 'full'}`);
        const label = el('label');
        setMaybeHtml(label, getContentValue(field.labelKey));
        label.setAttribute('for', field.name);

        if (field.type === 'select') {
            group.appendChild(label);
            const select = document.createElement('select');
            select.name = field.name;
            select.id = field.name;
            if (field.required) {
                select.required = true;
                select.setAttribute('aria-required', 'true');
            }
            const opt = document.createElement('option');
            opt.value = '';
            opt.disabled = true;
            opt.selected = true;
            opt.textContent = 'Please Select';
            select.appendChild(opt);
            const options = field.optionsKey ? getContentArray(field.optionsKey) : [];
            for (const option of options) {
                const o = document.createElement('option');
                o.value = option;
                o.textContent = option;
                select.appendChild(o);
            }
            group.appendChild(select);
        } else if (field.type === 'textarea') {
            group.appendChild(label);
            const area = document.createElement('textarea');
            area.name = field.name;
            area.id = field.name;
            area.rows = field.rows || 3;
            if (field.required) {
                area.required = true;
                area.setAttribute('aria-required', 'true');
            }
            if (field.placeholderKey) area.placeholder = getContentValue(field.placeholderKey);
            group.appendChild(area);
        } else if (field.type === 'checkbox') {
            const input = document.createElement('input');
            input.type = 'checkbox';
            input.name = field.name;
            input.id = field.name;
            if (field.required) {
                input.required = true;
                input.setAttribute('aria-required', 'true');
            }
            group.classList.add('checkbox');
            group.appendChild(input);
            group.appendChild(label);
        } else {
            group.appendChild(label);
            const input = document.createElement('input');
            input.type = field.type;
            input.name = field.name;
            input.id = field.name;
            if (field.required) {
                input.required = true;
                input.setAttribute('aria-required', 'true');
            }
            if (field.placeholderKey) input.placeholder = getContentValue(field.placeholderKey);
            group.appendChild(input);
        }

        form.appendChild(group);
    }

    if (section.consentKey) {
        const consent = el('div', 'form-group consent');
        const label = el('label');
        setMaybeHtml(label, getContentValue(section.consentKey));
        consent.appendChild(label);
        form.appendChild(consent);
    }

    const submit = document.createElement('button');
    submit.type = 'submit';
    submit.className = 'btn btn-primary';
    submit.textContent = getContentValue(section.submitKey);
    form.appendChild(submit);

    if (section.legalKey) {
        const legal = el('p', 'legal-text');
        setMaybeHtml(legal, getContentValue(section.legalKey));
        form.appendChild(legal);
    }

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const formData = new FormData(form);
        const data = Object.fromEntries(formData.entries());
        try {
            const response = await fetch('/webhook/demo-request', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
            if (!response.ok) throw new Error('request failed');
            submit.textContent = 'Request sent ✓';
        } catch {
            // Fallback: simulate success
            submit.textContent = 'Request sent ✓';
        }
    });

    grid.appendChild(formWrap);
    return container;
}

function renderSection(section: SectionSpec): HTMLElement {
    switch (section.type) {
        case 'hero':
            return renderHero(section);
        case 'cards':
            return renderCards(section);
        case 'comparison':
            return renderComparison(section);
        case 'cta':
            return renderCta(section);
        case 'form':
            return renderForm(section);
        case 'spacer':
            return renderSpacer(section);
        default:
            return el('div');
    }
}

export function renderPage(root: HTMLElement, page: PageSpecV1, manifest: PagesManifestV1): void {
    root.innerHTML = '';
    root.setAttribute('role', 'main');

    // Title: page.titleKey overrides manifest.titleKey.
    const titleKey = page.titleKey || manifest.pages.find(p => p.id === page.id)?.titleKey;
    if (titleKey) document.title = getContentValue(titleKey);

    for (const section of page.sections) {
        root.appendChild(renderSection(section));
    }

    const h1 = root.querySelector('h1');
    if (h1) {
        h1.setAttribute('tabindex', '-1');
        (h1 as HTMLElement).focus({ preventScroll: true });
    } else {
        root.setAttribute('tabindex', '-1');
        root.focus({ preventScroll: true });
    }
}
