/**
 * Agent Console Application Logic
 * Populates views with data from Knowledge Graph and Skills Registry
 */

const ConsoleApp = {
    state: {
        agents: [],
        skills: [],
        graph: null,
        skillsFilter: 'all'
    },

    async init() {
        console.log('🤖 Agent Console initializing...');

        // Load data
        await this.loadData();

        // Render views
        this.renderAgents();
        this.renderSkills();
        this.updateStats();

        // Setup search
        this.setupSearch();
        this.setupSkillsFilter();

        console.log('✅ Agent Console ready');
    },

    async loadData() {
        try {
            const [agentsData, runtimeSkillsData, macroSkillsData, graphData] = await Promise.all([
                Valentino.data.loadAgents(),
                Valentino.data.loadSkills(),
                Valentino.data.loadJSON('../../docs/skills/catalog.generated.json'),
                Valentino.data.loadKnowledgeGraph()
            ]);

            this.state.agents = agentsData?.agents || [];
            const runtimeSkills = (runtimeSkillsData?.skills || []).map(skill => ({
                ...skill,
                type: 'runtime',
                domain: skill.domain || 'runtime',
                description: skill.description || 'Runtime skill'
            }));
            const macroSkills = (macroSkillsData?.skills || []).map(skill => ({
                ...skill,
                type: 'macro-use-case',
                domain: skill.domain || 'macro-use-case',
                description: skill.description || skill.summary || 'Macro use-case skill'
            }));
            this.state.skills = [...runtimeSkills, ...macroSkills];
            this.state.graph = graphData;

            console.log(`Loaded: ${this.state.agents.length} agents, ${runtimeSkills.length} runtime skills, ${macroSkills.length} macro skills`);
        } catch (error) {
            console.error('Error loading data:', error);
        }
    },

    updateStats() {
        // Update dashboard stats
        const totalAgents = this.state.agents.length;
        const totalSkills = this.state.skills.length;
        const graphNodes = this.state.graph?.metadata?.total_nodes || 0;

        document.getElementById('stat-total-agents').textContent = totalAgents;
        document.getElementById('stat-total-skills').textContent = totalSkills;
        document.getElementById('stat-graph-nodes').textContent = graphNodes;
    },

    renderAgents() {
        const container = document.getElementById('agents-container');
        if (!container) return;

        container.innerHTML = '';

        this.state.agents.forEach(agent => {
            const card = document.createElement('div');
            card.className = `agent-card ${agent.classification}`;
            card.innerHTML = `
                <div class="agent-header">
                    <div class="agent-name">${Valentino.utils.escapeHtml(agent.name)}</div>
                    <span class="agent-badge">${agent.classification === 'brain' ? '🧠 Brain' : '💪 Arm'}</span>
                </div>
                <div class="agent-description">${Valentino.utils.escapeHtml(agent.description)}</div>
                <div class="agent-meta">
                    <span>📊 Level ${agent.level}</span>
                    <span>🆔 ${agent.id}</span>
                </div>
            `;
            container.appendChild(card);
        });
    },

    renderSkills() {
        const container = document.getElementById('skills-container');
        if (!container) return;

        container.innerHTML = '';

        const visibleSkills = this.state.skills.filter(skill => (
            this.state.skillsFilter === 'all' || skill.type === this.state.skillsFilter
        ));

        if (visibleSkills.length === 0) {
            container.innerHTML = '<p class="text-muted">Nessuna skill trovata per il filtro selezionato.</p>';
            return;
        }

        visibleSkills.forEach(skill => {
            const card = document.createElement('div');
            card.className = `skill-card ${skill.type === 'macro-use-case' ? 'macro' : 'runtime'}`;
            const skillTypeLabel = skill.type === 'macro-use-case' ? 'Macro Use Case' : 'Runtime';
            card.innerHTML = `
                <div class="skill-name">${Valentino.utils.escapeHtml(skill.name || skill.id)}</div>
                <div class="skill-type-row">
                    <span class="skill-type-badge">${Valentino.utils.escapeHtml(skillTypeLabel)}</span>
                </div>
                <div class="skill-domain">📁 ${Valentino.utils.escapeHtml(skill.domain || 'general')}</div>
                <div class="skill-description">${Valentino.utils.escapeHtml(skill.description || 'No description')}</div>
            `;
            container.appendChild(card);
        });
    },

    setupSkillsFilter() {
        const filterSelect = document.getElementById('skills-type-filter');
        if (!filterSelect) return;
        filterSelect.addEventListener('change', () => {
            this.state.skillsFilter = filterSelect.value;
            this.renderSkills();
        });
    },

    setupSearch() {
        const searchInput = document.getElementById('search-input');
        const searchBtn = document.getElementById('search-btn');
        const searchResults = document.getElementById('search-results');

        if (!searchInput || !searchBtn || !searchResults) return;

        const performSearch = () => {
            const query = searchInput.value.toLowerCase().trim();

            if (!query) {
                searchResults.innerHTML = '<p class="text-muted">Inserisci una query per cercare...</p>';
                return;
            }

            // Search in agents
            const agentResults = this.state.agents.filter(a =>
                a.name.toLowerCase().includes(query) ||
                a.description.toLowerCase().includes(query) ||
                a.id.toLowerCase().includes(query)
            );

            // Search in skills
            const skillResults = this.state.skills.filter(s =>
                (s.name || s.id).toLowerCase().includes(query) ||
                (s.description || '').toLowerCase().includes(query) ||
                (s.type || '').toLowerCase().includes(query) ||
                (s.domain || '').toLowerCase().includes(query)
            );

            // Render results
            let html = '';

            if (agentResults.length > 0) {
                html += '<h3>🤖 Agenti</h3><ul class="activity-list">';
                agentResults.forEach(a => {
                    html += `
                        <li class="activity-item">
                            <span class="activity-icon">${a.classification === 'brain' ? '🧠' : '💪'}</span>
                            <span class="activity-text"><strong>${Valentino.utils.escapeHtml(a.name)}</strong> - ${Valentino.utils.escapeHtml(a.description)}</span>
                        </li>
                    `;
                });
                html += '</ul>';
            }

            if (skillResults.length > 0) {
                html += '<h3 class="mt-md">🛠️ Skills</h3><ul class="activity-list">';
                skillResults.forEach(s => {
                    const badge = s.type === 'macro-use-case' ? '[macro]' : '[runtime]';
                    html += `
                        <li class="activity-item">
                            <span class="activity-icon">🛠️</span>
                            <span class="activity-text"><strong>${Valentino.utils.escapeHtml(s.name || s.id)}</strong> ${badge} - ${Valentino.utils.escapeHtml(s.description || '')}</span>
                        </li>
                    `;
                });
                html += '</ul>';
            }

            if (agentResults.length === 0 && skillResults.length === 0) {
                html = '<p class="text-muted">Nessun risultato trovato per "' + Valentino.utils.escapeHtml(query) + '"</p>';
            }

            searchResults.innerHTML = html;
        };

        searchBtn.addEventListener('click', performSearch);
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') performSearch();
        });
    }
};

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => ConsoleApp.init());
} else {
    ConsoleApp.init();
}

window.ConsoleApp = ConsoleApp;
