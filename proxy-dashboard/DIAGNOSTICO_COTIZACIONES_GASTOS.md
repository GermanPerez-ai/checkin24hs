# 🔍 Diagnóstico: Cotizaciones y Gastos no se Muestran

## Pasos para diagnosticar:

### 1. Verificar que el código actualizado está en el servidor

```bash
# En el servidor, verificar la versión del código
# El código debe tener la lógica para cargar cotizaciones cuando se muestra la sección
```

### 2. Verificar en el navegador (Consola del desarrollador)

Abre la consola del navegador (F12) y ejecuta:

```javascript
// Verificar si las funciones existen
console.log('loadQuotesTable:', typeof loadQuotesTable);
console.log('loadExpensesData:', typeof loadExpensesData);
console.log('updateQuotesStats:', typeof updateQuotesStats);

// Verificar si hay datos
console.log('Cotizaciones en localStorage:', JSON.parse(localStorage.getItem('quotesDB') || '[]').length);
console.log('Gastos en localStorage:', JSON.parse(localStorage.getItem('expensesDB') || '[]').length);

// Intentar cargar manualmente
if (typeof loadQuotesTable === 'function') {
    loadQuotesTable();
}
if (typeof loadExpensesData === 'function') {
    loadExpensesData();
}
```

### 3. Verificar errores en la consola

Busca errores en rojo en la consola del navegador que puedan estar impidiendo la ejecución.

### 4. Verificar que el código se actualizó

El código debe tener esta sección en la función `showSection`:

```javascript
if (section === 'quotes') {
    setTimeout(() => {
        if (typeof loadQuotesTable === 'function') {
            loadQuotesTable();
        }
        if (typeof updateQuotesStats === 'function') {
            updateQuotesStats();
        }
    }, 100);
}
```

## Solución si el código no está actualizado:

1. Hacer git pull en el servidor
2. Implementar el servicio dashboard desde EasyPanel
3. Recargar la página del dashboard (Ctrl+F5)
