// Script para extraer código de gastos y cotizaciones de muleto.html
const fs = require('fs');
const path = require('path');

const muletoPath = 'C:/Users/German/Downloads/admincheckin/muleto.html';
const dashboardPath = 'dashboard.html';

console.log('📖 Leyendo muleto.html...');
const muletoContent = fs.readFileSync(muletoPath, 'utf-8');

// Extraer expenses-section completa
const expensesSectionMatch = muletoContent.match(/<!-- Expenses Section -->[\s\S]*?<\/div>\s*<\/div>\s*<\/div>/);
const expensesSection = expensesSectionMatch ? expensesSectionMatch[0] : null;

// Extraer quotes-section completa  
const quotesSectionMatch = muletoContent.match(/<!-- Quotes Section -->[\s\S]*?<\/div>\s*<\/div>/);
const quotesSection = quotesSectionMatch ? quotesSectionMatch[0] : null;

// Extraer modal expenseModal completo
const expenseModalMatch = muletoContent.match(/<!-- Modal de Agregar\/Editar Gasto -->[\s\S]*?<\/div>\s*<\/div>\s*<\/div>/);
const expenseModal = expenseModalMatch ? expenseModalMatch[0] : null;

// Extraer modal cameraModal completo
const cameraModalMatch = muletoContent.match(/<!-- Modal de Captura de Cámara -->[\s\S]*?<\/div>\s*<\/div>\s*<\/div>/);
const cameraModal = cameraModalMatch ? cameraModalMatch[0] : null;

console.log('✅ Secciones extraídas:');
console.log('  - expenses-section:', expensesSection ? '✅' : '❌');
console.log('  - quotes-section:', quotesSection ? '✅' : '❌');
console.log('  - expenseModal:', expenseModal ? '✅' : '❌');
console.log('  - cameraModal:', cameraModal ? '✅' : '❌');

// Guardar en archivos temporales
if (expensesSection) fs.writeFileSync('expenses_section.txt', expensesSection);
if (quotesSection) fs.writeFileSync('quotes_section.txt', quotesSection);
if (expenseModal) fs.writeFileSync('expense_modal.txt', expenseModal);
if (cameraModal) fs.writeFileSync('camera_modal.txt', cameraModal);

console.log('✅ Archivos temporales creados');
