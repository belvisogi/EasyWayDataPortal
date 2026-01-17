// script.js

let agentsData = [];

document.addEventListener('DOMContentLoaded', () => {
    fetchData();
    setupEventListeners();
});

async function fetchData() {
    try {
        const response = await fetch('data/roster.json');
        if (!response.ok) throw new Error('Network response was not ok');
        const data = await response.json();

        agentsData = data.agents;
        updateStats(data.stats);
        renderGrid(agentsData);
    } catch (error) {
        console.error('Error fetching roster:', error);
        document.getElementById('agentGrid').innerHTML = '<p>Error loading agents. Run generators first.</p>';
    }
}

function updateStats(stats) {
    document.getElementById('totalAgents').textContent = stats.total;
    document.getElementById('totalBrains').textContent = stats.brains;
    document.getElementById('totalArms').textContent = stats.arms;
}

function setupEventListeners() {
    // Search
    document.getElementById('searchInput').addEventListener('input', (e) => {
        filterAgents(e.target.value, getActiveFilter());
    });

    // Filters
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            // Toggle active class
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');

            filterAgents(document.getElementById('searchInput').value, e.target.dataset.filter);
        });
    });
}

function getActiveFilter() {
    return document.querySelector('.filter-btn.active').dataset.filter;
}

function filterAgents(searchText, filterType) {
    const term = searchText.toLowerCase();

    const filtered = agentsData.filter(agent => {
        const matchesSearch = agent.name.toLowerCase().includes(term) ||
            agent.description.toLowerCase().includes(term) ||
            agent.role.toLowerCase().includes(term);

        const matchesType = filterType === 'all' || agent.classification === filterType;

        return matchesSearch && matchesType;
    });

    renderGrid(filtered);
}

function renderGrid(agents) {
    const grid = document.getElementById('agentGrid');
    grid.innerHTML = '';

    agents.forEach(agent => {
        const card = document.createElement('div');
        card.className = 'card';
        card.innerHTML = `
            <div class="card-header">
                <div class="card-icon">${agent.icon}</div>
                <div class="card-class ${agent.classification}">${agent.classification}</div>
            </div>
            <h3 class="card-title">${agent.name}</h3>
            <div class="card-role">${agent.role}</div>
            <p class="card-desc">${truncate(agent.description, 80)}</p>
            <div class="card-footer">
                <span class="model-badge">🧠 ${agent.model || 'Default'}</span>
                <div class="tools">
                    ${renderToolIcons(agent)}
                </div>
            </div>
        `;
        grid.appendChild(card);
    });
}

function renderToolIcons(agent) {
    let html = '';
    const allTools = [...(agent.tools || []), ...(agent.os_tools || [])];

    allTools.forEach(tool => {
        let icon = '🔧';
        if (tool.includes('web')) icon = '🌐';
        if (tool.includes('code') || tool.includes('python')) icon = '🐍';
        if (tool.includes('az')) icon = '☁️';
        if (tool.includes('git')) icon = '🐙';
        if (tool.includes('pwsh')) icon = '💻';
        if (tool.includes('reasoning')) icon = '🤯';

        html += `<span class="tool-icon" title="${tool}">${icon}</span>`;
    });
    return html;
}

function truncate(str, n) {
    return (str.length > n) ? str.substr(0, n - 1) + '&hellip;' : str;
}
