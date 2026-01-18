
const fs = require('fs');
const path = require('path');

const gapFile = path.resolve(__dirname, '../wiki-gap.all.json');
const rootDir = path.resolve(__dirname, '../Wiki/EasyWayData.wiki');

try {
    const gapContent = fs.readFileSync(gapFile, 'utf8');
    const gapData = JSON.parse(gapContent);

    let updatedCount = 0;

    gapData.results.forEach(item => {
        if (item.status === 'draft') {
            const filePath = path.join(rootDir, item.file);
            if (fs.existsSync(filePath)) {
                let content = fs.readFileSync(filePath, 'utf8');
                // Replace "status: draft" with "status: active" in frontmatter
                // Assuming frontmatter is at the top
                const newContent = content.replace(/^status:\s*draft/m, 'status: active');

                if (content !== newContent) {
                    fs.writeFileSync(filePath, newContent, 'utf8');
                    console.log(`Updated: ${item.file}`);
                    updatedCount++;
                } else {
                    // Try searching for "status: " line to be sure
                    console.log(`Skipped (pattern not matched): ${item.file}`);
                }
            } else {
                console.log(`File not found: ${item.file}`);
            }
        }
    });

    console.log(`Total files updated: ${updatedCount}`);

} catch (err) {
    console.error('Error:', err);
}
