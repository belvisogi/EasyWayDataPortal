/**
 * Knowledge Graph Visualization using D3.js
 * Interactive force-directed graph of agents, skills, and dependencies
 */

const KnowledgeGraphViz = {
    svg: null,
    simulation: null,
    transform: null,

    init() {
        console.log('🗺️ Initializing Knowledge Graph visualization...');

        // Setup controls
        this.setupControls();

        // Wait for graph data to load
        this.waitForData();
    },

    waitForData() {
        const checkData = setInterval(() => {
            if (ConsoleApp.state.graph) {
                clearInterval(checkData);
                this.render(ConsoleApp.state.graph);
            }
        }, 100);
    },

    setupControls() {
        const zoomIn = document.getElementById('btn-zoom-in');
        const zoomOut = document.getElementById('btn-zoom-out');
        const reset = document.getElementById('btn-reset-graph');

        if (zoomIn) zoomIn.addEventListener('click', () => this.zoom(1.2));
        if (zoomOut) zoomOut.addEventListener('click', () => this.zoom(0.8));
        if (reset) reset.addEventListener('click', () => this.resetGraph());
    },

    render(graphData) {
        const container = document.getElementById('knowledge-graph');
        if (!container) return;

        // Clear existing
        container.innerHTML = '';

        const width = container.clientWidth;
        const height = container.clientHeight;

        // Create SVG
        this.svg = d3.select('#knowledge-graph')
            .append('svg')
            .attr('width', width)
            .attr('height', height)
            .attr('viewBox', [0, 0, width, height]);

        // Add zoom behavior
        const zoom = d3.zoom()
            .scaleExtent([0.1, 4])
            .on('zoom', (event) => {
                this.transform = event.transform;
                g.attr('transform', event.transform);
            });

        this.svg.call(zoom);

        const g = this.svg.append('g');

        // Prepare data
        const nodes = graphData.nodes.map(n => ({
            id: n.id,
            label: n.label,
            type: n.type,
            group: this.getNodeGroup(n.type)
        }));

        const links = graphData.edges.map(e => ({
            source: e.source,
            target: e.target,
            type: e.type
        }));

        // Create force simulation
        this.simulation = d3.forceSimulation(nodes)
            .force('link', d3.forceLink(links).id(d => d.id).distance(100))
            .force('charge', d3.forceManyBody().strength(-300))
            .force('center', d3.forceCenter(width / 2, height / 2))
            .force('collision', d3.forceCollide().radius(30));

        // Draw links
        const link = g.append('g')
            .selectAll('line')
            .data(links)
            .join('line')
            .attr('stroke', '#BDC3C7')
            .attr('stroke-width', 2)
            .attr('stroke-opacity', 0.6);

        // Draw nodes
        const node = g.append('g')
            .selectAll('circle')
            .data(nodes)
            .join('circle')
            .attr('r', d => this.getNodeSize(d.type))
            .attr('fill', d => this.getNodeColor(d.type))
            .attr('stroke', '#fff')
            .attr('stroke-width', 2)
            .call(this.drag(this.simulation));

        // Add labels
        const label = g.append('g')
            .selectAll('text')
            .data(nodes)
            .join('text')
            .text(d => d.label)
            .attr('font-size', 10)
            .attr('dx', 12)
            .attr('dy', 4)
            .attr('fill', '#2C3E50');

        // Add tooltips
        node.append('title')
            .text(d => `${d.label}\nType: ${d.type}`);

        // Update positions on tick
        this.simulation.on('tick', () => {
            link
                .attr('x1', d => d.source.x)
                .attr('y1', d => d.source.y)
                .attr('x2', d => d.target.x)
                .attr('y2', d => d.target.y);

            node
                .attr('cx', d => d.x)
                .attr('cy', d => d.y);

            label
                .attr('x', d => d.x)
                .attr('y', d => d.y);
        });

        console.log(`✅ Graph rendered: ${nodes.length} nodes, ${links.length} edges`);
    },

    getNodeGroup(type) {
        const groups = {
            'agent': 1,
            'skill': 2,
            'document': 3,
            'database': 4,
            'infrastructure': 5
        };
        return groups[type] || 0;
    },

    getNodeSize(type) {
        const sizes = {
            'agent': 12,
            'skill': 8,
            'document': 6,
            'database': 10,
            'infrastructure': 10
        };
        return sizes[type] || 6;
    },

    getNodeColor(type) {
        const colors = {
            'agent': '#3498DB',      // Blue
            'skill': '#27AE60',      // Green
            'document': '#F39C12',   // Orange
            'database': '#E74C3C',   // Red
            'infrastructure': '#9B59B6' // Purple
        };
        return colors[type] || '#95A5A6';
    },

    drag(simulation) {
        function dragstarted(event) {
            if (!event.active) simulation.alphaTarget(0.3).restart();
            event.subject.fx = event.subject.x;
            event.subject.fy = event.subject.y;
        }

        function dragged(event) {
            event.subject.fx = event.x;
            event.subject.fy = event.y;
        }

        function dragended(event) {
            if (!event.active) simulation.alphaTarget(0);
            event.subject.fx = null;
            event.subject.fy = null;
        }

        return d3.drag()
            .on('start', dragstarted)
            .on('drag', dragged)
            .on('end', dragended);
    },

    zoom(factor) {
        if (!this.svg) return;

        const currentTransform = this.transform || d3.zoomIdentity;
        const newTransform = currentTransform.scale(factor);

        this.svg.transition()
            .duration(300)
            .call(d3.zoom().transform, newTransform);
    },

    resetGraph() {
        if (!this.svg) return;

        this.svg.transition()
            .duration(500)
            .call(d3.zoom().transform, d3.zoomIdentity);

        if (this.simulation) {
            this.simulation.alpha(1).restart();
        }
    }
};

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => KnowledgeGraphViz.init());
} else {
    KnowledgeGraphViz.init();
}

window.KnowledgeGraphViz = KnowledgeGraphViz;
