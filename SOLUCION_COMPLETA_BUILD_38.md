# 🔧 Solución Completa: Build #38 y Login Fallando

## 🔴 Problema Detectado

- **Build #38** en servidor (debe ser #39)
- 4 usuarios en localStorage pero login falla
- El código del servidor es antiguo y puede tener lógica diferente

## ✅ Solución (2 Pasos)

### Paso 1: Verificar/Corregir Usuarios en Navegador

Ejecuta en la consola (F12):

```javascript
// Ver usuarios actuales
const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
console.log('Usuarios:', users);

// Si faltan password o password_hash, corregirlos
users.forEach(u => {
    if (u.password && !u.password_hash) u.password_hash = u.password;
    if (!u.password && u.password_hash) u.password = u.password_hash;
    if (!u.status) u.status = 'active';
});
localStorage.setItem('dashboard_admin_users', JSON.stringify(users));
console.log('✅ Usuarios corregidos');
location.reload();
```

### Paso 2: Actualizar Servidor a Build #39 (CRÍTICO)

**El servidor tiene código antiguo. Ejecuta en SSH:**

```bash
cd /etc/easypanel/projects/checkin24hs/dashboard/code
curl -L -o dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
docker service update --force checkin24hs_dashboard
```

Espera 10 segundos, luego:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls=true" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  checkin24hs_dashboard
```

### Paso 3: Verificar

1. Limpia caché: `Ctrl+Shift+Delete` → Todo el tiempo
2. Recarga: `Ctrl+Shift+R`
3. Verifica Build: En consola, `window.DASHBOARD_BUILD_NUMBER` debe ser `39`
4. Prueba login con:
   - Usuario: `German`
   - Contraseña: `123456`

## 🎯 Por Qué Fallaba

- Build #38 tiene código antiguo de autenticación
- Puede tener lógica diferente para comparar contraseñas
- Build #39 tiene la lógica corregida

## ✅ Después de Actualizar

- Build #39 debería funcionar correctamente
- Login debería aceptar las credenciales
- Menú Administradores debería ser visible
