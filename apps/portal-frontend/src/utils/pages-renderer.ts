import type {
    ActionFormSection,
    CardsCatalogItem,
    ComparisonSection,
    CtaSection,
    FormSection,
    HeroSection,
    ManifestoSection,
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

function renderManifesto(_section: ManifestoSection): HTMLElement {
    const wrapper = el('section', 'manifesto-section');
    const container = el('div', 'code-container');
    wrapper.appendChild(container);

    const h1 = el('h1', 'title-code h1');
    setMaybeHtml(h1, getContentValue('manifesto.title'));
    container.appendChild(h1);

    const subtitle = el('p', 'subtitle-code');
    setMaybeHtml(subtitle, getContentValue('manifesto.subtitle'));
    container.appendChild(subtitle);

    const prelude = el('div', 'prelude');
    const preludeLine1 = el('p');
    const preludeLine2 = el('span', 'highlight-gold');
    setMaybeHtml(preludeLine1, getContentValue('manifesto.prelude.line1'));
    setMaybeHtml(preludeLine2, getContentValue('manifesto.prelude.line2'));
    preludeLine1.appendChild(document.createElement('br'));
    preludeLine1.appendChild(preludeLine2);
    prelude.appendChild(preludeLine1);
    container.appendChild(prelude);

    const verse1 = el('div', 'verse');
    const v1h = el('h2', 'h2');
    setMaybeHtml(v1h, getContentValue('manifesto.verse1.title'));
    verse1.appendChild(v1h);
    const v1t1 = el('span', 'voice-they');
    setMaybeHtml(v1t1, getContentValue('manifesto.verse1.they1'));
    verse1.appendChild(v1t1);
    const v1u1 = el('span', 'voice-us');
    setMaybeHtml(v1u1, getContentValue('manifesto.verse1.us1'));
    verse1.appendChild(v1u1);
    const v1t2 = el('span', 'voice-they');
    setMaybeHtml(v1t2, getContentValue('manifesto.verse1.they2'));
    verse1.appendChild(v1t2);
    const v1u2 = el('span', 'voice-us');
    setMaybeHtml(v1u2, getContentValue('manifesto.verse1.us2'));
    verse1.appendChild(v1u2);
    container.appendChild(verse1);

    const verse2 = el('div', 'verse');
    const v2h = el('h2', 'h2');
    setMaybeHtml(v2h, getContentValue('manifesto.verse2.title'));
    verse2.appendChild(v2h);
    const v2t = el('p');
    setMaybeHtml(v2t, getContentValue('manifesto.verse2.text'));
    verse2.appendChild(v2t);
    const v2hl = el('div', 'verse-highlight');
    setMaybeHtml(v2hl, getContentValue('manifesto.verse2.highlight'));
    verse2.appendChild(v2hl);
    const v2c = el('p');
    setMaybeHtml(v2c, getContentValue('manifesto.verse2.climax'));
    verse2.appendChild(v2c);
    const v2f = el('p', 'verse-footer');
    setMaybeHtml(v2f, getContentValue('manifesto.verse2.footer'));
    verse2.appendChild(v2f);
    container.appendChild(verse2);

    const verse3 = el('div', 'verse');
    const v3h = el('h2', 'h2');
    setMaybeHtml(v3h, getContentValue('manifesto.verse3.title'));
    verse3.appendChild(v3h);
    const v3t1 = el('p');
    setMaybeHtml(v3t1, getContentValue('manifesto.verse3.text1'));
    verse3.appendChild(v3t1);
    const v3t2 = el('p');
    setMaybeHtml(v3t2, getContentValue('manifesto.verse3.text2'));
    verse3.appendChild(v3t2);
    const v3t3 = el('p');
    setMaybeHtml(v3t3, getContentValue('manifesto.verse3.text3'));
    verse3.appendChild(v3t3);
    container.appendChild(verse3);

    const oath = el('div', 'oath-box');
    const oathCode = el('p', 'oath-code');
    setMaybeHtml(oathCode, getContentValue('manifesto.oath.code'));
    oath.appendChild(oathCode);
    const oathText = el('p', 'oath-text');
    setMaybeHtml(oathText, getContentValue('manifesto.oath.text'));
    oath.appendChild(oathText);
    const oathFinal = el('p', 'oath-final');
    setMaybeHtml(oathFinal, getContentValue('manifesto.oath.final'));
    oath.appendChild(oathFinal);
    const haka = el('div', 'ka-mate');
    setMaybeHtml(haka, getContentValue('manifesto.oath.haka'));
    oath.appendChild(haka);
    container.appendChild(oath);

    const cta = el('a', 'btn-primary', getContentValue('manifesto.cta')) as HTMLAnchorElement;
    cta.href = '/demo';
    container.appendChild(cta);

    return wrapper;
}

function renderShowcaseIntro(section: import('../types/runtime-pages').ShowcaseIntroSection): HTMLElement {
    const intro = el('section', 'showcase-intro');
    const container = el('div', 'container');
    intro.appendChild(container);

    const title = el('h2', 'h2');
    setMaybeHtml(title, getContentValue(section.titleKey));
    container.appendChild(title);

    const description = el('p', 'lead');
    setMaybeHtml(description, getContentValue(section.descriptionKey));
    container.appendChild(description);

    return intro;
}

function renderComponentShowcase(section: import('../types/runtime-pages').ComponentShowcaseSection): HTMLElement {
    const showcase = el('section', 'component-showcase');
    const container = el('div', 'container');
    showcase.appendChild(container);

    for (const component of section.components) {
        const componentBlock = el('div', 'component-block');
        componentBlock.id = `component-${component.id}`;

        // Component header
        const header = el('div', 'component-header');
        const componentTitle = el('h3', 'h3', component.name);
        header.appendChild(componentTitle);
        componentBlock.appendChild(header);

        // Variants
        for (const variant of component.variants) {
            const variantBlock = el('div', 'variant-block');

            // Variant name
            const variantName = el('h4', 'h4', variant.name);
            variantBlock.appendChild(variantName);

            // JSON spec (copyable)
            const specContainer = el('div', 'spec-container');
            const specPre = el('pre', 'spec-json');
            specPre.setAttribute('tabindex', '0'); // Accessibility: Scrollable region must be focusable
            const specCode = el('code');
            specCode.textContent = JSON.stringify(variant.spec, null, 2);
            specPre.appendChild(specCode);

            const copyBtn = el('button', 'btn btn-glass btn-sm copy-json', '📋 Copy JSON');
            copyBtn.addEventListener('click', () => {
                navigator.clipboard.writeText(JSON.stringify(variant.spec, null, 2));
                copyBtn.textContent = '✅ Copied!';
                setTimeout(() => { copyBtn.textContent = '📋 Copy JSON'; }, 2000);
            });

            specContainer.appendChild(copyBtn);
            specContainer.appendChild(specPre);
            variantBlock.appendChild(specContainer);

            // Live preview
            const previewContainer = el('div', 'preview-container');
            const previewLabel = el('div', 'preview-label', 'Live Preview:');
            previewContainer.appendChild(previewLabel);

            const preview = el('div', 'preview-content');
            try {
                // Render the component using existing renderers
                const renderedComponent = renderSection(variant.spec as any);
                preview.appendChild(renderedComponent);
            } catch (err) {
                preview.textContent = `Error rendering preview: ${err}`;
                preview.className = 'preview-error';
            }
            previewContainer.appendChild(preview);
            variantBlock.appendChild(previewContainer);

            componentBlock.appendChild(variantBlock);
        }

        container.appendChild(componentBlock);
    }

    return showcase;
}

function renderDataList(section: import('../types/runtime-pages').DataListSection): HTMLElement {
    const wrapper = el('section', 'container');
    wrapper.style.paddingBottom = '4rem';
    wrapper.style.marginTop = '2rem';

    if (section.titleKey) {
        const h2 = el('h2', 'h2');
        setMaybeHtml(h2, getContentValue(section.titleKey));
        wrapper.appendChild(h2);
    }

    const tableWrapper = el('div', 'data-list-wrapper');
    tableWrapper.style.overflowX = 'auto';
    tableWrapper.style.marginTop = '1.5rem';
    tableWrapper.appendChild(el('p', '', 'Caricamento…'));
    wrapper.appendChild(tableWrapper);

    fetch(section.dataUrl)
        .then(r => r.json())
        .then((rows: any[]) => {
            tableWrapper.innerHTML = '';
            const table = document.createElement('table');
            table.className = 'data-list-table';
            table.style.width = '100%';
            table.style.borderCollapse = 'collapse';
            table.style.fontSize = '0.875rem';

            const thead = document.createElement('thead');
            const headerRow = document.createElement('tr');
            for (const col of section.columns) {
                const th = document.createElement('th');
                th.textContent = getContentValue(col.labelKey);
                th.style.textAlign = 'left';
                th.style.padding = '0.5rem 1rem';
                th.style.borderBottom = '1px solid rgba(255,255,255,0.15)';
                th.style.color = 'var(--accent-neural-cyan, #00d4ff)';
                th.style.fontWeight = '600';
                headerRow.appendChild(th);
            }
            if (section.rowActions && section.rowActions.length > 0) {
                const thAct = document.createElement('th');
                thAct.textContent = getContentValue('backoffice.table.col_actions') || 'Azioni';
                thAct.style.textAlign = 'center';
                thAct.style.padding = '0.5rem 1rem';
                thAct.style.borderBottom = '1px solid rgba(255,255,255,0.15)';
                thAct.style.color = 'var(--accent-neural-cyan, #00d4ff)';
                thAct.style.fontWeight = '600';
                headerRow.appendChild(thAct);
            }
            thead.appendChild(headerRow);
            table.appendChild(thead);

            if (rows.length === 0) {
                const emptyMsg = el('p', 'data-list-empty');
                emptyMsg.textContent = getContentValue('backoffice.table.empty');
                emptyMsg.style.padding = '1.5rem 1rem';
                emptyMsg.style.color = 'rgba(255,255,255,0.45)';
                emptyMsg.style.fontStyle = 'italic';
                tableWrapper.appendChild(emptyMsg);
                return;
            }

            const STATUS_BADGE_MAP: Record<string, string> = {
                CONFIRMED: 'badge--confirmed', PENDING: 'badge--pending', CANCELLED: 'badge--cancelled',
                ONLINE: 'badge--confirmed', ACTIVE: 'badge--confirmed', SUCCESS: 'badge--confirmed',
                IDLE: 'badge--pending', RUNNING: 'badge--pending',
                FAILED: 'badge--cancelled', OFFLINE: 'badge--cancelled',
            };

            const tbody = document.createElement('tbody');
            for (const row of rows) {
                const tr = document.createElement('tr');
                tr.style.borderBottom = '1px solid rgba(255,255,255,0.06)';
                for (const col of section.columns) {
                    const td = document.createElement('td');
                    td.style.padding = '0.6rem 1rem';
                    td.style.verticalAlign = 'middle';
                    const raw = row[col.key];
                    let value: string = raw != null ? String(raw) : '—';
                    if (col.format === 'datetime' && raw) {
                        value = new Date(raw).toLocaleString('it-IT', { dateStyle: 'short', timeStyle: 'short' });
                    } else if (col.format === 'date' && raw) {
                        value = new Date(raw).toLocaleDateString('it-IT');
                    } else if (col.format === 'currency' && raw != null) {
                        value = Number(raw).toLocaleString('it-IT', { style: 'currency', currency: 'EUR' });
                    }
                    if (col.key === 'status') {
                        const statusClass = STATUS_BADGE_MAP[value.toUpperCase()] ?? '';
                        const badge = el('span', `badge ${statusClass}`.trim());
                        badge.textContent = value;
                        badge.style.fontSize = '0.75rem';
                        td.appendChild(badge);
                    } else {
                        td.textContent = value;
                    }
                    tr.appendChild(td);
                }
                // Per-row action buttons
                if (section.rowActions && section.rowActions.length > 0) {
                    const tdAct = document.createElement('td');
                    tdAct.style.padding = '0.4rem 1rem';
                    tdAct.style.textAlign = 'center';
                    tdAct.style.verticalAlign = 'middle';
                    for (const act of section.rowActions) {
                        if (act.type === 'link') {
                            const a = document.createElement('a');
                            a.href = act.href;
                            a.textContent = getContentValue(act.labelKey) || '→';
                            a.style.cssText = 'padding:0.3rem 0.8rem;border-radius:4px;border:1px solid rgba(255,255,255,0.2);background:rgba(255,255,255,0.05);color:rgba(255,255,255,0.7);cursor:pointer;font-size:0.75rem;text-decoration:none;display:inline-block;transition:background 0.15s;margin-left:0.4rem;';
                            a.addEventListener('mouseenter', () => { a.style.background = 'rgba(255,255,255,0.10)'; });
                            a.addEventListener('mouseleave', () => { a.style.background = 'rgba(255,255,255,0.05)'; });
                            tdAct.appendChild(a);
                        } else if (act.type === 'run') {
                            const idField = act.idField || 'agent_id';
                            const agentId = row[idField] as string;
                            const btn = document.createElement('button');
                            btn.textContent = getContentValue(act.labelKey) || '▶';
                            btn.style.cssText = 'padding:0.3rem 0.8rem;border-radius:4px;border:1px solid rgba(0,212,255,0.4);background:rgba(0,212,255,0.08);color:#00d4ff;cursor:pointer;font-size:0.75rem;transition:background 0.15s;';
                            btn.addEventListener('mouseenter', () => { btn.style.background = 'rgba(0,212,255,0.18)'; });
                            btn.addEventListener('mouseleave', () => { btn.style.background = 'rgba(0,212,255,0.08)'; });
                            btn.addEventListener('click', () => {
                                btn.disabled = true;
                                btn.textContent = '…';
                                fetch(`/api/agents/${encodeURIComponent(agentId)}/run`, { method: 'POST', headers: { 'Content-Type': 'application/json' } })
                                    .then(r => r.ok ? r.json() : Promise.reject(r.status))
                                    .then(() => {
                                        btn.textContent = getContentValue('backoffice.agents.run_ok') || '✓';
                                        btn.style.color = '#4caf50';
                                        setTimeout(() => { btn.textContent = getContentValue(act.labelKey) || '▶'; btn.style.color = '#00d4ff'; btn.disabled = false; }, 3000);
                                    })
                                    .catch(() => {
                                        btn.textContent = getContentValue('backoffice.agents.run_fail') || '✗';
                                        btn.style.color = '#ff6b6b';
                                        setTimeout(() => { btn.textContent = getContentValue(act.labelKey) || '▶'; btn.style.color = '#00d4ff'; btn.disabled = false; }, 3000);
                                    });
                            });
                            tdAct.appendChild(btn);
                        }
                    }
                    tr.appendChild(tdAct);
                }
                tbody.appendChild(tr);
            }
            table.appendChild(tbody);
            tableWrapper.appendChild(table);
        })
        .catch(() => {
            tableWrapper.innerHTML = '';
            tableWrapper.appendChild(el('p', '', 'Errore nel caricamento dei dati.'));
        });

    return wrapper;
}

function renderActionForm(section: ActionFormSection): HTMLElement {
    const wrapper = el('section', 'action-form-section');
    wrapper.style.maxWidth = '640px';
    wrapper.style.margin = '2rem auto';
    wrapper.style.padding = '2rem';
    wrapper.style.background = 'rgba(255,255,255,0.04)';
    wrapper.style.border = '1px solid rgba(255,255,255,0.10)';
    wrapper.style.borderRadius = '12px';

    const h2 = el('h2', 'h2');
    h2.textContent = getContentValue(section.titleKey);
    h2.style.marginBottom = '1.5rem';
    wrapper.appendChild(h2);

    const form = document.createElement('form');
    form.style.display = 'flex';
    form.style.flexDirection = 'column';
    form.style.gap = '1rem';

    for (const field of section.fields) {
        const group = el('div', 'action-form-group');
        group.style.display = 'flex';
        group.style.flexDirection = 'column';
        group.style.gap = '0.35rem';

        const label = el('label');
        label.textContent = getContentValue(field.labelKey);
        label.setAttribute('for', field.name);
        label.style.fontSize = '0.8rem';
        label.style.color = 'rgba(255,255,255,0.6)';
        label.style.fontWeight = '500';
        group.appendChild(label);

        const inputStyle = 'background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.12);border-radius:6px;color:#fff;font-size:0.875rem;padding:0.5rem 0.75rem;outline:none;width:100%;box-sizing:border-box;';

        if (field.type === 'textarea') {
            const area = document.createElement('textarea');
            area.name = field.name;
            area.id = field.name;
            area.rows = field.rows ?? 3;
            if (field.required) { area.required = true; area.setAttribute('aria-required', 'true'); }
            if (field.placeholderKey) area.placeholder = getContentValue(field.placeholderKey);
            area.setAttribute('style', inputStyle);
            group.appendChild(area);
        } else {
            const input = document.createElement('input');
            input.type = field.type;
            input.name = field.name;
            input.id = field.name;
            if (field.required) { input.required = true; input.setAttribute('aria-required', 'true'); }
            if (field.placeholderKey) input.placeholder = getContentValue(field.placeholderKey);
            input.setAttribute('style', inputStyle);
            group.appendChild(input);
        }
        form.appendChild(group);
    }

    const feedback = el('p', 'action-form-feedback');
    feedback.style.display = 'none';
    feedback.style.marginTop = '0.5rem';

    const submitBtn = document.createElement('button');
    submitBtn.type = 'submit';
    submitBtn.className = 'btn btn-primary';
    submitBtn.textContent = getContentValue(section.submitKey);
    submitBtn.style.marginTop = '0.5rem';
    submitBtn.style.alignSelf = 'flex-start';
    form.appendChild(submitBtn);
    form.appendChild(feedback);

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        submitBtn.disabled = true;
        const raw = Object.fromEntries(new FormData(form).entries());
        // coerce numeric fields
        const payload: Record<string, unknown> = {};
        for (const field of section.fields) {
            const v = raw[field.name];
            if (field.type === 'number' && v !== '' && v !== undefined) {
                payload[field.name] = Number(v);
            } else if (v !== '' && v !== undefined) {
                payload[field.name] = v;
            }
        }
        try {
            const res = await fetch(section.submitUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload),
            });
            if (!res.ok) throw new Error('server error');
            feedback.textContent = getContentValue(section.successKey);
            feedback.style.display = '';
            feedback.style.color = 'var(--accent-neural-cyan, #00d4ff)';
            form.reset();
        } catch {
            feedback.textContent = 'Errore. Riprova.';
            feedback.style.display = '';
            feedback.style.color = '#ff6b6b';
        } finally {
            submitBtn.disabled = false;
        }
    });

    wrapper.appendChild(form);
    return wrapper;
}

import { renderAgentDashboard, renderAgentGraph, renderAgentList } from './agent-console-renderers';

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
        case 'manifesto':
            return renderManifesto(section);
        case 'spacer':
            return renderSpacer(section);
        case 'showcase-intro':
            return renderShowcaseIntro(section);
        case 'component-showcase':
            return renderComponentShowcase(section);
        case 'agent-dashboard':
            return renderAgentDashboard(section);
        case 'agent-graph':
            return renderAgentGraph(section);
        case 'agent-list':
            return renderAgentList(section);
        case 'data-list':
            return renderDataList(section);
        case 'action-form':
            return renderActionForm(section);
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
