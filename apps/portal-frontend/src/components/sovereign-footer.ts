/**
 * Sovereign Footer Component
 * Standardized footer for the EasyWay platform.
 * 
 * Usage: <sovereign-footer></sovereign-footer>
 */

export class SovereignFooter extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        this.innerHTML = `
    <footer class="site-footer">
        <div class="footer-container">
            <!-- Brand Column -->
            <div class="footer-col brand-col">
                <div class="footer-logo">
                    <svg width="24" height="24" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <rect x="4" y="4" width="32" height="32" rx="6" stroke="var(--text-sovereign-gold)" stroke-width="3" fill="none"/>
                        <circle cx="20" cy="20" r="4" fill="var(--text-sovereign-gold)"/>
                    </svg>
                    EasyWay
                </div>
                <p class="footer-tagline">
                    Sovereign Intelligence.<br>
                    Owned by You.
                </p>
                <div class="social-links">
                    <a href="#" aria-label="GitHub">GH</a>
                    <a href="#" aria-label="Docs">DOC</a>
                    <a href="#" aria-label="LinkedIn">LI</a>
                </div>
            </div>

            <!-- Links Column: Platform -->
            <div class="footer-col">
                <h4>Platform</h4>
                <ul>
                    <li><a href="#">Sovereign Cloud</a></li>
                    <li><a href="/n8n/">N8N Pipelines</a></li>
                    <li><a href="/memory">Vector Memory</a></li>
                    <li><a href="#">Security Protocol</a></li>
                </ul>
            </div>

            <!-- Links Column: Agents -->
            <div class="footer-col">
                <h4>Agents</h4>
                <ul>
                    <li><a href="#">GEDI Guardian</a></li>
                    <li><a href="#">SQL Analyst</a></li>
                    <li><a href="#">Cortex Chat</a></li>
                    <li><a href="#">Architect</a></li>
                </ul>
            </div>

            <!-- Links Column: Company -->
            <div class="footer-col">
                <h4>Company</h4>
                <ul>
                    <li><a href="/manifesto">Manifesto</a></li>
                    <li><a href="#">Roadmap</a></li>
                    <li><a href="/demo">Request Demo</a></li>
                    <li><a href="#">Contact</a></li>
                </ul>
            </div>
        </div>
        
        <div class="footer-bottom">
            <p>&copy; 2026 EasyWay Inc. All Sovereign Rights Reserved.</p>
            <div class="legal-links">
                <a href="#">Privacy</a>
                <a href="#">Terms</a>
                <a href="#">Compliance</a>
            </div>
        </div>
    </footer>

    <style>
        .site-footer {
            background: rgba(6, 11, 19, 0.95);
            border-top: 1px solid rgba(234, 179, 8, 0.2);
            padding: 4rem 0 2rem;
            margin-top: auto;
            color: var(--text-secondary);
            font-family: var(--font-family);
            position: relative;
            z-index: 10;
        }

        .footer-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 2rem;
            display: grid;
            grid-template-columns: 2fr 1fr 1fr 1fr;
            gap: 4rem;
        }

        .footer-col h4 {
            color: var(--text-sovereign-gold);
            font-family: var(--font-family);
            margin-bottom: 1.5rem;
            font-size: 1rem;
            letter-spacing: 0.05em;
            text-transform: uppercase;
        }

        .footer-col ul {
            list-style: none;
            padding: 0;
            margin: 0;
        }

        .footer-col li {
            margin-bottom: 0.8rem;
        }

        .footer-col a {
            color: var(--text-secondary);
            text-decoration: none;
            font-size: 0.9rem;
            transition: color 0.2s;
        }

        .footer-col a:hover {
            color: var(--accent-neural-cyan);
        }

        .brand-col .footer-logo {
            color: var(--text-sovereign-gold);
            font-family: var(--font-family);
            font-weight: 800;
            font-size: 1.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 1rem;
        }

        .footer-tagline {
            font-size: 0.9rem;
            line-height: 1.6;
            margin-bottom: 2rem;
            opacity: 0.8;
        }

        .social-links {
            display: flex;
            gap: 1rem;
        }

        .social-links a {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
            font-size: 0.8rem;
            border: 1px solid rgba(255,255,255,0.1);
            padding: 0.4rem 0.8rem;
            border-radius: 4px;
            color: var(--text-primary);
        }

        .social-links a:hover {
            border-color: var(--accent-neural-cyan);
            color: var(--accent-neural-cyan);
        }

        .footer-bottom {
            max-width: 1200px;
            margin: 3rem auto 0;
            padding: 2rem 2rem 0;
            border-top: 1px solid rgba(255,255,255,0.05);
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.8rem;
        }

        .legal-links {
            display: flex;
            gap: 2rem;
        }

        .legal-links a {
            color: var(--text-secondary);
            text-decoration: none;
            transition: color 0.2s;
        }

        .legal-links a:hover {
            color: var(--accent-neural-cyan);
        }

        /* Responsive */
        @media (max-width: 900px) {
            .footer-container {
                grid-template-columns: 1fr 1fr;
                gap: 2rem;
            }
        }

        @media (max-width: 600px) {
            .footer-container {
                grid-template-columns: 1fr;
            }
            .footer-bottom {
                flex-direction: column;
                gap: 1rem;
                text-align: center;
            }
        }
    </style>
        `;
    }
}

// Self-Register
customElements.define('sovereign-footer', SovereignFooter);
