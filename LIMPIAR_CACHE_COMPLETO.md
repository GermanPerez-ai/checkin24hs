# 🧹 Limpiar Caché Completo del Navegador

## 🔧 Pasos para Limpiar Caché

### Opción 1: Limpiar desde Configuración (Recomendado)

1. **Chrome/Edge:**
   - Presiona `Ctrl+Shift+Delete`
   - Selecciona "**Todo el tiempo**" en el rango de tiempo
   - Marca todas las opciones:
     - ✅ Historial de navegación
     - ✅ Imágenes y archivos en caché
     - ✅ Cookies y otros datos de sitios
   - Clic en "**Borrar datos**"

2. **O desde F12 (DevTools):**
   - Abre DevTools (F12)
   - Clic derecho en el botón de **Recargar** (cerca de la barra de direcciones)
   - Selecciona "**Vaciar caché y recargar de forma forzada**"

### Opción 2: Modo Incógnito (Prueba Rápida)

1. Abre ventana incógnita: `Ctrl+Shift+N`
2. Ve a `https://dashboard.checkin24hs.com`
3. Prueba hacer login

## 🔍 Verificar en Consola

Después de limpiar caché, abre la consola (F12) y ejecuta:

```javascript
// 1. Verificar usuarios
console.log('Usuarios:', JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]'));

// 2. Verificar build
console.log('Build:', window.DASHBOARD_BUILD_NUMBER);

// 3. Inicializar usuarios si no existen
const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
if (users.length === 0) {
    const defaultUsers = [
        {id: 'admin-001', username: 'admin', password: 'admin123', password_hash: 'admin123', name: 'Administrador', role: 'admin_total', email: 'admin@checkin24hs.com', createdAt: new Date().toISOString(), status: 'active'},
        {id: 'admin-002', username: 'German', password: '123456', password_hash: '123456', name: 'German Perez', role: 'admin_total', email: 'german@checkin24hs.com', createdAt: new Date().toISOString(), status: 'active'},
        {id: 'admin-003', username: 'Axel', password: '123456', password_hash: '123456', name: 'Axel', role: 'admin_total', email: 'axel@checkin24hs.com', createdAt: new Date().toISOString(), status: 'active'}
    ];
    localStorage.setItem('dashboard_admin_users', JSON.stringify(defaultUsers));
    console.log('✅ Usuarios creados');
    location.reload();
}
```

## ⚠️ Si Sigue Sin Funcionar

El problema probablemente es que **el servidor tiene Build #38** (código antiguo).

**Ejecuta en el servidor SSH:**

```bash
cd /etc/easypanel/projects/checkin24hs/dashboard/code
curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
docker service update --force checkin24hs_dashboard
```
