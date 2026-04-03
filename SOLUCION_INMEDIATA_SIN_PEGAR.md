# 🔧 Solución Inmediata: Crear Usuarios SIN Pegar Código

## Método: Escribir el código manualmente

Como el navegador bloquea pegar código, escribe esto **línea por línea** en la consola:

### Paso 1: Abre la consola
Presiona **F12** → Pestaña **Console**

### Paso 2: Escribe esta línea y presiona Enter:

```javascript
localStorage.setItem('dashboard_admin_users','[{"id":"admin-001","username":"admin","password":"admin123","password_hash":"admin123","name":"Administrador","role":"admin_total","email":"admin@checkin24hs.com","createdAt":"2025-01-27T00:00:00.000Z","status":"active","lastLogin":null},{"id":"admin-002","username":"German","password":"123456","password_hash":"123456","name":"German Perez","role":"admin_total","email":"german@checkin24hs.com","createdAt":"2025-01-27T00:00:00.000Z","status":"active","lastLogin":null},{"id":"admin-003","username":"Axel","password":"123456","password_hash":"123456","name":"Axel","role":"admin_total","email":"axel@checkin24hs.com","createdAt":"2025-01-27T00:00:00.000Z","status":"active","lastLogin":null}]')
```

### Paso 3: Verifica que funcionó:

```javascript
JSON.parse(localStorage.getItem('dashboard_admin_users')).length
```

Debería mostrar `3`

### Paso 4: Recarga la página:

```javascript
location.reload()
```

---

## Alternativa: Usar un bookmarklet

Si prefieres, puedes crear un bookmarklet (enlace guardado en favoritos) que ejecute el código automáticamente al hacer clic.

1. **Crea un nuevo marcador/favorito** en tu navegador
2. **Como URL, pega esto**:

```javascript
javascript:(function(){localStorage.setItem('dashboard_admin_users','[{"id":"admin-001","username":"admin","password":"admin123","password_hash":"admin123","name":"Administrador","role":"admin_total","email":"admin@checkin24hs.com","createdAt":"2025-01-27T00:00:00.000Z","status":"active","lastLogin":null},{"id":"admin-002","username":"German","password":"123456","password_hash":"123456","name":"German Perez","role":"admin_total","email":"german@checkin24hs.com","createdAt":"2025-01-27T00:00:00.000Z","status":"active","lastLogin":null},{"id":"admin-003","username":"Axel","password":"123456","password_hash":"123456","name":"Axel","role":"admin_total","email":"axel@checkin24hs.com","createdAt":"2025-01-27T00:00:00.000Z","status":"active","lastLogin":null}]');alert('Usuarios creados. Recarga la página.');location.reload();})();
```

3. **Guarda el marcador** como "Crear Usuarios Dashboard"
4. **Abre el dashboard** y haz clic en el marcador
5. **Recarga la página** si es necesario

---

**Después de crear los usuarios, intenta iniciar sesión con:**
- Usuario: `admin`
- Contraseña: `admin123`
