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
    gedi.addEventListener('click', () => {
        console.log('GEDI Interaction detected.');
        // Simple visual feedback
        gedi.style.transform = 'scale(0.9)';
        setTimeout(() => {
            gedi.style.transform = 'scale(1)';
        }, 200);
    });
}
