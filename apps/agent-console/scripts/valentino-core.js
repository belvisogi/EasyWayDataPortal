/**
 * Valentino Framework - Core JavaScript
 * Sovereign, lightweight, no external dependencies (except D3 for graphs)
 */

const Valentino = {
    // Navigation System
    navigation: {
        init() {
            const navButtons = document.querySelectorAll('.nav-btn');
            const views = document.querySelectorAll('.view');

            navButtons.forEach(btn => {
                btn.addEventListener('click', () => {
                    const targetView = btn.dataset.view;

                    // Update active states
                    navButtons.forEach(b => b.classList.remove('active'));
                    btn.classList.add('active');

                    // Show target view
                    views.forEach(v => v.classList.remove('active'));
                    document.getElementById(`view-${targetView}`).classList.add('active');
                });
            });
        }
    },

    // Data Loading
    data: {
        async loadJSON(path) {
            try {
                const response = await fetch(path);
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                return await response.json();
            } catch (error) {
                console.error(`Error loading ${path}:`, error);
                return null;
            }
        },

        async loadAgents() {
            return await this.loadJSON('../../agents/kb/agents-summary.json') ||
                await this.generateAgentsSummary();
        },

        async loadSkills() {
            return await this.loadJSON('../../agents/skills/registry.json');
        },

        async loadKnowledgeGraph() {
            return await this.loadJSON('../../agents/kb/knowledge-graph.json');
        },

        // Fallback: generate agents summary from manifests
        async generateAgentsSummary() {
            // This would scan manifests in production
            // For now, return hardcoded active agents
            return {
                agents: [
                    { id: 'agent_gedi', name: 'GEDI', classification: 'brain', level: 2, description: 'Philosophy Guardian - OODA Loop' },
                    { id: 'agent_governance', name: 'Governance', classification: 'brain', level: 2, description: 'Policy Master' },
                    { id: 'agent_retrieval', name: 'Retrieval', classification: 'brain', level: 2, description: 'RAG Manager' },
                    { id: 'agent_chronicler', name: 'Chronicler', classification: 'brain', level: 2, description: 'Milestone Celebrator' },
                    { id: 'agent_cartographer', name: 'Cartographer', classification: 'brain', level: 2, description: 'The Navigator - Knowledge Graph' },
                    { id: 'agent_dba', name: 'DBA', classification: 'arm', level: 1, description: 'Database Administrator' },
                    { id: 'agent_docs_sync', name: 'Docs Sync', classification: 'arm', level: 2, description: 'Documentation Alignment' },
                    { id: 'agent_frontend', name: 'Frontend', classification: 'arm', level: 1, description: 'UI/UX Developer' },
                    { id: 'agent_security', name: 'Security', classification: 'arm', level: 1, description: 'Security Guardian' },
                    { id: 'agent_vulnerability_scanner', name: 'Vulnerability Scanner', classification: 'arm', level: 1, description: 'Security Scanning' }
                ]
            };
        }
    },

    // Utilities
    utils: {
        formatDate(date) {
            return new Date(date).toLocaleDateString('it-IT', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            });
        },

        debounce(func, wait) {
            let timeout;
            return function executedFunction(...args) {
                const later = () => {
                    clearTimeout(timeout);
                    func(...args);
                };
                clearTimeout(timeout);
                timeout = setTimeout(later, wait);
            };
        },

        escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    },

    // Initialize all modules
    init() {
        console.log('🌹 Valentino Framework initialized');
        this.navigation.init();
    }
};

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => Valentino.init());
} else {
    Valentino.init();
}

// Export for use in other modules
window.Valentino = Valentino;
