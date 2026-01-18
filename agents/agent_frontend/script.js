// script.js - Quantum Leap Edition 🧠✨

let agentsData = [];
let graphData = { nodes: [], links: [] };
let networkSim = null; // Animation Frame ID

document.addEventListener('DOMContentLoaded', () => {
    fetchData();
    setupEventListeners();
    setupViewControls();
});

async function fetchData() {
    try {
        const response = await fetch('data/roster.json');
        if (!response.ok) throw new Error('Network response was not ok');
        const data = await response.json();

        agentsData = data.agents;
        graphData = data.graph || { nodes: [], links: [] };

        updateStats(data.stats);
        renderGrid(agentsData);
        // Pre-warm graph if desired, or wait for view switch
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
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            filterAgents(document.getElementById('searchInput').value, e.target.dataset.filter);
        });
    });
}

function setupViewControls() {
    document.querySelectorAll('.view-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const view = e.target.dataset.view;

            // Toggle Buttons
            document.querySelectorAll('.view-btn').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');

            // Toggle Views
            if (view === 'grid') {
                document.getElementById('agentGrid').classList.remove('hidden');
                document.getElementById('networkView').classList.add('hidden');
                document.getElementById('settingsView').classList.add('hidden');
                document.querySelector('.dashboard-controls .filters').style.display = 'flex';
                stopNetwork();
            } else if (view === 'network') {
                document.getElementById('agentGrid').classList.add('hidden');
                document.getElementById('networkView').classList.remove('hidden');
                document.getElementById('settingsView').classList.add('hidden');
                document.querySelector('.dashboard-controls .filters').style.display = 'none';
                startNetwork();
            } else if (view === 'settings') {
                document.getElementById('agentGrid').classList.add('hidden');
                document.getElementById('networkView').classList.add('hidden');
                document.getElementById('settingsView').classList.remove('hidden');
                document.querySelector('.dashboard-controls .filters').style.display = 'none';
                stopNetwork();
                setupSettingsLogic(); // Init Settings interactions
            }
        });
    });
}

function setupSettingsLogic() {
    const cards = document.querySelectorAll('.profile-card');
    const output = document.getElementById('envConfigOutput');
    const copyBtn = document.getElementById('copyConfigBtn');

    // Config Templates
    const configs = {
        budget: `# Budget King (Recommended) 👑
EASYWAY_MODE=Framework
BRAIN_MODEL=deepseek-chat
ARM_MODEL=gemini-1.5-flash
# Keys
DEEPSEEK_API_KEY=sk-...
GEMINI_API_KEY=sk-...`,

        deepseek_all: `# DeepSeek Pure 🦄
EASYWAY_MODE=Framework
BRAIN_MODEL=deepseek-chat
ARM_MODEL=deepseek-chat
# Keys
DEEPSEEK_API_KEY=sk-...`,

        azure: `# Enterprise (Azure) 💼
EASYWAY_MODE=Enterprise
BRAIN_MODEL=gpt-4o
ARM_MODEL=gpt-4o-mini
# Keys
OPENAI_API_KEY=sk-...`
    };

    cards.forEach(card => {
        card.addEventListener('click', () => {
            cards.forEach(c => c.classList.remove('active'));
            card.classList.add('active');
            const profile = card.dataset.profile;
            output.value = configs[profile];
        });
    });

    copyBtn.addEventListener('click', () => {
        output.select();
        document.execCommand('copy'); // Legacy but reliable
        const fb = document.getElementById('copyFeedback');
        fb.classList.remove('hidden');
        setTimeout(() => fb.classList.add('hidden'), 2000);
    });
}
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
                <div class="tools">${renderToolIcons(agent)}</div>
            </div>
        `;
        grid.appendChild(card);
    });
}

function renderToolIcons(agent) {
    let html = '';
    const allTools = [...(agent.tools || []), ...(agent.os_tools || [])];
    const max = 4;
    allTools.slice(0, max).forEach(tool => {
        let icon = '🔧';
        if (tool.includes('web')) icon = '🌐';
        if (tool.includes('code') || tool.includes('python')) icon = '🐍';
        if (tool.includes('az')) icon = '☁️';
        if (tool.includes('git')) icon = '🐙';
        if (tool.includes('pwsh')) icon = '💻';
        if (tool.includes('reasoning')) icon = '🤯';
        html += `<span class="tool-icon" title="${tool}">${icon}</span>`;
    });
    if (allTools.length > max) html += `<span class="tool-icon" title="More...">+${allTools.length - max}</span>`;
    return html;
}

function truncate(str, n) {
    return (str.length > n) ? str.substr(0, n - 1) + '&hellip;' : str;
}

// --- NETWORK VISUALIZATION (Quantum Physics Engine) ---
const canvas = document.getElementById('networkCanvas');
const ctx = canvas.getContext('2d');
let width, height;
let nodes = [], links = [];
let draggedNode = null;

function resizeCanvas() {
    const container = document.getElementById('networkView');
    if (container.classList.contains('hidden')) return;

    width = canvas.width = container.offsetWidth;
    height = canvas.height = container.offsetHeight;
}
window.addEventListener('resize', resizeCanvas);

function startNetwork() {
    resizeCanvas();
    if (nodes.length === 0) initSimulation();
    animate();

    // Interactions
    canvas.addEventListener('mousedown', onMouseDown);
    canvas.addEventListener('mousemove', onMouseMove);
    canvas.addEventListener('mouseup', onMouseUp);
}

function stopNetwork() {
    cancelAnimationFrame(networkSim);
    // Remove listeners
    canvas.removeEventListener('mousedown', onMouseDown);
    canvas.removeEventListener('mousemove', onMouseMove);
    canvas.removeEventListener('mouseup', onMouseUp);
}

function initSimulation() {
    // Clone data to avoid mutations impacting original source
    nodes = graphData.nodes.map(n => ({ ...n, x: width / 2 + (Math.random() - 0.5) * 50, y: height / 2 + (Math.random() - 0.5) * 50, vx: 0, vy: 0 }));
    // Links need direct references or index lookups
    links = graphData.links.map(l => {
        const source = nodes.find(n => n.id === l.source);
        const target = nodes.find(n => n.id === l.target);
        return { source, target, type: l.type };
    }).filter(l => l.source && l.target);
}

function animate() {
    ctx.clearRect(0, 0, width, height);

    // Physics Step
    applyForces();

    // Draw Links
    ctx.lineWidth = 1;
    links.forEach(link => {
        ctx.beginPath();
        ctx.moveTo(link.source.x, link.source.y);
        ctx.lineTo(link.target.x, link.target.y);
        if (link.type === 'strategic') {
            ctx.strokeStyle = '#a855f7'; // Purple for OODA
            ctx.setLineDash([5, 5]);
        } else {
            ctx.strokeStyle = '#334155';
            ctx.setLineDash([]);
        }
        ctx.stroke();
    });

    // Draw Nodes
    nodes.forEach(node => {
        ctx.beginPath();
        const r = node.val || 10;
        ctx.arc(node.x, node.y, r, 0, 2 * Math.PI);

        if (node.group === 'brain') ctx.fillStyle = '#a855f7';
        else if (node.group === 'arm') ctx.fillStyle = '#22c55e';
        else ctx.fillStyle = '#64748b'; // System

        ctx.fill();
        ctx.strokeStyle = '#fff';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Labels
        ctx.fillStyle = '#cbd5e1';
        ctx.font = '10px Sans-Serif';
        ctx.fillText(node.label, node.x + r + 5, node.y + 3);
    });

    networkSim = requestAnimationFrame(animate);
}

function applyForces() {
    // Parameters
    const repulsion = 500;
    const springLength = 100;
    const springK = 0.05;
    const damping = 0.9;
    const centerK = 0.01;

    // Repulsion (Coulomb)
    for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
            const dx = nodes[j].x - nodes[i].x;
            const dy = nodes[j].y - nodes[i].y;
            const distSq = dx * dx + dy * dy + 0.1;
            const dist = Math.sqrt(distSq);
            const f = repulsion / distSq;

            const fx = (dx / dist) * f;
            const fy = (dy / dist) * f;

            nodes[i].vx -= fx;
            nodes[i].vy -= fy;
            nodes[j].vx += fx;
            nodes[j].vy += fy;
        }
    }

    // Attraction (Springs)
    links.forEach(link => {
        const dx = link.target.x - link.source.x;
        const dy = link.target.y - link.source.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        const force = (dist - springLength) * springK;

        const fx = (dx / dist) * force;
        const fy = (dy / dist) * force;

        link.source.vx += fx;
        link.source.vy += fy;
        link.target.vx -= fx;
        link.target.vy -= fy;
    });

    // Center Gravity
    nodes.forEach(node => {
        node.vx += (width / 2 - node.x) * centerK;
        node.vy += (height / 2 - node.y) * centerK;
    });

    // Update Position
    nodes.forEach(node => {
        if (node === draggedNode) return; // Don't move dragged node
        node.vx *= damping;
        node.vy *= damping;
        node.x += node.vx;
        node.y += node.vy;

        // Boundaries
        node.x = Math.max(20, Math.min(width - 20, node.x));
        node.y = Math.max(20, Math.min(height - 20, node.y));
    });
}

// Interaction Handlers
function onMouseDown(e) {
    const { x, y } = getPos(e);
    draggedNode = nodes.find(n => Math.hypot(n.x - x, n.y - y) < (n.val || 15));
}
function onMouseMove(e) {
    if (draggedNode) {
        const { x, y } = getPos(e);
        draggedNode.x = x;
        draggedNode.y = y;
    } else {
        // Tooltip logic could go here
        const { x, y } = getPos(e);
        const hoverNode = nodes.find(n => Math.hypot(n.x - x, n.y - y) < (n.val || 15));
        const tooltip = document.getElementById('nodeTooltip');
        if (hoverNode) {
            tooltip.textContent = `${hoverNode.label} (${hoverNode.group})`;
            tooltip.style.left = (e.clientX + 10) + 'px';
            tooltip.style.top = (e.clientY + 10) + 'px';
            tooltip.classList.remove('hidden');
        } else {
            tooltip.classList.add('hidden');
        }
    }
}
function onMouseUp() {
    draggedNode = null;
}
function getPos(e) {
    const rect = canvas.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
}
