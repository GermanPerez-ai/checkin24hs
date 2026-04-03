# 🔍 Script de Diagnóstico para Consola

## 📋 Instrucciones

1. Abre la **Consola del Navegador** (F12 → pestaña Console)
2. Copia y pega el siguiente código completo
3. Presiona Enter para ejecutarlo
4. Comparte los resultados

## 🔧 Script Completo de Diagnóstico

```javascript
// ============================================
// DIAGNÓSTICO COMPLETO DE SECCIONES
// ============================================

console.log('🔍 ===== INICIANDO DIAGNÓSTICO =====');

// 1. Verificar secciones específicas
const sectionsToCheck = ['quotes', 'expenses'];
sectionsToCheck.forEach(sectionName => {
    console.log(`\n📋 Verificando sección: ${sectionName}`);
    const section = document.getElementById(`${sectionName}-section`);
    
    if (!section) {
        console.error(`❌ Sección ${sectionName}-section NO EXISTE en el DOM`);
        return;
    }
    
    console.log(`✅ Sección encontrada: ${sectionName}-section`);
    
    // Verificar estilos inline
    const inlineStyle = section.getAttribute('style') || '';
    console.log(`  - Estilo inline: ${inlineStyle || '(ninguno)'}`);
    
    // Verificar estilos computados
    const computed = window.getComputedStyle(section);
    console.log(`  - Display computado: ${computed.display}`);
    console.log(`  - Visibility computado: ${computed.visibility}`);
    console.log(`  - Opacity computado: ${computed.opacity}`);
    console.log(`  - Height computado: ${computed.height}`);
    console.log(`  - Min-height computado: ${computed.minHeight}`);
    console.log(`  - Position computado: ${computed.position}`);
    console.log(`  - Z-index computado: ${computed.zIndex}`);
    console.log(`  - Overflow computado: ${computed.overflow}`);
    
    // Verificar dimensiones
    console.log(`  - OffsetHeight: ${section.offsetHeight}px`);
    console.log(`  - OffsetWidth: ${section.offsetWidth}px`);
    console.log(`  - ScrollHeight: ${section.scrollHeight}px`);
    console.log(`  - ClientHeight: ${section.clientHeight}px`);
    console.log(`  - ClientWidth: ${section.clientWidth}px`);
    
    // Verificar si está visible
    const isVisible = section.offsetParent !== null;
    console.log(`  - ¿Está visible? (offsetParent !== null): ${isVisible}`);
    
    // Verificar contenedores padres
    console.log(`\n  📦 Verificando contenedores padres:`);
    let parent = section.parentElement;
    let level = 0;
    const parentChain = [];
    
    while (parent && level < 15) {
        const parentComputed = window.getComputedStyle(parent);
        const parentInfo = {
            level: level,
            tag: parent.tagName,
            id: parent.id || '(sin id)',
            class: parent.className || '(sin clase)',
            display: parentComputed.display,
            visibility: parentComputed.visibility,
            opacity: parentComputed.opacity,
            height: parentComputed.height,
            minHeight: parentComputed.minHeight,
            overflow: parentComputed.overflow,
            position: parentComputed.position,
            zIndex: parentComputed.zIndex,
            offsetHeight: parent.offsetHeight,
            offsetParent: parent.offsetParent !== null
        };
        
        parentChain.push(parentInfo);
        
        // Verificar si está oculto
        const isHidden = parentComputed.display === 'none' || 
                        parentComputed.visibility === 'hidden' || 
                        parentComputed.opacity === '0' ||
                        parent.offsetHeight === 0;
        
        if (isHidden) {
            console.error(`    ❌ Nivel ${level}: ${parent.tagName} ${parent.id || parent.className || ''} - OCULTO`);
            console.error(`       Display: ${parentComputed.display}, Visibility: ${parentComputed.visibility}, Opacity: ${parentComputed.opacity}, Height: ${parent.offsetHeight}px`);
        } else {
            console.log(`    ✅ Nivel ${level}: ${parent.tagName} ${parent.id || parent.className || ''} - VISIBLE`);
        }
        
        parent = parent.parentElement;
        level++;
    }
    
    console.log(`\n  📊 Resumen de cadena de padres:`, parentChain);
});

// 2. Verificar contenedores principales
console.log(`\n\n🏗️ Verificando contenedores principales:`);

const dashboardContent = document.querySelector('.dashboard-content');
if (dashboardContent) {
    const dcComputed = window.getComputedStyle(dashboardContent);
    console.log(`✅ .dashboard-content encontrado`);
    console.log(`  - Display: ${dcComputed.display}`);
    console.log(`  - Visibility: ${dcComputed.visibility}`);
    console.log(`  - Opacity: ${dcComputed.opacity}`);
    console.log(`  - Height: ${dcComputed.height}`);
    console.log(`  - OffsetHeight: ${dashboardContent.offsetHeight}px`);
    console.log(`  - Clase 'authenticated': ${dashboardContent.classList.contains('authenticated')}`);
    console.log(`  - ¿Visible? (offsetParent !== null): ${dashboardContent.offsetParent !== null}`);
} else {
    console.error(`❌ .dashboard-content NO ENCONTRADO`);
}

const mainContent = document.querySelector('.main-content');
if (mainContent) {
    const mcComputed = window.getComputedStyle(mainContent);
    console.log(`✅ .main-content encontrado`);
    console.log(`  - Display: ${mcComputed.display}`);
    console.log(`  - Visibility: ${mcComputed.visibility}`);
    console.log(`  - Opacity: ${mcComputed.opacity}`);
    console.log(`  - Height: ${mcComputed.height}`);
    console.log(`  - OffsetHeight: ${mainContent.offsetHeight}px`);
    console.log(`  - ¿Visible? (offsetParent !== null): ${mainContent.offsetParent !== null}`);
} else {
    console.error(`❌ .main-content NO ENCONTRADO`);
}

// 3. Verificar body
console.log(`\n\n👤 Verificando body:`);
const bodyComputed = window.getComputedStyle(document.body);
console.log(`  - Display: ${bodyComputed.display}`);
console.log(`  - Visibility: ${bodyComputed.visibility}`);
console.log(`  - Opacity: ${bodyComputed.opacity}`);
console.log(`  - Clase 'authenticated': ${document.body.classList.contains('authenticated')}`);

// 4. Intentar forzar visibilidad
console.log(`\n\n🔧 Intentando forzar visibilidad de secciones...`);

sectionsToCheck.forEach(sectionName => {
    const section = document.getElementById(`${sectionName}-section`);
    if (!section) return;
    
    console.log(`\n  Forzando ${sectionName}-section:`);
    
    // Forzar contenedores principales
    if (dashboardContent) {
        dashboardContent.style.setProperty('display', 'flex', 'important');
        dashboardContent.style.setProperty('visibility', 'visible', 'important');
        dashboardContent.style.setProperty('opacity', '1', 'important');
        dashboardContent.classList.add('authenticated');
        console.log(`    ✅ .dashboard-content forzado`);
    }
    
    if (mainContent) {
        mainContent.style.setProperty('display', 'flex', 'important');
        mainContent.style.setProperty('visibility', 'visible', 'important');
        mainContent.style.setProperty('opacity', '1', 'important');
        console.log(`    ✅ .main-content forzado`);
    }
    
    // Forzar body
    document.body.classList.add('authenticated');
    
    // Forzar contenedores padres de la sección
    let parent = section.parentElement;
    let level = 0;
    while (parent && level < 10) {
        const parentComputed = window.getComputedStyle(parent);
        if (parentComputed.display === 'none' || parentComputed.visibility === 'hidden') {
            if (parent.classList.contains('main-content')) {
                parent.style.setProperty('display', 'flex', 'important');
            } else if (parent.classList.contains('dashboard-content')) {
                parent.style.setProperty('display', 'flex', 'important');
            } else {
                parent.style.setProperty('display', 'block', 'important');
            }
            parent.style.setProperty('visibility', 'visible', 'important');
            parent.style.setProperty('opacity', '1', 'important');
            console.log(`    ✅ Contenedor padre nivel ${level} forzado: ${parent.tagName}`);
        }
        parent = parent.parentElement;
        level++;
    }
    
    // Forzar la sección
    section.removeAttribute('style');
    section.style.setProperty('display', 'block', 'important');
    section.style.setProperty('visibility', 'visible', 'important');
    section.style.setProperty('opacity', '1', 'important');
    section.style.setProperty('position', 'relative', 'important');
    section.style.setProperty('z-index', '1', 'important');
    section.style.setProperty('min-height', '100px', 'important');
    
    // Verificar después de forzar
    setTimeout(() => {
        const finalComputed = window.getComputedStyle(section);
        const finalHeight = section.offsetHeight;
        console.log(`\n  📊 Estado después de forzar ${sectionName}-section:`);
        console.log(`    - Display: ${finalComputed.display}`);
        console.log(`    - Visibility: ${finalComputed.visibility}`);
        console.log(`    - Opacity: ${finalComputed.opacity}`);
        console.log(`    - OffsetHeight: ${finalHeight}px`);
        console.log(`    - ¿Visible? (offsetParent !== null): ${section.offsetParent !== null}`);
        
        if (finalComputed.display === 'none' || finalHeight === 0) {
            console.error(`    ❌ ${sectionName}-section SIGUE OCULTA después de forzar!`);
        } else {
            console.log(`    ✅ ${sectionName}-section DEBERÍA SER VISIBLE ahora`);
        }
    }, 200);
});

console.log(`\n\n✅ ===== DIAGNÓSTICO COMPLETADO =====`);
console.log(`\n💡 Si las secciones siguen ocultas después de este script,`);
console.log(`   comparte los resultados completos de la consola.`);
```

## 🚀 Script Rápido (Versión Corta)

Si el script completo es muy largo, usa esta versión corta:

```javascript
// Verificación rápida
const quotes = document.getElementById('quotes-section');
const expenses = document.getElementById('expenses-section');

console.log('QUOTES:', {
    existe: !!quotes,
    display: quotes ? window.getComputedStyle(quotes).display : 'N/A',
    height: quotes ? quotes.offsetHeight : 'N/A',
    visible: quotes ? quotes.offsetParent !== null : 'N/A'
});

console.log('EXPENSES:', {
    existe: !!expenses,
    display: expenses ? window.getComputedStyle(expenses).display : 'N/A',
    height: expenses ? expenses.offsetHeight : 'N/A',
    visible: expenses ? expenses.offsetParent !== null : 'N/A'
});

// Forzar visibilidad
if (quotes) {
    quotes.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important;';
    document.querySelector('.dashboard-content').style.cssText = 'display: flex !important;';
    document.querySelector('.main-content').style.cssText = 'display: flex !important;';
    document.body.classList.add('authenticated');
}
if (expenses) {
    expenses.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important;';
}
```

## 📝 Qué Hacer Después

1. **Ejecuta el script completo** y copia todos los resultados de la consola
2. **Comparte los resultados** para que pueda identificar la causa exacta
3. **Prueba el script rápido** si quieres una solución inmediata (puede hacer que las secciones aparezcan temporalmente)
