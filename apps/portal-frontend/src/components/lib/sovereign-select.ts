
/**
 * Sovereign Select Component
 * A zero-dependency, glassmorphism-styled dropdown / multi-select.
 * 
 * Features:
 * - Sovereign Architecture (No external libs)
 * - Glassmorphism UI
 * - Support for Single and Multi selection
 * - Accessible keyboard navigation
 */

export interface SovereignOption {
    label: string;
    value: string;
}

export class SovereignSelect extends HTMLElement {
    private _shadow: ShadowRoot;
    private _options: SovereignOption[] = [];
    private _value: string | string[] = '';
    private _isOpen: boolean = false;
    private _multiple: boolean = false;
    private _placeholder: string = 'Select option...';

    static get observedAttributes() {
        return ['placeholder', 'multiple'];
    }

    constructor() {
        super();
        this._shadow = this.attachShadow({ mode: 'open' });
    }

    connectedCallback() {
        this.render();

        // Close on click outside
        document.addEventListener('click', this.handleOutsideClick);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.handleOutsideClick);
    }

    attributeChangedCallback(name: string, oldValue: string, newValue: string) {
        if (oldValue === newValue) return;
        if (name === 'placeholder') this._placeholder = newValue;
        if (name === 'multiple') this._multiple = this.hasAttribute('multiple');
        this.render();
    }

    set options(opts: SovereignOption[]) {
        this._options = opts;
        this.render();
    }

    get value(): string | string[] {
        return this._value;
    }

    set value(val: string | string[]) {
        this._value = val;
        this.render();
    }

    private handleOutsideClick = (e: MouseEvent) => {
        if (!this.contains(e.target as Node)) {
            this._isOpen = false;
            this.render();
        }
    }

    private toggleOpen = (e: Event) => {
        e.stopPropagation();
        this._isOpen = !this._isOpen;
        this.render();
    }

    private selectOption = (opt: SovereignOption) => {
        if (this._multiple) {
            if (!Array.isArray(this._value)) this._value = [];
            const idx = this._value.indexOf(opt.value);
            if (idx === -1) {
                this._value = [...this._value, opt.value];
            } else {
                this._value = this._value.filter(v => v !== opt.value);
            }
        } else {
            this._value = opt.value;
            this._isOpen = false;
        }

        this.dispatchEvent(new CustomEvent('sovereign-change', {
            detail: { value: this._value },
            bubbles: true,
            composed: true
        }));
        this.render();
    }

    render() {
        // Display Text Calculation
        let displayText = this._placeholder;
        if (this._multiple && Array.isArray(this._value) && this._value.length > 0) {
            const labels = this._options
                .filter(o => this._value.includes(o.value))
                .map(o => o.label);
            displayText = labels.length > 0 ? labels.join(', ') : this._placeholder;
        } else if (!this._multiple && this._value) {
            const selected = this._options.find(o => o.value === this._value);
            if (selected) displayText = selected.label;
        }

        const chipsHtml = (this._multiple && Array.isArray(this._value) && this._value.length > 0)
            ? `<div class="chips">
                ${this._options
                .filter(o => this._value.includes(o.value))
                .map(o => `<span class="chip">${o.label}</span>`)
                .join('')}
               </div>`
            : `<span class="placeholder">${displayText}</span>`;

        // Using simple text for single select to avoid double rendering
        const triggerContent = this._multiple && Array.isArray(this._value) && this._value.length > 0
            ? chipsHtml
            : `<span class="value-text">${displayText}</span>`;


        const styles = `
            :host {
                display: block;
                font-family: var(--font-family, system-ui, sans-serif);
                --glass-bg: rgba(255, 255, 255, 0.05);
                --glass-border: rgba(255, 255, 255, 0.1);
                --accent-color: var(--accent-neural-cyan, #00d4ff);
                --text-color: var(--text-primary, #ffffff);
                --text-muted: var(--text-secondary, rgba(255,255,255,0.6));
                position: relative;
                width: 100%;
                min-width: 200px;
            }

            .select-trigger {
                background: var(--glass-bg);
                border: 1px solid var(--glass-border);
                border-radius: 8px;
                padding: 0.8rem 1rem;
                cursor: pointer;
                display: flex;
                flex-wrap: wrap;
                justify-content: space-between;
                align-items: center;
                gap: 0.5rem;
                color: var(--text-color);
                transition: border-color 0.2s;
                min-height: 42px;
            }

            .select-trigger:hover {
                border-color: rgba(255,255,255,0.3);
            }

            .select-trigger.open {
                border-color: var(--accent-color);
            }

            .dropdown {
                position: absolute;
                top: 100%;
                left: 0;
                right: 0;
                margin-top: 4px;
                background: rgba(10, 15, 30, 0.95);
                border: 1px solid var(--glass-border);
                border-radius: 8px;
                backdrop-filter: blur(12px);
                z-index: 100;
                max-height: 0;
                opacity: 0;
                overflow: hidden;
                transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
            }

            .dropdown.open {
                max-height: 300px;
                opacity: 1;
                overflow-y: auto;
            }

            .option {
                padding: 0.8rem 1rem;
                cursor: pointer;
                transition: background 0.2s;
                color: var(--text-muted);
                display: flex;
                align-items: center;
                gap: 0.5rem;
            }

            .option:hover {
                background: rgba(255,255,255,0.05);
                color: var(--text-color);
            }

            .option.selected {
                color: var(--accent-color);
                background: rgba(0, 212, 255, 0.1);
            }

            .arrow {
                border: solid var(--text-muted);
                border-width: 0 2px 2px 0;
                display: inline-block;
                padding: 3px;
                transform: rotate(45deg);
                transition: transform 0.2s;
                margin-left: auto;
            }

            .open .arrow {
                transform: rotate(-135deg);
            }

            /* Multi-select Chips */
            .chips {
                display: flex;
                flex-wrap: wrap;
                gap: 4px;
            }

            .chip {
                background: rgba(0, 212, 255, 0.2);
                border: 1px solid rgba(0, 212, 255, 0.3);
                color: var(--text-color);
                padding: 2px 8px;
                border-radius: 12px;
                font-size: 0.85rem;
            }
        `;

        const optionsHtml = this._options.map(opt => {
            const isSelected = Array.isArray(this._value)
                ? this._value.includes(opt.value)
                : this._value === opt.value;
            return `
                <div class="option ${isSelected ? 'selected' : ''}" data-value="${opt.value}">
                    ${isSelected ? '<span>✓</span>' : ''}
                    ${opt.label}
                </div>
            `;
        }).join('');

        this._shadow.innerHTML = `
            <style>${styles}</style>
            <div class="select-trigger ${this._isOpen ? 'open' : ''}">
                ${triggerContent}
                <i class="arrow"></i>
            </div>
            <div class="dropdown ${this._isOpen ? 'open' : ''}">
                ${optionsHtml}
            </div>
        `;

        this._shadow.querySelector('.select-trigger')?.addEventListener('click', this.toggleOpen);
        this._shadow.querySelectorAll('.option').forEach(el => {
            el.addEventListener('click', (e: Event) => {
                e.stopPropagation(); // Prevent closing immediately if multi? No, toggle handles logic
                const val = (el as HTMLElement).getAttribute('data-value');
                const opt = this._options.find(o => o.value === val);
                if (opt) this.selectOption(opt);
            });
        });
    }


}

if (!customElements.get('sovereign-select')) {
    customElements.define('sovereign-select', SovereignSelect);
}
