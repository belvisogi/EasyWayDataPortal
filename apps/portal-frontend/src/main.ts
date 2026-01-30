/**
 * easyway-core (main.ts)
 * ----------------------
 * @branding EasyWay Core
 * @codebase EasyWayDataPortal
 * 
 * ARCHITECTURAL NOTE:
 * We intentionally keep the 'EasyWayDataPortal' namespace in code to ensure
 * backward compatibility with Docker volumes and GitOps scripts.
 * The UI renders "EasyWay Core".
 */
// ---------------------------------------------------------------------------
// "Non costruiamo software. Coltiviamo ecosistemi di pensiero." 
// Co-Authored: gbelviso78 & Antigravity/Codex/ChatGPT (2026-01-30)
// ---------------------------------------------------------------------------
import { loadBranding } from './utils/theme-loader';
import './components/sovereign-header';
import './components/sovereign-footer';

// Initialize Branding (Dynamic Theme)
loadBranding();
console.log(
    "%c EasyWay Core %c Sovereign Intelligence Online ",
    "background: #eaa91c; color: #000; font-weight: bold; padding: 4px; border-radius: 4px 0 0 4px;",
    "background: #060b13; color: #4deeea; padding: 4px; border-radius: 0 4px 4px 0;"
);
console.log("%c > Ci adattiamo alle novità evolvendoci grazie a loro.", "color: #888; font-style: italic;");

// Main Entry Point - EasyWay One (Sovereign Intelligence)
console.log("EasyWay Sovereign System: Initializing... [v0.2.1]");

const btnEngage = document.getElementById('btn-engage');
const marketingLayer = document.getElementById('marketing-layer');
const operatorLayer = document.getElementById('operator-layer');
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
    marketingLayer?.classList.add('fade-out-down');

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

async function handleFiles(files: FileList) {
    if (files.length === 0) return;

    const file = files[0];
    typeToCortex(`DETECTED ARTIFACT: ${file.name}. INITIATING TRANSFER...`, 'system');

    // 1. Visual Feedack: Pulsing Gold
    const core = document.querySelector('.neural-core') as HTMLElement;
    if (core) core.style.animation = "pulse-gold 1s infinite";

    // 2. Prepare Payload
    const formData = new FormData();
    formData.append('data', file);

    try {
        // 3. The Transmission
        // 3. The Transmission
        // SOVEREIGN CONFIGURATION (No Hardcoding)
        const baseUrl = window.SOVEREIGN_CONFIG?.apiEndpoint || "http://localhost:5678";
        const webhookUrl = `${baseUrl}/webhook/ingest`;

        typeToCortex(`UPLOADING TO VAULT (MinIO)...`, 'system');

        // Real Fetch
        const response = await fetch(webhookUrl, {
            method: 'POST',
            body: formData
        });

        if (response.ok) {
            typeToCortex("✅ UPLOAD COMPLETE. ARTIFACT SECURED.", 'ai');
            if (core) {
                core.style.borderColor = "var(--sovereign-success)";
                core.style.boxShadow = "0 0 50px var(--sovereign-success)";
                setTimeout(() => {
                    core.style.borderColor = "";
                    core.style.boxShadow = "";
                    core.style.animation = "";
                }, 2000);
            }
        } else {
            throw new Error(`Server rejected: ${response.status}`);
        }

    } catch (error) {
        typeToCortex(`❌ UPLOAD FAILED: ${(error as Error).message}`, 'system');
        typeToCortex(`HINT: Is Port 5678 Open?`, 'system');

        if (core) {
            core.style.borderColor = "var(--sovereign-error)";
            core.style.animation = "shake 0.5s";
            setTimeout(() => {
                core.style.borderColor = "";
                core.style.animation = "";
            }, 2000);
        }
    }
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

function typeToCortex(text: string, type: 'system' | 'user' | 'ai' | 'warn' = 'system') {
    const history = document.getElementById('cortex-history');
    if (!history) return;

    const div = document.createElement('div');
    div.className = `msg ${type}`;
    div.innerText = text;

    if (type === 'ai') div.style.color = 'var(--accent-neural-cyan)';
    if (type === 'ai') div.style.color = 'var(--accent-neural-cyan)';
    if (type === 'user') div.style.color = 'var(--text-sovereign-gold)';
    if (type === 'warn') div.style.color = '#ef4444'; // Red for warning

    history.appendChild(div);
    history.scrollTop = history.scrollHeight;
}

// --- GEDI: MEASURE TWICE PROTOCOL ---
let gediState = {
    awaitingConfirmation: false,
    pendingCommand: ""
};

function respondToCommand(cmd: string) {
    // 1. Check for Pending Confirmation (Measure Twice)
    if (gediState.awaitingConfirmation) {
        if (cmd === "CONFERMO DISTRUZIONE") {
            typeToCortex("⚠️ ACTION AUTHORIZED. EXECUTING...", 'warn');
            // Execute actual destructive logic here
            setTimeout(() => {
                const core = document.querySelector('.neural-core') as HTMLElement;
                if (core) core.style.background = "#ef4444"; // Red Flash
                typeToCortex("💥 PROTOCOL EXECUTED. SYSTEM RESET.", 'system');
                setTimeout(() => location.reload(), 2000);
            }, 1000);
            gediState.awaitingConfirmation = false;
        } else {
            typeToCortex("❌ CONFIRMATION FAILED. ABORTING.", 'system');
            gediState.awaitingConfirmation = false;
        }
        return;
    }

    let response = "COMMAND NOT RECOGNIZED. TRY 'STATUS' OR 'AGENTS'.";

    // 2. Critical Commands -> Trigger Measure Twice
    if (cmd === "DESTROY" || cmd === "RESET" || cmd === "DELETE") {
        gediState.awaitingConfirmation = true;
        gediState.pendingCommand = cmd;

        // UI Freeze Effect
        document.body.style.filter = "grayscale(100%)";
        setTimeout(() => document.body.style.filter = "", 200);

        typeToCortex("🛑 CRITICAL ACTION DETECTED. GEDI INTERVENTION.", 'warn');
        typeToCortex("GEDI: 'Hai misurato due volte? Questa azione è irreversibile.'", 'ai');
        setTimeout(() => typeToCortex("TYPE 'CONFERMO DISTRUZIONE' TO PROCEED.", 'system'), 500);
        return;
    }

    // 3. Standard Commands
    if (cmd.includes("STATUS")) response = "SYSTEM NOMINAL. CPU: 45%. RAM: 12GB. NETWORK: SECURE.";
    if (cmd.includes("AGENTS") || cmd.includes("GRID")) response = "AVAILABLE OPERATIVES: GEDI, SQL-EDGE, ARCHITECT.";
    if (cmd.includes("HELLO") || cmd.includes("HI")) response = "GREETINGS, ADMINISTRATOR.";
    if (cmd.includes("HELP")) response = "COMMANDS: STATUS, AGENTS, MATRIX, DESTROY, EXIT, RULES.";

    // GEDI Core Personality
    if (cmd.includes("RULES") || cmd.includes("GEDI") || cmd.includes("LEGGE")) {
        response = "GEDI: Ordine e Disciplina. Eliminare la ridondanza. (Project: No More Rabbits). 🐇🚫";
    }

    // Data Interaction
    if (cmd === "MATRIX") {
        response = "ENTERING VECTOR VOID...";
        toggleMatrix(true);
    }
    if (cmd === "EXIT") {
        response = "RETURNING TO COCKPIT.";
        toggleMatrix(false);
    }

    // --- GENESIS PROTOCOL (Interactive Setup) ---
    if (cmd === "INITIATE GENESIS") {
        startGenesis();
        return;
    }

    if (genesisState.active) {
        handleGenesisInput(cmd);
        return;
    }

    typeToCortex(response, 'ai');
}

// --- GENESIS LOGIC ---
let genesisState = {
    active: false,
    step: 0,
    data: {
        archetype: "",
        enemy: "",
        color: ""
    }
};

function startGenesis() {
    genesisState.active = true;
    genesisState.step = 1;
    typeToCortex("--- GENESIS PROTOCOL INITIATED ---", 'system');
    setTimeout(() => typeToCortex("I AM THE ARCHITECT. LET US DEFINE YOUR IDENTITY.", 'ai'), 500);
    setTimeout(() => typeToCortex("QUESTION 1: WHAT IS YOUR ARCHETYPE? (Warrior / Mage / Rogue / Sovereign)", 'ai'), 1500);
}

function handleGenesisInput(cmd: string) {
    // Step 1: Archetype
    if (genesisState.step === 1) {
        genesisState.data.archetype = cmd;
        typeToCortex(`ARCHETYPE REGISTERED: ${cmd}.`, 'system');
        setTimeout(() => typeToCortex("QUESTION 2: WHO IS THE ENEMY? (Chaos / Bureaucracy / Silence / The Void)", 'ai'), 800);
        genesisState.step = 2;
        return;
    }

    // Step 2: Enemy (Mood)
    if (genesisState.step === 2) {
        genesisState.data.enemy = cmd;
        typeToCortex(`TARGET LOCKED: ${cmd}.`, 'system');
        setTimeout(() => typeToCortex("QUESTION 3: DEFINE YOUR POWER COLOR. (Hex Code, e.g., #FF0000 or 'GOLD')", 'ai'), 800);
        genesisState.step = 3;
        return;
    }

    // Step 3: Color -> Generate
    if (genesisState.step === 3) {
        genesisState.data.color = cmd;
        typeToCortex(`POWER SOURCE: ${cmd}.`, 'system');
        setTimeout(() => typeToCortex("CALCULATING SOUL CONFIGURATION...", 'system'), 500);

        setTimeout(() => {
            generateTheme(genesisState.data);
            genesisState.active = false;
            genesisState.step = 0;
        }, 1500);
        return;
    }
}

function generateTheme(data: any) {
    const color = data.color.startsWith('#') ? data.color : '#c8aa6e'; // Default to gold if invalid

    const themeConfig = `
/* COPY THIS INTO src/theme.css */
:root {
    /* IDENTITY: ${data.archetype} vs ${data.enemy} */
    --bg-deep-void: #060b13; /* Standard Base */
    --text-sovereign-gold: ${color}; /* Authority */
    --accent-neural-cyan: ${color}; /* Power Source */
    
    --glass-border: ${color}26; /* 15% Opacity */
    --glass-bg: rgba(6, 11, 19, 0.7);
}
    `;

    typeToCortex("--- CONFIGURATION COMPLETE ---", 'system');
    typeToCortex("COPY THE FOLLOWING CSS BLOCK:", 'ai');
    typeToCortex(themeConfig, 'system');
    console.log(themeConfig); // Also log to console for easy copy
    setTimeout(() => typeToCortex("PROOTCOL FINISHED. WELCOME HOME.", 'ai'), 1000);
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
// Force Update: 01/27/2026 19:48:43
