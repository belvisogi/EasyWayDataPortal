import './style.css'

// Main Entry Point - EasyWay One (Sovereign Intelligence)
console.log("EasyWay Sovereign System: Initializing... [v0.2.1]");

const btnEngage = document.getElementById('btn-engage');
const marketingLayer = document.getElementById('marketing-layer');
const operatorLayer = document.getElementById('operator-layer');
const heroText = document.getElementById('hero-text');
const features = document.getElementById('features-section');
const cortexInput = document.getElementById('cortex-input') as HTMLInputElement;

// --- STATE MANAGEMENT ---
if (btnEngage) {
    btnEngage.addEventListener('click', (e) => {
        e.preventDefault();
        initiateProtocol();
    });
}

function initiateProtocol() {
    console.log("Protocol Initiated.");

    // 1. Fade out Marketing
    heroText?.classList.add('fade-out-down');
    features?.classList.add('fade-out-down');

    // 2. Reveal Operator UI (after delay)
    setTimeout(() => {
        operatorLayer?.classList.remove('hidden');
        cortexInput?.focus();

        // Simulate "System Boot" messages
        typeToCortex("SYSTEM.CORE // ONLINE");
        setTimeout(() => typeToCortex("INTELLIGENCE // SOVEREIGN"), 800);
        setTimeout(() => typeToCortex("AWAITING DIRECTIVE..."), 1600);
    }, 800);

    initDragAndDrop();
}

// --- DRAG & DROP LOGIC ---
function initDragAndDrop() {
    const core = document.querySelector('.neural-core');
    if (!core) return;

    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        document.body.addEventListener(eventName, preventDefaults, false);
    });

    document.body.addEventListener('dragover', () => {
        core.classList.add('drag-over');
    });

    ['dragleave', 'drop'].forEach(eventName => {
        document.body.addEventListener(eventName, () => {
            core.classList.remove('drag-over');
        });
    });

    document.body.addEventListener('drop', (e: any) => {
        const dt = e.dataTransfer;
        const files = dt.files;
        handleFiles(files);
    });
}

function preventDefaults(e: Event) {
    e.preventDefault();
    e.stopPropagation();
}

function handleFiles(files: FileList) {
    // Simulate Absorption
    typeToCortex(`DETECTED ${files.length} NEW ARTIFACTS. ABSORBING...`, 'system');

    setTimeout(() => {
        typeToCortex("VECTOR EMBEDDING GENERATED. KNOWLEDGE INTEGRATED.", 'ai');
    }, 1500);
}

// --- CORTEX LOGIC ---
if (cortexInput) {
    cortexInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && cortexInput.value.trim() !== "") {
            const cmd = cortexInput.value.toUpperCase();
            cortexInput.value = "";

            // User Msg
            typeToCortex(`> ${cmd}`, 'user');

            // AI Response Sim
            setTimeout(() => {
                respondToCommand(cmd);
            }, 500);
        }
    });
}

function typeToCortex(text: string, type: 'system' | 'user' | 'ai' = 'system') {
    const history = document.getElementById('cortex-history');
    if (!history) return;

    const div = document.createElement('div');
    div.className = `msg ${type}`;
    div.innerText = text;

    if (type === 'ai') div.style.color = 'var(--accent-neural-cyan)';
    if (type === 'user') div.style.color = 'var(--text-sovereign-gold)';

    history.appendChild(div);
    history.scrollTop = history.scrollHeight;
}

function respondToCommand(cmd: string) {
    let response = "COMMAND NOT RECOGNIZED. TRY 'STATUS' OR 'AGENTS'.";

    if (cmd.includes("STATUS")) response = "SYSTEM NOMINAL. CPU: 45%. RAM: 12GB. NETWORK: SECURE.";
    if (cmd.includes("AGENTS") || cmd.includes("GRID")) response = "AVAILABLE OPERATIVES: GEDI, SQL-EDGE, ARCHITECT.";
    if (cmd.includes("HELLO") || cmd.includes("HI")) response = "GREETINGS, ADMINISTRATOR.";
    if (cmd.includes("HELP")) response = "COMMANDS: STATUS, AGENTS, MATRIX, EXIT.";

    // Data Interaction
    if (cmd === "MATRIX") {
        response = "ENTERING VECTOR VOID...";
        toggleMatrix(true);
    }
    if (cmd === "EXIT") {
        response = "RETURNING TO COCKPIT.";
        toggleMatrix(false);
    }

    typeToCortex(response, 'ai');
}

// --- VECTOR VOID (MATRIX) ---
let particleLoop: number;
function toggleMatrix(active: boolean) {
    const canvas = document.getElementById('vector-canvas') as HTMLCanvasElement;
    if (!canvas) return;

    if (active) {
        canvas.classList.remove('hidden');
        initParticles(canvas);
        // Hide Main UI for immersion? Or keep overlay?
        // Let's keep transparent overlay
    } else {
        canvas.classList.add('hidden');
        cancelAnimationFrame(particleLoop);
    }
}

function initParticles(canvas: HTMLCanvasElement) {
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let width = canvas.width = window.innerWidth;
    let height = canvas.height = window.innerHeight;

    const nodes: any[] = [];
    const nodeCount = 60;

    for (let i = 0; i < nodeCount; i++) {
        nodes.push({
            x: Math.random() * width,
            y: Math.random() * height,
            vx: (Math.random() - 0.5) * 0.5,
            vy: (Math.random() - 0.5) * 0.5
        });
    }

    function animate() {
        if (!ctx) return;
        ctx.clearRect(0, 0, width, height);

        ctx.fillStyle = '#0ea5e9';
        ctx.strokeStyle = 'rgba(14, 165, 233, 0.2)';

        for (let i = 0; i < nodeCount; i++) {
            let n = nodes[i];
            n.x += n.vx;
            n.y += n.vy;
            if (n.x < 0 || n.x > width) n.vx *= -1;
            if (n.y < 0 || n.y > height) n.vy *= -1;

            ctx.beginPath();
            ctx.arc(n.x, n.y, 2, 0, Math.PI * 2);
            ctx.fill();

            // Connections
            for (let j = i + 1; j < nodeCount; j++) {
                let n2 = nodes[j];
                let dist = Math.sqrt((n.x - n2.x) ** 2 + (n.y - n2.y) ** 2);
                if (dist < 150) {
                    ctx.beginPath();
                    ctx.moveTo(n.x, n.y);
                    ctx.lineTo(n2.x, n2.y);
                    ctx.stroke();
                }
            }
        }
        particleLoop = requestAnimationFrame(animate);
    }
    animate();
}
