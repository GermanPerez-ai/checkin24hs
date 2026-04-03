# 🔐 Restablecer Contraseña del Dashboard

## 📋 Credenciales por Defecto

El dashboard tiene estos usuarios por defecto:

1. **Usuario:** `admin` / **Contraseña:** `admin123`
2. **Usuario:** `German` / **Contraseña:** `123456`
3. **Usuario:** `Axel` / **Contraseña:** `123456`

---

## 🔧 Solución 1: Limpiar localStorage (Restablecer a Usuarios por Defecto)

Si olvidaste tu contraseña, puedes restablecer a los usuarios por defecto:

### Desde el navegador:

1. **Abre el dashboard**: `https://dashboard.checkin24hs.com`
2. **Abre la consola del navegador** (F12 o clic derecho → Inspeccionar → Consola)
3. **Ejecuta este comando**:
   ```javascript
   localStorage.removeItem('dashboard_admin_users');
   location.reload();
   ```
4. **Recarga la página** y usa las credenciales por defecto:
   - Usuario: `admin` / Contraseña: `admin123`

---

## 🔧 Solución 2: Restablecer Contraseña de un Usuario Específico

Si quieres cambiar solo la contraseña de un usuario sin eliminar todos:

1. **Abre la consola del navegador** (F12)
2. **Ejecuta este código** (cambia `'admin'` y `'nuevapassword123'` por los valores que quieras):
   ```javascript
   // Restablecer contraseña del usuario 'admin'
   const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
   const user = users.find(u => u.username === 'admin');
   if (user) {
       user.password = 'nuevapassword123';
       user.password_hash = 'nuevapassword123';
       localStorage.setItem('dashboard_admin_users', JSON.stringify(users));
       console.log('✅ Contraseña restablecida para:', user.username);
       alert('✅ Contraseña restablecida. Recarga la página.');
       location.reload();
   } else {
       alert('❌ Usuario no encontrado');
   }
   ```

---

## 🔧 Solución 3: Ver Todos los Usuarios Actuales

Para ver qué usuarios tienes guardados:

1. **Abre la consola del navegador** (F12)
2. **Ejecuta**:
   ```javascript
   const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
   console.table(users.map(u => ({
       Usuario: u.username,
       Nombre: u.name,
       Email: u.email,
       Estado: u.status
   })));
   ```

**⚠️ Nota:** Las contraseñas no se muestran por seguridad, pero puedes restablecerlas con la Solución 2.

---

## 🔧 Solución 4: Crear un Nuevo Usuario Administrador

Si quieres agregar un nuevo usuario:

1. **Abre la consola del navegador** (F12)
2. **Ejecuta** (cambia los valores según necesites):
   ```javascript
   const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
   const newUser = {
       id: 'admin-' + Date.now(),
       username: 'nuevousuario',
       password: 'micontraseña123',
       password_hash: 'micontraseña123',
       name: 'Nombre Completo',
       role: 'admin_total',
       email: 'email@ejemplo.com',
       createdAt: new Date().toISOString(),
       status: 'active',
       lastLogin: null
   };
   users.push(newUser);
   localStorage.setItem('dashboard_admin_users', JSON.stringify(users));
   console.log('✅ Usuario creado:', newUser.username);
   alert('✅ Usuario creado. Recarga la página.');
   location.reload();
   ```

---

## 🚀 Solución Rápida (Recomendada)

**La forma más rápida de solucionarlo ahora:**

1. Ve a `https://dashboard.checkin24hs.com`
2. Presiona **F12** (o clic derecho → Inspeccionar → Consola)
3. Pega y ejecuta:
   ```javascript
   localStorage.removeItem('dashboard_admin_users'); location.reload();
   ```
4. Inicia sesión con: **Usuario:** `admin` / **Contraseña:** `admin123`

---

## 📝 Cambiar Contraseña desde el Dashboard (Una vez dentro)

Una vez que hayas iniciado sesión:

1. Ve a la sección de **"Administradores"** o **"Usuarios"** en el dashboard
2. Busca tu usuario
3. Haz clic en **"Editar"**
4. Cambia la contraseña
5. Guarda los cambios

---

**¿Necesitas ayuda con algún paso? Indica qué solución quieres usar.**
