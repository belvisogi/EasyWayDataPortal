import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

export const getPages = () => {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const manifestPath = path.resolve(__dirname, '../../../public/pages/pages.manifest.json');
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf-8'));
    return manifest.pages.map((p: any) => ({
        id: p.id,
        route: p.route,
        titleKey: p.titleKey
    }));
};
