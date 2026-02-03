
/**
 * Sovereign Toaster Component (The Herald)
 * A zero-dependency, stacked notification system.
 * 
 * Usage:
 * document.body.dispatchEvent(new CustomEvent('sovereign-toast-show', { 
 *   detail: { message: 'Hello', type: 'success', duration: 3000 } 
 * }));
 */

export interface ToastOptions {
    message: string;
    type?: 'info' | 'success' | 'warning' | 'error';
    duration?: number;
    action?: { label: string; onClick: () => void };
}

export class SovereignToaster extends HTMLElement {
    private _shadow: ShadowRoot;
    private _toasts: Set<HTMLElement> = new Set();
    private _container: HTMLElement;

    constructor() {
        super();
        this._shadow = this.attachShadow({ mode: 'open' });
        this._container = document.createElement('div');
        this._container.classList.add('toast-container');
    }

    connectedCallback() {
        this.render();
        window.addEventListener('sovereign-toast-show', this.handleShowToast as EventListener);
    }

    disconnectedCallback() {
        window.removeEventListener('sovereign-toast-show', this.handleShowToast as EventListener);
    }

    private handleShowToast = (e: CustomEvent<ToastOptions>) => {
        const { message, type = 'info', duration = 4000, action } = e.detail;
        this.createToast(message, type, duration, action);
    }

    private createToast(message: string, type: string, duration: number, action?: { label: string; onClick: () => void }) {
        const toast = document.createElement('div');
        toast.classList.add('toast', type);

        // Icon map
        const icons: Record<string, string> = {
            success: '✓',
            error: '✕',
            warning: '⚠',
            info: 'ℹ'
        };

        const content = `
            <div class="icon">${icons[type] || icons.info}</div>
            <div class="message">${message}</div>
            ${action ? `<button class="action-btn">${action.label}</button>` : ''}
        `;
        toast.innerHTML = content;

        // Action binding
        if (action) {
            toast.querySelector('.action-btn')?.addEventListener('click', (e) => {
                e.stopPropagation();
                action.onClick();
                this.dismissToast(toast);
            });
        }

        // Dismiss on click
        toast.addEventListener('click', () => this.dismissToast(toast));

        // Mount
        this._container.prepend(toast); // Add to top usually, but for stacking we might want append and visual sort
        this._toasts.add(toast);

        // Animate In via CSS
        // requestAnimationFrame(() => toast.classList.add('visible')); 
        // Note: CSS Animation on mount works automatically if defined in keyframes

        // Auto Dismiss
        if (duration > 0) {
            setTimeout(() => {
                if (this._toasts.has(toast)) this.dismissToast(toast);
            }, duration);
        }

        // Limit stack size (max 5)
        if (this._toasts.size > 5) {

            // Wait, prepend means the newest is first in DOM, but Set order depends on add.
            // If we prepend to DOM, visual order is New -> Old. 
            // If we want to remove oldest, check the last one in DOM or first in Set.
            // Let's just remove the last element in DOM to be safe.
            const last = this._container.lastElementChild as HTMLElement;
            if (last) this.dismissToast(last);
        }
    }

    private dismissToast(toast: HTMLElement) {
        toast.classList.add('hiding');
        toast.addEventListener('animationend', () => {
            toast.remove();
            this._toasts.delete(toast);
        });
    }

    render() {
        const styles = `
            :host {
                position: fixed;
                bottom: 2rem;
                right: 2rem;
                z-index: 9999;
                pointer-events: none; /* Let clicks pass through container */
                font-family: var(--font-family, system-ui, sans-serif);
                --glass-bg: rgba(6, 11, 19, 0.85);
                --glass-border: rgba(255, 255, 255, 0.1);
                --accent-success: #10B981;
                --accent-error: #EF4444;
                --accent-warning: #F59E0B;
                --accent-info: #3B82F6;
            }

            .toast-container {
                display: flex;
                flex-direction: column-reverse; /* Stack upwards from bottom */
                gap: 10px;
                align-items: flex-end;
            }

            .toast {
                pointer-events: auto; /* Re-enable clicks on toasts */
                background: var(--glass-bg);
                border: 1px solid var(--glass-border);
                backdrop-filter: blur(12px);
                color: white;
                padding: 1rem 1.2rem;
                border-radius: 10px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.5);
                display: flex;
                align-items: center;
                gap: 1rem;
                min-width: 300px;
                max-width: 400px;
                cursor: pointer;
                transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
                
                /* Animation Enter */
                animation: slideIn 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
                opacity: 0;
                transform: translateY(20px) scale(0.95);
            }

            @keyframes slideIn {
                to {
                    opacity: 1;
                    transform: translateY(0) scale(1);
                }
            }

            .toast.hiding {
                animation: slideOut 0.3s forwards;
            }

            @keyframes slideOut {
                to {
                    opacity: 0;
                    transform: translateX(100px);
                }
            }

            .icon {
                font-size: 1.2rem;
            }

            .message {
                flex: 1;
                font-size: 0.95rem;
                line-height: 1.4;
            }

            /* Type Colors */
            .toast.success { border-left: 4px solid var(--accent-success); }
            .toast.success .icon { color: var(--accent-success); }

            .toast.error { border-left: 4px solid var(--accent-error); }
            .toast.error .icon { color: var(--accent-error); }

            .toast.warning { border-left: 4px solid var(--accent-warning); }
            .toast.warning .icon { color: var(--accent-warning); }

            .toast.info { border-left: 4px solid var(--accent-info); }
            .toast.info .icon { color: var(--accent-info); }

            .action-btn {
                background: rgba(255,255,255,0.1);
                border: none;
                color: white;
                padding: 0.4rem 0.8rem;
                border-radius: 4px;
                cursor: pointer;
                font-size: 0.8rem;
                transition: background 0.2s;
            }

            .action-btn:hover {
                background: rgba(255,255,255,0.2);
            }
        `;

        this._shadow.innerHTML = `<style>${styles}</style>`;
        this._shadow.appendChild(this._container);
    }
}

if (!customElements.get('sovereign-toaster')) {
    customElements.define('sovereign-toaster', SovereignToaster);
}
