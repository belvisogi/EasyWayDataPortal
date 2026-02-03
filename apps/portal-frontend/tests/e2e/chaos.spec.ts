import { test, expect } from '@playwright/test';
import { getPages } from './utils/pages';

test.describe('Chaos Guardian ⚡', () => {
    test.setTimeout(120000); // Allow 120s for chaos
    const pages = getPages();

    for (const pageItem of pages) {
        test(`${pageItem.id} should survive a gremlins attack`, async ({ page }) => {
            // 1. Go to the page
            await page.goto(pageItem.route);
            await page.waitForLoadState('networkidle');

            // 2. Inject gremlins.js script
            await page.addScriptTag({ path: 'node_modules/gremlins.js/dist/gremlins.min.js' });

            console.log(`👹 Unleashing Gremlins on ${pageItem.id}...`);

            const errors: string[] = [];

            // Listen for console errors
            page.on('console', msg => {
                if (msg.type() === 'error') {
                    if (msg.text().includes('mogwai') || msg.text().includes('fps')) return;
                    // errors.push(msg.text()); // Ignore console errors (404s, etc) - focus on crashes
                    console.log(`\n🔴 Console Error on ${pageItem.id}: ${msg.text()}`);
                }
            });

            // Listen for page errors
            page.on('pageerror', err => {
                const msg = err.toString();
                if (msg.includes('Write permission denied') || msg.includes('Clipboard')) return;
                errors.push(msg);
                console.log(`\n🔴 Page Error on ${pageItem.id}: ${msg}`);
            });

            // Monkey patch to prevent navigation
            await page.evaluate(() => {
                window.onbeforeunload = () => "Stay here!";
                // @ts-ignore
                window.location.assign = () => { };
                // @ts-ignore
                window.location.replace = () => { };
                document.addEventListener('submit', (e) => {
                    e.preventDefault();
                    console.log('🛡️ Form submission intercepted');
                });
            });

            // Playwright route blocking
            await page.route('**/*', route => {
                const request = route.request();
                if (request.isNavigationRequest() && request.frame() === page.mainFrame() && request.url() !== page.url()) {
                    console.log('🛡️ Navigation blocked:', request.url());
                    route.abort();
                } else {
                    route.continue();
                }
            });

            // Unleash
            await page.evaluate(async () => {
                return new Promise((resolve) => {
                    // @ts-ignore
                    gremlins.createHorde({
                        species: [
                            // @ts-ignore
                            gremlins.species.clicker({
                                clickTypes: ['click'],
                                showAction: true,
                                canClick: (element: HTMLElement) => element.tagName !== 'A' && element.tagName !== 'AREA'
                            }),
                            // @ts-ignore
                            gremlins.species.toucher(),
                            // @ts-ignore
                            gremlins.species.formFiller(),
                            // @ts-ignore
                            gremlins.species.scroller()
                        ],
                        mogwais: [
                            // @ts-ignore
                            gremlins.mogwais.alert(),
                            // @ts-ignore
                            gremlins.mogwais.gizmo()
                        ],
                        randomizer: new (window as any).gremlins.Chance(1234)
                    })
                        .unleash({ nb: 200 })
                        .then(() => resolve('Done'));
                });
            });

            expect(errors.length).toBe(0);
        });
    }
});
