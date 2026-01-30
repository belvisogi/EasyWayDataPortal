export async function loadContent() {
    try {
        const response = await fetch('/content.json');
        if (!response.ok) throw new Error('Failed to load content');

        const data = await response.json();

        // Find all elements with data-key attribute
        const elements = document.querySelectorAll('[data-key]');

        elements.forEach(el => {
            const key = el.getAttribute('data-key');
            if (!key) return;

            // Resolve nested keys (e.g. "manifesto.verse1.title")
            const value = key.split('.').reduce((obj, k) => obj && obj[k], data);

            if (value) {
                // If the value contains HTML tags, use innerHTML, otherwise innerText
                if (typeof value === 'string' && value.includes('<')) {
                    el.innerHTML = value;
                } else {
                    el.textContent = value as string;
                }
            } else {
                console.warn(`[ContentLoader] Missing key: ${key}`);
            }
        });

        console.log(`🦅 [SovereignContent] Text Injection Complete`);
    } catch (error) {
        console.error('⚠️ [SovereignContent] Error loading content:', error);
    }
}
