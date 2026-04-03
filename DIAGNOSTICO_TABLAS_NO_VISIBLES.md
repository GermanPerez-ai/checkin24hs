# Diagnóstico: Tablas de Gastos y Cotizaciones No Visibles

## Problema
Las tablas de gastos y cotizaciones no se muestran aunque:
1. Los datos se cargan correctamente (39 filas agregadas al DOM)
2. Las funciones de forzado de dimensiones se ejecutan
3. Las secciones tienen `display: block !important`

## Síntomas en Consola
```
✅ Tabla de gastos renderizada: 39 filas agregadas al DOM
✅ expenses-section dimensiones forzadas: 0px x 0px
✅ expenses-section dimensiones finales: 0px x 0px
```

## Posibles Causas

### 1. El contenedor `.content` no tiene dimensiones
- `.content` solo tiene `padding: 24px` pero no tiene `width` definido
- Las secciones están dentro de `.content`
- Si `.content` tiene 0px de ancho, las secciones también tendrán 0px

### 2. Las secciones están dentro de un contenedor oculto
- `.main-content` podría estar oculto
- O algún padre intermedio está oculto

### 3. CSS está sobrescribiendo nuestros estilos inline
- Aunque usamos `!important`, podría haber CSS más específico
- O JavaScript está cambiando los estilos después

## Solución Propuesta

Ejecutar estos comandos en la consola del navegador cuando estés en la sección de gastos o cotizaciones:

```javascript
// 1. Verificar dimensiones de la cadena de contenedores
console.log('=== DIAGNÓSTICO DE DIMENSIONES ===');
const expensesSection = document.getElementById('expenses-section');
const contentDiv = document.querySelector('.content');
const mainContent = document.querySelector('.main-content');

console.log('main-content:', {
    display: window.getComputedStyle(mainContent).display,
    width: mainContent.offsetWidth,
    height: mainContent.offsetHeight,
    visibility: window.getComputedStyle(mainContent).visibility
});

console.log('.content:', {
    display: window.getComputedStyle(contentDiv).display,
    width: contentDiv.offsetWidth,
    height: contentDiv.offsetHeight,
    visibility: window.getComputedStyle(contentDiv).visibility
});

console.log('expenses-section:', {
    display: window.getComputedStyle(expensesSection).display,
    width: expensesSection.offsetWidth,
    height: expensesSection.offsetHeight,
    visibility: window.getComputedStyle(expensesSection).visibility,
    position: window.getComputedStyle(expensesSection).position
});

// 2. Verificar la tabla
const tableContainer = expensesSection?.querySelector('.table-container');
const table = tableContainer?.querySelector('table');
const tbody = table?.querySelector('tbody');

console.log('table-container:', {
    display: tableContainer ? window.getComputedStyle(tableContainer).display : 'no encontrado',
    width: tableContainer?.offsetWidth,
    height: tableContainer?.offsetHeight,
    visibility: tableContainer ? window.getComputedStyle(tableContainer).visibility : 'no encontrado'
});

console.log('table:', {
    display: table ? window.getComputedStyle(table).display : 'no encontrado',
    width: table?.offsetWidth,
    height: table?.offsetHeight
});

console.log('tbody:', {
    display: tbody ? window.getComputedStyle(tbody).display : 'no encontrado',
    rows: tbody?.rows?.length || 0
});

// 3. Forzar dimensiones manualmente
if (expensesSection) {
    expensesSection.style.cssText = `
        display: block !important;
        width: 100% !important;
        min-width: 1200px !important;
        visibility: visible !important;
        position: relative !important;
        padding: 0 !important;
        box-sizing: border-box !important;
        overflow: visible !important;
    `;
    
    if (contentDiv) {
        contentDiv.style.cssText = `
            display: block !important;
            width: 100% !important;
            min-width: 1200px !important;
            padding: 24px !important;
            box-sizing: border-box !important;
            visibility: visible !important;
            position: relative !important;
            overflow: visible !important;
        `;
    }
    
    if (tableContainer) {
        tableContainer.style.cssText = `
            display: block !important;
            visibility: visible !important;
            width: 100% !important;
            opacity: 1 !important;
        `;
    }
    
    if (table) {
        table.style.cssText = `
            display: table !important;
            visibility: visible !important;
            width: 100% !important;
            opacity: 1 !important;
        `;
    }
    
    if (tbody) {
        tbody.style.cssText = `
            display: table-row-group !important;
            visibility: visible !important;
            opacity: 1 !important;
        `;
    }
    
    // Forzar reflow
    void expensesSection.offsetWidth;
    void expensesSection.offsetHeight;
    
    console.log('=== DESPUÉS DE FORZAR ===');
    console.log('expenses-section:', {
        width: expensesSection.offsetWidth,
        height: expensesSection.offsetHeight
    });
}
```
