# 🔍 Diagnóstico: Funciones y Datos

## El código está actualizado, pero no se muestran los datos

## Posibles causas:
1. Las funciones no existen o no se están ejecutando
2. No hay datos en localStorage o Supabase
3. Hay errores en JavaScript que impiden la ejecución
4. Supabase no está inicializado correctamente

## Verificaciones en el navegador:

Abre la consola del navegador (F12) y ejecuta:

```javascript
// 1. Verificar si las funciones existen
console.log('=== Verificando funciones ===');
console.log('loadQuotesTable:', typeof loadQuotesTable);
console.log('loadExpensesData:', typeof loadExpensesData);
console.log('updateQuotesStats:', typeof updateQuotesStats);

// 2. Verificar datos
console.log('');
console.log('=== Verificando datos ===');
const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
console.log('Cotizaciones en localStorage:', quotes.length);
console.log('Gastos en localStorage:', expenses.length);

// 3. Verificar Supabase
console.log('');
console.log('=== Verificando Supabase ===');
console.log('window.supabaseClient:', typeof window.supabaseClient);
if (window.supabaseClient) {
    console.log('Supabase inicializado:', window.supabaseClient.isInitialized());
}

// 4. Intentar cargar manualmente
console.log('');
console.log('=== Intentando cargar manualmente ===');
if (typeof loadQuotesTable === 'function') {
    console.log('Ejecutando loadQuotesTable...');
    loadQuotesTable().then(() => {
        console.log('✅ loadQuotesTable completado');
    }).catch(err => {
        console.error('❌ Error en loadQuotesTable:', err);
    });
} else {
    console.error('❌ loadQuotesTable no existe');
}

if (typeof loadExpensesData === 'function') {
    console.log('Ejecutando loadExpensesData...');
    loadExpensesData();
    console.log('✅ loadExpensesData ejecutado');
} else {
    console.error('❌ loadExpensesData no existe');
}

// 5. Verificar si las secciones están visibles
console.log('');
console.log('=== Verificando secciones ===');
const quotesSection = document.getElementById('quotes-section');
const expensesSection = document.getElementById('expenses-section');
console.log('quotes-section display:', quotesSection ? quotesSection.style.display : 'no encontrada');
console.log('expenses-section display:', expensesSection ? expensesSection.style.display : 'no encontrada');
```

## También verifica:
- ¿Hay errores en rojo en la consola?
- ¿Las secciones se muestran cuando haces clic en el menú?
- ¿Aparece el mensaje "No hay cotizaciones" o "No hay gastos"?
