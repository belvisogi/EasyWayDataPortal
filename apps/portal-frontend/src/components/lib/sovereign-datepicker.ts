
/**
 * Sovereign Datepicker Component
 * A zero-dependency, glassmorphism-styled datepicker.
 * 
 * Features:
 * - Sovereign Architecture (No external libs)
 * - Glassmorphism UI
 * - Accessible Keyboarding (Basic)
 * - Custom "sovereign-change" event
 */

export class SovereignDatepicker extends HTMLElement {
    private _internals: ElementInternals | null = null;
    private _shadow: ShadowRoot;
    private _value: Date = new Date();
    private _currentMonth: number = new Date().getMonth();
    private _currentYear: number = new Date().getFullYear();

    static get observedAttributes() {
        return ['value', 'min', 'max', 'locale'];
    }

    constructor() {
        super();
        this._shadow = this.attachShadow({ mode: 'open' });
        // ElementInternals for form participation (if needed later)
        // this._internals = this.attachInternals(); 
    }

    connectedCallback() {
        this.render();
        this.addEventListeners();
    }

    attributeChangedCallback(name: string, oldValue: string, newValue: string) {
        if (oldValue === newValue) return;

        if (name === 'value' && newValue) {
            const date = new Date(newValue);
            if (!isNaN(date.getTime())) {
                this._value = date;
                this._currentMonth = date.getMonth();
                this._currentYear = date.getFullYear();
                this.render();
            }
        }
    }

    get value(): Date {
        return this._value;
    }

    set value(val: Date) {
        this._value = val;
        this.setAttribute('value', val.toISOString());
        this.render();
    }

    private addEventListeners() {
        // Shadow DOM events leverage event delegation where possible in render()
    }

    private handlePrevMonth = () => {
        if (this._currentMonth === 0) {
            this._currentMonth = 11;
            this._currentYear--;
        } else {
            this._currentMonth--;
        }
        this.render();
    }

    private handleNextMonth = () => {
        if (this._currentMonth === 11) {
            this._currentMonth = 0;
            this._currentYear++;
        } else {
            this._currentMonth++;
        }
        this.render();
    }

    private handleDateClick = (day: number) => {
        this._value = new Date(this._currentYear, this._currentMonth, day);
        this.dispatchEvent(new CustomEvent('sovereign-change', {
            detail: { value: this._value },
            bubbles: true,
            composed: true
        }));
        this.render();
    }

    private getDaysInMonth(month: number, year: number): number {
        return new Date(year, month + 1, 0).getDate();
    }

    private getFirstDayOfMonth(month: number, year: number): number {
        return new Date(year, month, 1).getDay();
    }

    render() {
        const locale = this.getAttribute('locale') || 'default';
        const monthName = new Intl.DateTimeFormat(locale, { month: 'long' }).format(new Date(this._currentYear, this._currentMonth));
        const daysInMonth = this.getDaysInMonth(this._currentMonth, this._currentYear);
        const firstDay = this.getFirstDayOfMonth(this._currentMonth, this._currentYear);

        // CSS Variables mapping from host context or defaults
        const style = `
            :host {
                display: inline-block;
                font-family: var(--font-family, system-ui, sans-serif);
                --glass-bg: rgba(255, 255, 255, 0.05);
                --glass-border: rgba(255, 255, 255, 0.1);
                --accent-color: var(--accent-neural-cyan, #00d4ff);
                --text-color: var(--text-primary, #ffffff);
                --text-muted: var(--text-secondary, #rgba(255,255,255,0.6));
            }

            .datepicker-card {
                background: var(--glass-bg);
                border: 1px solid var(--glass-border);
                backdrop-filter: blur(10px);
                border-radius: 12px;
                padding: 1rem;
                width: 300px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                color: var(--text-color);
                user-select: none;
            }

            .header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 1rem;
            }

            .month-title {
                font-weight: 600;
                font-size: 1.1rem;
                text-transform: capitalize;
            }

            .nav-btn {
                background: transparent;
                border: 1px solid var(--glass-border);
                color: var(--text-color);
                border-radius: 6px;
                width: 32px;
                height: 32px;
                cursor: pointer;
                transition: all 0.2s;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .nav-btn:hover {
                background: rgba(255,255,255,0.1);
                border-color: var(--accent-color);
            }

            .grid {
                display: grid;
                grid-template-columns: repeat(7, 1fr);
                gap: 4px;
                text-align: center;
            }

            .weekday {
                font-size: 0.8rem;
                color: var(--text-muted);
                margin-bottom: 0.5rem;
                font-weight: 500;
            }

            .day {
                aspect-ratio: 1;
                display: flex;
                align-items: center;
                justify-content: center;
                border-radius: 6px;
                cursor: pointer;
                font-size: 0.9rem;
                transition: all 0.2s;
            }

            .day:hover:not(.empty) {
                background: rgba(255,255,255,0.1);
            }

            .day.selected {
                background: var(--accent-color);
                color: #000;
                font-weight: 700;
            }

            .day.today {
                border: 1px solid var(--accent-color);
            }

            .empty {
                cursor: default;
            }
        `;

        const weekDays = [];
        // Generate weekdays (Starting Sunday for now, ideally locale aware)
        for (let i = 0; i < 7; i++) {
            const d = new Date(2024, 0, i + 7); // A known Sunday week
            weekDays.push(new Intl.DateTimeFormat(locale, { weekday: 'short' }).format(d));
        }

        const days = [];
        // Empty slots
        for (let i = 0; i < firstDay; i++) {
            days.push(`<div class="day empty"></div>`);
        }
        // Days
        for (let i = 1; i <= daysInMonth; i++) {
            const isSelected =
                this._value.getDate() === i &&
                this._value.getMonth() === this._currentMonth &&
                this._value.getFullYear() === this._currentYear;

            const isToday =
                new Date().getDate() === i &&
                new Date().getMonth() === this._currentMonth &&
                new Date().getFullYear() === this._currentYear;

            const classes = ['day'];
            if (isSelected) classes.push('selected');
            if (isToday) classes.push('today');

            days.push(`<div class="${classes.join(' ')}" data-day="${i}">${i}</div>`);
        }

        this._shadow.innerHTML = `
            <style>${style}</style>
            <div class="datepicker-card">
                <div class="header">
                    <button class="nav-btn prev" aria-label="Previous Month">&lt;</button>
                    <div class="month-title">${monthName} ${this._currentYear}</div>
                    <button class="nav-btn next" aria-label="Next Month">&gt;</button>
                </div>
                <div class="grid">
                    ${weekDays.map(d => `<div class="weekday">${d}</div>`).join('')}
                    ${days.join('')}
                </div>
            </div>
        `;

        // Bind events
        this._shadow.querySelector('.prev')?.addEventListener('click', this.handlePrevMonth);
        this._shadow.querySelector('.next')?.addEventListener('click', this.handleNextMonth);
        this._shadow.querySelectorAll('.day:not(.empty)').forEach(el => {
            el.addEventListener('click', () => {
                this.handleDateClick(parseInt(el.getAttribute('data-day')!));
            });
        });
    }
}

// Define component
if (!customElements.get('sovereign-datepicker')) {
    customElements.define('sovereign-datepicker', SovereignDatepicker);
}
