import './style.css'

console.log('EasyWay Portal Initialized. System Status: Nominal.');

const engageBtn = document.getElementById('btn-engage');
const gedi = document.getElementById('gedi-guardian');

if (engageBtn) {
    engageBtn.addEventListener('click', (e) => {
        e.preventDefault();
        console.log('User requested system initialization...');
        alert('System Initialization Sequence Started... [Demo Mode]');
    });
}

if (gedi) {
    let themeStep = 0;
    const themes = ['', 'theme-shield', 'theme-terminal'];

    gedi.addEventListener('click', () => {
        console.log('GEDI Interaction: Cycling Visual Concepts...');

        // Cycle themes
        themeStep = (themeStep + 1) % themes.length;
        document.body.className = themes[themeStep];

        // Visual feedback
        gedi.style.transform = 'scale(0.9)';

        let modeName = "Pulse";
        if (themeStep === 1) modeName = "Shield";
        if (themeStep === 2) modeName = "Terminal";

        console.log(`Switched to Concept: ${modeName}`);

        // Update engage button text for fun
        if (engageBtn) {
            if (themeStep === 2) engageBtn.textContent = "> EXECUTE_INIT";
            else engageBtn.textContent = "access_protocol.init()";
        }

        setTimeout(() => {
            gedi.style.transform = 'scale(1)';
        }, 200);
    });
}
