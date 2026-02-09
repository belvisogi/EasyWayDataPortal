// Agent Console Section Renderers
// Custom sections for Agent Console integration

import { getContentValue } from './content';

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

function setMaybeHtml(node: HTMLElement, value: string) {
    if (value.includes('<')) node.innerHTML = value;
    else node.textContent = value;
}

/**
 * Agent Dashboard - Stats cards showing agent ecosystem metrics
 */
export function renderAgentDashboard(section: any): HTMLElement {
    const container = el('section', 'container');
    container.style.paddingTop = '2rem';
    container.style.paddingBottom = '4rem';

    if (section.titleKey) {
        const h2 = el('h2', 'h2');
        setMaybeHtml(h2, getContentValue(section.titleKey));
        container.appendChild(h2);
    }

    const statsGrid = el('div', 'stats-grid');
    statsGrid.style.display = 'grid';
    statsGrid.style.gridTemplateColumns = 'repeat(auto-fit, minmax(250px, 1fr))';
    statsGrid.style.gap = '1.5rem';
    statsGrid.style.marginTop = '2rem';

    // Stats will be populated by JavaScript
    statsGrid.id = 'agent-stats-grid';
    container.appendChild(statsGrid);

    // Initialize stats loading
    setTimeout(() => loadAgentStats(), 100);

    return container;
}

/**
 * Agent Graph - D3.js Knowledge Graph visualization
 */
export function renderAgentGraph(section: any): HTMLElement {
    const container = el('section', 'container');
    container.style.paddingTop = '2rem';
    container.style.paddingBottom = '4rem';

    if (section.titleKey) {
        const h2 = el('h2', 'h2');
        setMaybeHtml(h2, getContentValue(section.titleKey));
        container.appendChild(h2);
    }

    if (section.descKey) {
        const desc = el('p');
        desc.style.color = 'var(--text-secondary)';
        desc.style.marginBottom = '2rem';
        setMaybeHtml(desc, getContentValue(section.descKey));
        container.appendChild(desc);
    }

    // Graph controls
    const controls = el('div', 'graph-controls');
    controls.style.display = 'flex';
    controls.style.gap = '0.5rem';
    controls.style.marginBottom = '1rem';

    const zoomIn = el('button', 'btn btn-glass btn-sm', '🔍 Zoom In');
    zoomIn.id = 'btn-zoom-in';
    const zoomOut = el('button', 'btn btn-glass btn-sm', '🔍 Zoom Out');
    zoomOut.id = 'btn-zoom-out';
    const reset = el('button', 'btn btn-glass btn-sm', '🔄 Reset');
    reset.id = 'btn-reset-graph';

    controls.appendChild(zoomIn);
    controls.appendChild(zoomOut);
    controls.appendChild(reset);
    container.appendChild(controls);

    // Graph container
    const graphContainer = el('div');
    graphContainer.id = 'knowledge-graph';
    graphContainer.style.width = '100%';
    graphContainer.style.height = '600px';
    graphContainer.style.background = 'var(--bg-paper)';
    graphContainer.style.borderRadius = '12px';
    graphContainer.style.border = '1px solid var(--glass-border)';
    container.appendChild(graphContainer);

    // Load D3.js and initialize graph
    setTimeout(() => initKnowledgeGraph(), 100);

    return container;
}

/**
 * Agent List - Grid of agent cards
 */
export function renderAgentList(section: any): HTMLElement {
    const container = el('section', 'container');
    container.style.paddingTop = '2rem';
    container.style.paddingBottom = '4rem';

    if (section.titleKey) {
        const h2 = el('h2', 'h2');
        setMaybeHtml(h2, getContentValue(section.titleKey));
        container.appendChild(h2);
    }

    if (section.descKey) {
        const desc = el('p');
        desc.style.color = 'var(--text-secondary)';
        desc.style.marginBottom = '2rem';
        setMaybeHtml(desc, getContentValue(section.descKey));
        container.appendChild(desc);
    }

    const agentsGrid = el('div', 'agents-grid');
    agentsGrid.style.display = 'grid';
    agentsGrid.style.gridTemplateColumns = 'repeat(auto-fill, minmax(300px, 1fr))';
    agentsGrid.style.gap = '1.5rem';
    agentsGrid.id = 'agents-container';
    container.appendChild(agentsGrid);

    // Load agents
    setTimeout(() => loadAgentsList(), 100);

    return container;
}

// Data loading functions (will be called by the renderers)
async function loadAgentStats() {
    console.log('[AgentConsole] Loading stats...');
    const grid = document.getElementById('agent-stats-grid');
    if (!grid) return;

    try {
        const response = await fetch('/data/knowledge-graph.json');
        if (!response.ok) throw new Error(`Fetch failed: ${response.status} ${response.statusText}`);

        const graphData = await response.json();
        console.log('[AgentConsole] Stats data loaded:', graphData);

        const stats = [
            { value: '10', label: 'Agenti Attivi', detail: '38% coverage (10/26)' },
            { value: '13', label: 'Skills Disponibili', detail: '5 domini' },
            { value: graphData.metadata?.total_nodes || '105', label: 'Knowledge Graph Nodes', detail: `${graphData.metadata?.total_edges || 30} relazioni` },
            { value: '$0.16', label: 'Costo Mensile LLM', detail: 'DeepSeek (95% risparmio)' }
        ];

        grid.innerHTML = '';
        stats.forEach(stat => {
            const card = el('div', 'stat-card');
            card.style.background = 'var(--bg-paper)';
            card.style.padding = '2rem';
            card.style.borderRadius = '12px';
            card.style.border = '1px solid var(--glass-border)';
            card.style.textAlign = 'center';

            const value = el('div', 'stat-value');
            value.style.fontSize = '3rem';
            value.style.fontWeight = '700';
            value.style.color = 'var(--text-sovereign-gold)';
            value.textContent = String(stat.value);

            const label = el('div', 'stat-label');
            label.style.fontSize = '1.125rem';
            label.style.fontWeight = '600';
            label.style.marginTop = '0.5rem';
            label.textContent = stat.label;

            const detail = el('div', 'stat-detail');
            detail.style.fontSize = '0.875rem';
            detail.style.color = 'var(--text-secondary)';
            detail.style.marginTop = '0.25rem';
            detail.textContent = stat.detail;

            card.appendChild(value);
            card.appendChild(label);
            card.appendChild(detail);
            grid.appendChild(card);
        });
    } catch (err) {
        console.error('[AgentConsole] Failed to load agent stats:', err);
        grid.innerHTML = `<p style="color: var(--text-secondary);">Failed to load stats: ${(err as Error).message}</p>`;
    }
}

// Map of detailed descriptions for known agents
const detailedDescriptions: Record<string, string> = {
    'agent_gedi': 'Il Guardiano della Filosofia di EasyWay. GEDI utilizza il ciclo OODA (Observe, Orient, Decide, Act) per valutare ogni modifica rispetto ai Principi Guida (Sovereignty, Anti-Fragility, Hextech). È l\'autorità morale del sistema.',
    'agent_governance': 'Il Maestro delle Policy. Verifica che ogni PR e modifica rispetti gli standard di codice, sicurezza e documentazione. Gestisce le checklist di approvazione e blocca le violazioni critiche.',
    'agent_retrieval': 'Il Gestore della Conoscenza. Specializzato nel recupero di informazioni tramite RAG (Retrieval-Augmented Generation). Utilizza Qdrant per indicizzare e cercare nella Wiki e nel codice.',
    'agent_chronicler': 'Il Bardo del Progetto. Registra le decisioni architettoniche (ADR) e celebra i successi. Mantiene la storia viva di EasyWay e genera changelog narrativi.',
    'agent_cartographer': 'Il Navigatore. Mantiene aggiornato il Knowledge Graph, mappando le relazioni tra agenti, skills e infrastruttura. Permette l\'analisi dell\'Effetto Farfalla.',
    'agent_dba': 'Amministratore del Database SQL Server. Gestisce migrazioni, ottimizzazioni e sicurezza dei dati. Assicura l\'integrità referenziale e le performance.',
    'agent_docs_sync': 'Garante dell\'Allineamento. Verifica che il codice coincida con la documentazione. Aggiorna automaticamente la Wiki quando il codice cambia.',
    'agent_frontend': 'Sviluppatore UI/UX. Costruisce interfacce sovrane usando il Valentino Framework. Esperto di Web Components e CSS sartoriale.',
    'agent_security': 'Guardiano della Sicurezza. Scansiona CVE, gestisce i segreti ne Key Vault e verifica le policy di accesso.',
    'agent_vulnerability_scanner': 'Scanner di Vulnerabilità. Esegue controlli periodici su container e dipendenze per identificare rischi di sicurezza.'
};

async function loadAgentsList() {
    console.log('[AgentConsole] Loading agents list...');
    const container = document.getElementById('agents-container');
    if (!container) return;

    try {
        // Load graph data to find connections
        const response = await fetch('/data/knowledge-graph.json');
        if (!response.ok) throw new Error(`Fetch failed: ${response.status}`);

        const graphData = await response.json();
        const nodes = graphData.nodes || [];
        const edges = graphData.edges || [];

        // Filter agent nodes
        const agents = nodes.filter((n: any) => n.type === 'agent');
        console.log(`[AgentConsole] Found ${agents.length} agents`);

        container.innerHTML = '';
        agents.forEach((agent: any) => {
            const description = detailedDescriptions[agent.id] || agent.properties?.role || 'Agente Operativo';
            const isBrain = agent.properties?.classification === 'brain';

            // Find connected skills (source = agent, target = skill, type = uses)
            const skills = edges
                .filter((e: any) => e.source === agent.id && e.target.startsWith('skill_') && e.type === 'uses')
                .map((e: any) => {
                    const skillNode = nodes.find((n: any) => n.id === e.target);
                    return skillNode ? skillNode.label : e.target;
                });

            const card = el('div', 'agent-card');
            card.style.background = 'var(--bg-paper)';
            card.style.padding = '1.5rem';
            card.style.borderRadius = '12px';
            card.style.border = '1px solid var(--glass-border)';
            card.style.borderLeft = `4px solid ${isBrain ? 'var(--accent-neural-cyan)' : 'var(--text-sovereign-gold)'}`;
            card.style.display = 'flex';
            card.style.flexDirection = 'column';
            card.style.height = '100%';

            const header = el('div');
            header.style.display = 'flex';
            header.style.justifyContent = 'space-between';
            header.style.marginBottom = '0.5rem';

            const name = el('div');
            name.style.fontSize = '1.125rem';
            name.style.fontWeight = '600';
            name.textContent = agent.label;

            const badge = el('span', 'badge');
            badge.style.fontSize = '0.75rem';
            badge.style.padding = '0.25rem 0.5rem';
            badge.style.borderRadius = '4px';
            badge.style.background = 'var(--glass-bg)';
            badge.style.height = 'fit-content';
            badge.textContent = isBrain ? '🧠 Brain' : '💪 Arm';

            header.appendChild(name);
            header.appendChild(badge);

            const desc = el('div');
            desc.style.color = 'var(--text-secondary)';
            desc.style.fontSize = '0.875rem';
            desc.style.marginBottom = '1rem';
            desc.style.flex = '1'; // Push footer down
            desc.textContent = description;

            const footer = el('div');
            footer.style.marginTop = 'auto'; // Stick to bottom

            const meta = el('div');
            meta.style.display = 'flex';
            meta.style.gap = '1rem';
            meta.style.fontSize = '0.8rem';
            meta.style.color = 'var(--text-secondary)';
            meta.style.marginBottom = '1rem';
            meta.innerHTML = `<span>📊 Lvl ${agent.properties?.evolution_level || 1}</span><span>🖇️ ${skills.length} Skills</span>`;

            const btn = el('button', 'btn btn-glass btn-sm', '🔍 Dettagli & Skills');
            btn.style.width = '100%';
            btn.onclick = () => showAgentDetails(agent, description, skills);

            footer.appendChild(meta);
            footer.appendChild(btn);

            card.appendChild(header);
            card.appendChild(desc);
            card.appendChild(footer);
            container.appendChild(card);
        });

    } catch (err) {
        console.error('Failed to load agents:', err);
        container.innerHTML = `<p style="color: var(--text-secondary);">Errore caricamento agenti: ${(err as Error).message}</p>`;
    }
}

function showAgentDetails(agent: any, description: string, skills: string[]) {
    // Simple modal implementation
    const overlay = el('div');
    overlay.style.position = 'fixed';
    overlay.style.top = '0';
    overlay.style.left = '0';
    overlay.style.width = '100%';
    overlay.style.height = '100%';
    overlay.style.background = 'rgba(0,0,0,0.8)';
    overlay.style.backdropFilter = 'blur(5px)';
    overlay.style.zIndex = '1000';
    overlay.style.display = 'flex';
    overlay.style.justifyContent = 'center';
    overlay.style.alignItems = 'center';
    overlay.onclick = (e) => {
        if (e.target === overlay) document.body.removeChild(overlay);
    };

    const modal = el('div');
    modal.style.background = 'var(--bg-paper)';
    modal.style.border = '1px solid var(--accent-neural-cyan)';
    modal.style.borderRadius = '16px';
    modal.style.padding = '2rem';
    modal.style.width = '90%';
    modal.style.maxWidth = '600px';
    modal.style.maxHeight = '90vh';
    modal.style.overflowY = 'auto';
    modal.style.boxShadow = '0 0 30px rgba(10, 200, 185, 0.2)';

    const h2 = el('h2');
    h2.style.color = 'var(--text-primary)';
    h2.style.marginBottom = '0.5rem';
    h2.textContent = agent.label;

    const role = el('div');
    role.style.color = 'var(--accent-neural-cyan)';
    role.style.fontSize = '0.9rem';
    role.style.marginBottom = '1.5rem';
    role.style.fontFamily = 'monospace';
    role.textContent = `ID: ${agent.id} | Role: ${agent.properties?.role || 'N/A'}`;

    const p = el('p');
    p.style.lineHeight = '1.6';
    p.style.marginBottom = '2rem';
    p.textContent = description;

    const skillsTitle = el('h3');
    skillsTitle.style.fontSize = '1.1rem';
    skillsTitle.style.marginBottom = '1rem';
    skillsTitle.textContent = '🛠️ Skills & Capabilities';

    const skillsList = el('div');
    skillsList.style.display = 'flex';
    skillsList.style.flexWrap = 'wrap';
    skillsList.style.gap = '0.5rem';

    if (skills.length > 0) {
        skills.forEach(skill => {
            const tag = el('span');
            tag.style.background = 'rgba(10, 200, 185, 0.1)';
            tag.style.color = 'var(--accent-neural-cyan)';
            tag.style.padding = '0.25rem 0.75rem';
            tag.style.borderRadius = '20px';
            tag.style.fontSize = '0.85rem';
            tag.style.border = '1px solid rgba(10, 200, 185, 0.3)';
            tag.textContent = skill;
            skillsList.appendChild(tag);
        });
    } else {
        const empty = el('span');
        empty.style.color = 'var(--text-secondary)';
        empty.style.fontStyle = 'italic';
        empty.textContent = 'Nessuna skill esplicita mappata nel grafo.';
        skillsList.appendChild(empty);
    }

    const closeBtn = el('button', 'btn btn-primary', 'Chiudi');
    closeBtn.style.marginTop = '2rem';
    closeBtn.style.width = '100%';
    closeBtn.onclick = () => document.body.removeChild(overlay);

    modal.appendChild(h2);
    modal.appendChild(role);
    modal.appendChild(p);
    modal.appendChild(skillsTitle);
    modal.appendChild(skillsList);
    modal.appendChild(closeBtn);
    overlay.appendChild(modal);
    document.body.appendChild(overlay);
}

async function initKnowledgeGraph() {
    const container = document.getElementById('knowledge-graph');
    if (!container || !(window as any).d3) {
        console.warn('D3.js not loaded or container not found');
        if (container) {
            container.innerHTML = '<p style="padding: 2rem; text-align: center; color: var(--text-secondary);">Loading D3.js...</p>';
        }
        // Load D3.js dynamically
        const script = document.createElement('script');
        script.src = 'https://d3js.org/d3.v7.min.js';
        script.onload = () => setTimeout(() => renderGraph(), 500);
        document.head.appendChild(script);
        return;
    }
    renderGraph();
}

async function renderGraph() {
    const container = document.getElementById('knowledge-graph');
    if (!container) return;

    try {
        const graphData = await fetch('/data/knowledge-graph.json').then(r => r.json());
        const d3 = (window as any).d3;

        container.innerHTML = '';
        const width = container.clientWidth;
        const height = 600;

        const svg = d3.select('#knowledge-graph')
            .append('svg')
            .attr('width', width)
            .attr('height', height);

        const g = svg.append('g');

        const zoom = d3.zoom()
            .scaleExtent([0.1, 4])
            .on('zoom', (event: any) => g.attr('transform', event.transform));

        svg.call(zoom);

        const simulation = d3.forceSimulation(graphData.nodes)
            .force('link', d3.forceLink(graphData.edges).id((d: any) => d.id).distance(100))
            .force('charge', d3.forceManyBody().strength(-300))
            .force('center', d3.forceCenter(width / 2, height / 2));

        const link = g.append('g')
            .selectAll('line')
            .data(graphData.edges)
            .join('line')
            .attr('stroke', 'rgba(200, 170, 110, 0.3)')
            .attr('stroke-width', 2);

        const node = g.append('g')
            .selectAll('circle')
            .data(graphData.nodes)
            .join('circle')
            .attr('r', (d: any) => d.type === 'agent' ? 12 : 8)
            .attr('fill', (d: any) => {
                const colors: any = {
                    'agent': 'var(--accent-neural-cyan)',
                    'skill': 'var(--text-sovereign-gold)',
                    'document': '#F39C12',
                    'database': '#E74C3C',
                    'infrastructure': '#8b5cf6'
                };
                return colors[d.type] || '#95A5A6';
            })
            .attr('stroke', '#fff')
            .attr('stroke-width', 2)
            .call(d3.drag()
                .on('start', (event: any) => {
                    if (!event.active) simulation.alphaTarget(0.3).restart();
                    event.subject.fx = event.subject.x;
                    event.subject.fy = event.subject.y;
                })
                .on('drag', (event: any) => {
                    event.subject.fx = event.x;
                    event.subject.fy = event.y;
                })
                .on('end', (event: any) => {
                    if (!event.active) simulation.alphaTarget(0);
                    event.subject.fx = null;
                    event.subject.fy = null;
                }));

        const label = g.append('g')
            .selectAll('text')
            .data(graphData.nodes)
            .join('text')
            .text((d: any) => d.label)
            .attr('font-size', 10)
            .attr('dx', 12)
            .attr('dy', 4)
            .attr('fill', 'var(--text-primary)');

        simulation.on('tick', () => {
            link
                .attr('x1', (d: any) => d.source.x)
                .attr('y1', (d: any) => d.source.y)
                .attr('x2', (d: any) => d.target.x)
                .attr('y2', (d: any) => d.target.y);

            node
                .attr('cx', (d: any) => d.x)
                .attr('cy', (d: any) => d.y);

            label
                .attr('x', (d: any) => d.x)
                .attr('y', (d: any) => d.y);
        });

        // Bind zoom controls
        document.getElementById('btn-zoom-in')?.addEventListener('click', () => {
            svg.transition().call(zoom.scaleBy, 1.2);
        });
        document.getElementById('btn-zoom-out')?.addEventListener('click', () => {
            svg.transition().call(zoom.scaleBy, 0.8);
        });
        document.getElementById('btn-reset-graph')?.addEventListener('click', () => {
            svg.transition().call(zoom.transform, d3.zoomIdentity);
            simulation.alpha(1).restart();
        });

    } catch (err) {
        console.error('Failed to render graph:', err);
        container.innerHTML = '<p style="padding: 2rem; text-align: center; color: var(--text-secondary);">Failed to load Knowledge Graph</p>';
    }
}
