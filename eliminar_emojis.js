const fs = require('fs');

// Leer el archivo
let content = fs.readFileSync('dashboard.html', 'utf8');

// Eliminar emojis comunes usando expresiones regulares
const emojiPatterns = [
    /\u{1F3AB}/gu,  // 🎫
    /\u{1F916}/gu,  // 🤖
    /\u{2705}/gu,   // ✅
    /\u{1F4BE}/gu,  // 💾
    /\u{1F44B}/gu,  // 👋
    /\u{1F64F}/gu   // 🙏
];

emojiPatterns.forEach(pattern => {
    content = content.replace(pattern, '');
});

// Guardar el archivo
fs.writeFileSync('dashboard.html', content, 'utf8');
console.log('Emojis eliminados exitosamente');

