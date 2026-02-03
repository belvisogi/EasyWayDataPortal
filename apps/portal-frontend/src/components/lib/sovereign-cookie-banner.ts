
/**
 * Sovereign Cookie Banner (The Gatekeeper)
 * GDPR-ready, zero-dependency consent manager.
 * 
 * Storage Key: 'sovereign-consent'
 * Event: 'sovereign-consent-updated'
 */

export interface ConsentState {
    necessary: boolean;
    analytics: boolean;
    marketing: boolean;
    timestamp: number;
}

export class SovereignCookieBanner extends HTMLElement {
    private _shadow: ShadowRoot;
    private _isOpen: boolean = false;
    private _showDetails: boolean = false;
    private _consent: ConsentState = {
        necessary: true,
        analytics: false,
        marketing: false,
        timestamp: 0
    };

    constructor() {
        super();
        this._shadow = this.attachShadow({ mode: 'open' });
    }

    connectedCallback() {
        this.checkConsent();
        this.render();
    }

    private checkConsent() {
        const stored = localStorage.getItem('sovereign-consent');
        if (stored) {
            try {
                this._consent = JSON.parse(stored);
                this._isOpen = false;
                this.emitConsent();
            } catch (e) {
                console.error('Invalid consent data', e);
                this._isOpen = true;
            }
        } else {
            this._isOpen = true;
        }
        this.render();
    }

    private saveConsent(analytics: boolean, marketing: boolean) {
        this._consent = {
            necessary: true,
            analytics,
            marketing,
            timestamp: Date.now()
        };
        localStorage.setItem('sovereign-consent', JSON.stringify(this._consent));
        this._isOpen = false;
        this.emitConsent();
        this.render();
    }

    private emitConsent() {
        window.dispatchEvent(new CustomEvent('sovereign-consent-updated', {
            detail: this._consent,
            bubbles: true,
            composed: true
        }));
    }

    private handleAcceptAll = () => this.saveConsent(true, true);
    private handleRejectAll = () => this.saveConsent(false, false);

    private handleSavePreferences = () => {
        const analytics = (this._shadow.getElementById('chk-analytics') as HTMLInputElement)?.checked || false;
        const marketing = (this._shadow.getElementById('chk-marketing') as HTMLInputElement)?.checked || false;
        this.saveConsent(analytics, marketing);
    }

    private toggleDetails = () => {
        this._showDetails = !this._showDetails;
        this.render();
    }

    render() {
        // If not open, render nothing (or a small trigger if we wanted one, but usually banners hide)
        if (!this._isOpen) {
            this._shadow.innerHTML = '';
            return;
        }

        const styles = `
            :host {
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                z-index: 10000;
                font-family: var(--font-family, system-ui, sans-serif);
                --glass-bg: rgba(6, 11, 19, 0.95);
                --glass-border: rgba(255, 255, 255, 0.1);
                --accent-color: var(--accent-neural-cyan, #00d4ff);
                --text-color: #ffffff;
                --text-muted: rgba(255,255,255,0.7);
            }

            .banner {
                background: var(--glass-bg);
                border-top: 1px solid var(--glass-border);
                backdrop-filter: blur(16px);
                color: var(--text-color);
                box-shadow: 0 -10px 40px rgba(0,0,0,0.5);
                padding: 1.5rem;
                display: flex;
                flex-direction: column;
                gap: 1.5rem;
                transform: translateY(100%);
                animation: slideUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
            }

            @keyframes slideUp {
                to { transform: translateY(0); }
            }

            .header {
                max-width: 800px;
                margin: 0 auto;
                text-align: center;
            }

            h2 {
                margin: 0 0 0.5rem 0;
                font-size: 1.25rem;
            }

            p {
                margin: 0;
                color: var(--text-muted);
                font-size: 0.9rem;
                line-height: 1.5;
            }

            .actions {
                display: flex;
                justify-content: center;
                gap: 1rem;
                flex-wrap: wrap;
            }

            button {
                background: rgba(255,255,255,0.1);
                border: 1px solid rgba(255,255,255,0.2);
                color: white;
                padding: 0.8rem 1.5rem;
                border-radius: 8px;
                cursor: pointer;
                font-size: 0.9rem;
                font-weight: 600;
                transition: all 0.2s;
            }

            button:hover {
                background: rgba(255,255,255,0.2);
                transform: translateY(-2px);
            }

            button.primary {
                background: var(--accent-color);
                border-color: var(--accent-color);
                color: #000; /* Contrast for cyan */
            }

            button.primary:hover {
                background: #33ddff;
            }

            .details {
                background: rgba(0,0,0,0.3);
                border-radius: 8px;
                padding: 1rem;
                max-width: 800px;
                margin: 0 auto;
                width: 100%;
                display: grid;
                gap: 1rem;
            }

            .preference-row {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 0.5rem 0;
                border-bottom: 1px solid rgba(255,255,255,0.1);
            }

            .preference-row:last-child {
                border-bottom: none;
            }

            .switch {
                position: relative;
                display: inline-block;
                width: 40px;
                height: 24px;
            }
            .switch input { opacity: 0; width: 0; height: 0; }
            .slider {
                position: absolute;
                cursor: pointer;
                top: 0; left: 0; right: 0; bottom: 0;
                background-color: #555;
                transition: .4s;
                border-radius: 24px;
            }
            .slider:before {
                position: absolute;
                content: "";
                height: 16px;
                width: 16px;
                left: 4px;
                bottom: 4px;
                background-color: white;
                transition: .4s;
                border-radius: 50%;
            }
            input:checked + .slider { background-color: var(--accent-color); }
            input:checked + .slider:before { transform: translateX(16px); }
            input:disabled + .slider { opacity: 0.5; cursor: not-allowed; }
        `;

        const detailsHtml = this._showDetails ? `
            <div class="details">
                <div class="preference-row">
                    <span>Necessary (Core System)</span>
                    <label class="switch">
                        <input type="checkbox" checked disabled>
                        <span class="slider"></span>
                    </label>
                </div>
                <div class="preference-row">
                    <span>Analytics (Anonymous)</span>
                    <label class="switch">
                        <input type="checkbox" id="chk-analytics">
                        <span class="slider"></span>
                    </label>
                </div>
                <div class="preference-row">
                    <span>Marketing (Personalization)</span>
                    <label class="switch">
                        <input type="checkbox" id="chk-marketing">
                        <span class="slider"></span>
                    </label>
                </div>
                <div class="actions" style="justify-content: flex-end; margin-top: 1rem;">
                    <button id="btn-save-pref">Save Preferences</button>
                </div>
            </div>
        ` : '';

        this._shadow.innerHTML = `
            <style>${styles}</style>
            <div class="banner">
                <div class="header">
                    <h2>🔒 Sovereign Privacy</h2>
                    <p>
                        We use minimal protocols to ensure the integrity of the Gateway.
                        We do not track you without your explicit Sovereign Consent.
                    </p>
                </div>
                
                ${detailsHtml}

                ${!this._showDetails ? `
                <div class="actions">
                    <button id="btn-customize">Customize</button>
                    <button id="btn-reject">Reject All</button>
                    <button id="btn-accept" class="primary">Accept All</button>
                </div>
                ` : ''}
            </div>
        `;

        // Bind events
        if (!this._showDetails) {
            this._shadow.getElementById('btn-accept')?.addEventListener('click', this.handleAcceptAll);
            this._shadow.getElementById('btn-reject')?.addEventListener('click', this.handleRejectAll);
            this._shadow.getElementById('btn-customize')?.addEventListener('click', this.toggleDetails);
        } else {
            this._shadow.getElementById('btn-save-pref')?.addEventListener('click', this.handleSavePreferences);
        }
    }
}

if (!customElements.get('sovereign-cookie-banner')) {
    customElements.define('sovereign-cookie-banner', SovereignCookieBanner);
}
