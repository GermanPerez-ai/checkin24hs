const fs = require('fs');
const path = require('path');

const dashboardPath = path.join(__dirname, 'dashboard.html');

fs.readFile(dashboardPath, 'utf8', (err, data) => {
    if (err) {
        console.error('Error reading dashboard.html:', err);
        process.exit(1);
    }

    const now = new Date().toISOString();
    const updatedContent = data.replace(
        /window\.BUILD_TIMESTAMP = '.*';/,
        `window.BUILD_TIMESTAMP = '${now}';`
    );

    if (updatedContent === data) {
        console.warn('⚠️ No se encontró BUILD_TIMESTAMP para actualizar');
        process.exit(1);
    }

    fs.writeFile(dashboardPath, updatedContent, 'utf8', (err) => {
        if (err) {
            console.error('Error writing dashboard.html:', err);
            process.exit(1);
        }
        console.log(`✅ BUILD_TIMESTAMP actualizado a ${now} en dashboard.html`);
    });
});
