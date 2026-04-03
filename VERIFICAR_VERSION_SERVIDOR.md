# 🔍 Verificar Versión del Archivo en el Servidor

## 🎯 Problema

El último commit en GitHub es del 28/12 y la última implementación en EasyPanel es de hace 12 días. Necesitas verificar si el archivo `deploy/dashboard.html` está actualizado en el servidor.

## ✅ Solución: Script de Verificación

Ejecuta este script en la consola del navegador (F12) para verificar:

```javascript
// Script de verificación de versión
(function() {
    console.log('🔍 Verificando versión del archivo en el servidor...');
    
    // 1. Verificar si el script de emergencia está presente
    const scripts = Array.from(document.querySelectorAll('script'));
    let scriptEmergenciaEncontrado = false;
    let scriptObservadorEncontrado = false;
    
    scripts.forEach(function(script) {
        const content = script.textContent || script.innerHTML || '';
        if (content.includes('SCRIPT EMERGENCIA') || content.includes('forceFlorTabs')) {
            scriptEmergenciaEncontrado = true;
            console.log('✅ Script de emergencia encontrado');
        }
        if (content.includes('OBSERVADOR FINAL') || content.includes('forceQuotesAndExpenses')) {
            scriptObservadorEncontrado = true;
            console.log('✅ Script observador final encontrado');
        }
    });
    
    if (!scriptEmergenciaEncontrado) {
        console.error('❌ Script de emergencia NO encontrado');
    }
    if (!scriptObservadorEncontrado) {
        console.error('❌ Script observador final NO encontrado');
    }
    
    // 2. Verificar fecha del archivo (si está disponible)
    fetch(window.location.href, { method: 'HEAD' })
        .then(response => {
            const lastModified = response.headers.get('last-modified');
            if (lastModified) {
                console.log('📅 Última modificación del archivo:', lastModified);
                const fileDate = new Date(lastModified);
                const now = new Date();
                const daysDiff = Math.floor((now - fileDate) / (1000 * 60 * 60 * 24));
                console.log(`⏰ Archivo modificado hace ${daysDiff} días`);
                
                if (daysDiff > 1) {
                    console.warn('⚠️ El archivo parece estar desactualizado (más de 1 día)');
                }
            }
        })
        .catch(e => console.warn('⚠️ No se pudo obtener fecha del archivo:', e));
    
    // 3. Verificar si las funciones están disponibles
    console.log('🔍 Verificando funciones disponibles...');
    console.log('  - forceFlorTabs:', typeof window.forceFlorTabs !== 'undefined' ? '✅' : '❌');
    console.log('  - forceQuotesAndExpenses:', typeof window.forceQuotesAndExpenses !== 'undefined' ? '✅' : '❌');
    console.log('  - forceAll:', typeof window.forceAll !== 'undefined' ? '✅' : '❌');
    
    // 4. Verificar elementos del DOM
    const quotes = document.getElementById('quotes-section');
    const expenses = document.getElementById('expenses-section');
    const knowledgeTab = document.getElementById('flor-tab-knowledge');
    const whatsappTab = document.getElementById('flor-tab-whatsapp');
    
    console.log('🔍 Verificando elementos del DOM...');
    console.log('  - quotes-section:', quotes ? '✅' : '❌');
    console.log('  - expenses-section:', expenses ? '✅' : '❌');
    console.log('  - flor-tab-knowledge:', knowledgeTab ? '✅' : '❌');
    console.log('  - flor-tab-whatsapp:', whatsappTab ? '✅' : '❌');
    
    // 5. Verificar estado actual de visibilidad
    if (quotes) {
        console.log('  - quotes-section display:', window.getComputedStyle(quotes).display);
        console.log('  - quotes-section height:', quotes.offsetHeight);
    }
    if (expenses) {
        console.log('  - expenses-section display:', window.getComputedStyle(expenses).display);
        console.log('  - expenses-section height:', expenses.offsetHeight);
    }
    if (knowledgeTab) {
        console.log('  - flor-tab-knowledge display:', window.getComputedStyle(knowledgeTab).display);
        console.log('  - flor-tab-knowledge active:', knowledgeTab.classList.contains('active'));
    }
    if (whatsappTab) {
        console.log('  - flor-tab-whatsapp display:', window.getComputedStyle(whatsappTab).display);
        console.log('  - flor-tab-whatsapp active:', whatsappTab.classList.contains('active'));
    }
    
    console.log('✅ Verificación completada');
})();
```

## 🚀 Pasos para Actualizar en EasyPanel

Si el archivo está desactualizado, sigue estos pasos:

### 1. Verificar GitHub
```bash
# Verificar último commit
git log -1 --format="%H %ai %s" deploy/dashboard.html
```

### 2. Forzar Actualización en EasyPanel

1. **Ir a EasyPanel**: https://easypanel.host
2. **Proyecto**: `checkin24hs`
3. **Servicio**: `dashboard`
4. **Source**:
   - Verificar que la rama sea `main`
   - Verificar que el repositorio sea correcto
5. **Forzar Redeploy**:
   - Click en **"Redeploy"** o **"Deploy"**
   - Esperar a que termine la construcción

### 3. Limpiar Caché del Navegador

Después del deploy:

1. **Hard Refresh**: `Ctrl + Shift + R` (Windows) o `Cmd + Shift + R` (Mac)
2. **O limpiar caché completamente**:
   - `Ctrl + Shift + Delete`
   - Seleccionar "Todo el tiempo"
   - Marcar "Imágenes y archivos en caché"
   - Click en "Borrar datos"

### 4. Verificar en el Navegador

Después de limpiar caché, ejecuta el script de verificación de nuevo y deberías ver:
- ✅ Script de emergencia encontrado
- ✅ Script observador final encontrado
- ✅ Mensajes de logs en la consola

## 🔧 Solución Temporal

Si el archivo no se actualiza inmediatamente, puedes ejecutar el script manualmente en la consola:

```javascript
// Script manual (igual al que funciona)
function forceFlorTabs() {
    const knowledgeTab = document.getElementById('flor-tab-knowledge');
    const whatsappTab = document.getElementById('flor-tab-whatsapp');
    
    [knowledgeTab, whatsappTab].forEach(function(tab) {
        if (!tab) return;
        if (tab.classList.contains('active')) {
            tab.removeAttribute('style');
            tab.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; min-height: 300px !important; height: auto !important; position: relative !important; z-index: 1 !important;';
            tab.classList.add('active');
        }
    });
}

function forceQuotesAndExpenses() {
    const quotes = document.getElementById('quotes-section');
    const expenses = document.getElementById('expenses-section');
    
    [quotes, expenses].forEach(function(section) {
        if (!section) return;
        if (section.id !== 'quotes-section' && section.id !== 'expenses-section') return;
        
        const computedDisplay = window.getComputedStyle(section).display;
        const offsetHeight = section.offsetHeight;
        const styleDisplay = section.style.display;
        
        if (computedDisplay === 'none' || styleDisplay === 'none' || offsetHeight === 0 || section.offsetParent === null) {
            section.removeAttribute('style');
            section.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; min-height: 500px !important; height: auto !important; position: relative !important; z-index: 1 !important;';
        }
    });
}

function forceAll() {
    forceQuotesAndExpenses();
    forceFlorTabs();
}

// Ejecutar inmediatamente
forceAll();

// Ejecutar cada 100ms
setInterval(forceAll, 100);

console.log('✅ Script manual activado');
```

## 📋 Resumen

1. **Ejecuta el script de verificación** en la consola para ver qué está pasando
2. **Si el archivo está desactualizado**: Forzar redeploy en EasyPanel
3. **Limpiar caché del navegador**: `Ctrl + Shift + R`
4. **Usar script manual temporalmente** si es necesario

---

**Fecha**: 2025-01-27
**Estado**: Script de verificación creado
