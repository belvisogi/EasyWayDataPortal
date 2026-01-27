import './style.css'

// Main Entry Point - EasyWay One (Sovereign Intelligence)
console.log("EasyWay Sovereign System: Initializing...");

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
    if (cmd.includes("HELP")) response = "COMMANDS: STATUS, AGENTS, SCAN, DEPLOY.";

    typeToCortex(response, 'ai');
}
