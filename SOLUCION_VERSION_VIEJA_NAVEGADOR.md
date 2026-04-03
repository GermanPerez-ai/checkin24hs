# 🔄 Solución: Dashboard Muestra Versión Vieja en el Navegador

## 📋 Diagnóstico

- ✅ **Contenedor tiene la versión nueva**: `BUILD_TIMESTAMP = '2026-01-12T22:06:40Z'`
- ❌ **Navegador muestra versión vieja**: Caché del navegador muy agresiva

## 🔧 Soluciones (en orden de efectividad)

### Opción 1: Hard Refresh (Más Rápida)

1. **Abre el dashboard** en tu navegador
2. **Presiona**:
   - **Windows/Linux**: `Ctrl + Shift + R` o `Ctrl + F5`
   - **Mac**: `Cmd + Shift + R`
3. **Espera** 2-3 segundos

### Opción 2: Limpiar Caché desde DevTools

1. **Abre las herramientas de desarrollador**: `F12`
2. **Haz clic derecho** en el botón de recargar (🔄)
3. **Selecciona**: "Vaciar caché y volver a cargar de forma forzada"
   - En Chrome: "Empty Cache and Hard Reload"
   - En Firefox: "Vaciar caché y recargar de forma forzada"

### Opción 3: Limpiar Todo el Almacenamiento (Más Agresiva)

1. **Abre la consola** (`F12` → Pestaña "Console")
2. **Ejecuta estos comandos**:

```javascript
// Limpiar TODO
localStorage.clear();
sessionStorage.clear();

// Limpiar IndexedDB
if ('indexedDB' in window) {
    indexedDB.databases().then(dbs => {
        dbs.forEach(db => indexedDB.deleteDatabase(db.name));
    });
}

// Desregistrar Service Workers
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(regs => {
        regs.forEach(r => r.unregister());
    });
}

// Recargar con parámetros únicos
const unique = Date.now();
window.location.href = window.location.pathname + '?v=2.1.0&t=' + unique + '&b=' + encodeURIComponent('2026-01-12T22:06:40Z') + '&force=' + unique + '&nocache=1';
```

### Opción 4: Modo Incógnito (Para Verificar)

1. **Abre una ventana de incógnito**:
   - **Chrome**: `Ctrl + Shift + N` (Windows) o `Cmd + Shift + N` (Mac)
   - **Firefox**: `Ctrl + Shift + P` (Windows) o `Cmd + Shift + P` (Mac)
2. **Abre el dashboard** en modo incógnito
3. **Verifica** si muestra la versión nueva

Si funciona en incógnito, confirma que es un problema de caché del navegador.

### Opción 5: Agregar Headers Anti-Caché en Traefik

Si ninguna de las opciones anteriores funciona, aplica headers anti-caché en Traefik:

```bash
# Ejecutar en el servidor
cd ~
curl -O https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/ACTUALIZAR_TRAEFIK_MANUAL.sh
chmod +x ACTUALIZAR_TRAEFIK_MANUAL.sh
./ACTUALIZAR_TRAEFIK_MANUAL.sh
```

Este script ahora incluye headers anti-caché en Traefik.

## ✅ Verificación

Después de aplicar cualquier solución, verifica en la consola del navegador (`F12`):

```javascript
// Debería mostrar:
window.DASHBOARD_VERSION  // '2.1.0'
window.BUILD_TIMESTAMP    // '2026-01-12T22:06:40Z'
```

O busca en los logs de la consola:
```
🏨 CHECKIN24HS DASHBOARD
Versión: 2.1.0 (2025-01-27)
Build: 2026-01-12T22:06:40Z
```

## 🔍 Si Nada Funciona

1. **Cierra completamente el navegador** (no solo la pestaña)
2. **Reinicia el navegador**
3. **Abre el dashboard de nuevo**
4. **Haz Hard Refresh** (`Ctrl + Shift + R`)

Si después de esto sigue mostrando la versión vieja, puede ser que:
- Traefik esté cacheando (aplica la Opción 5)
- Hay un proxy/CDN intermedio cacheando (necesitas limpiarlo desde ese servicio)
