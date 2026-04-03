# 🔄 Restaurar Configuración de Ayer

## ✅ Configuración Correcta (Como Estaba Ayer)

Veo que la "Ruta de compilación" está en `/deploy`. Si así estaba ayer y funcionaba, debemos restaurarla.

## 🔧 Pasos para Restaurar

### Paso 1: Verificar que la Ruta Esté Correcta

En la página de "Fuente" que estás viendo:
1. **Verifica** que la "Ruta de compilación" diga `/deploy`
2. Si dice otra cosa (como `/checkin24hs-admin`), **cámbiala a `/deploy`**
3. **Haz clic en "Guardar"** (botón verde abajo)

### Paso 2: Reconstruir el Servicio

Después de guardar:
1. **Busca el botón "Implementar"** o **"Deploy"** en la parte superior de la página del servicio
2. **O ve a "Implementaciones"** en el menú lateral
3. **Haz clic en "Implementar"** o **"Nueva Implementación"**
4. **Espera** a que termine la reconstrucción (2-5 minutos)

### Paso 3: Verificar el Dominio

Mientras se reconstruye, verifica el dominio:
1. **Ve a** → **Servicios** → **dashboard** → **Dominios**
2. **Edita el dominio** `dashboard.checkin24hs.com`
3. **Verifica**:
   - **Puerto**: `3000` (puerto interno)
   - **Target Service**: `checkin24hs-dashboard` (con guión)
   - **Protocolo**: `HTTP`
4. **Guarda** si hiciste cambios

### Paso 4: Probar

1. **Espera** a que termine la reconstrucción
2. **Limpia la cache** del navegador (Ctrl+Shift+Delete)
3. **O abre ventana de incógnito** (Ctrl+Shift+N)
4. **Accede** a `https://dashboard.checkin24hs.com`

## 🔍 Verificar que el Código en `/deploy` Esté Correcto

Si después de reconstruir sigue sin funcionar, puede ser que el código en la carpeta `/deploy` en GitHub no tenga la versión correcta del dashboard.

En ese caso, necesitaríamos:
1. Verificar qué hay en `/deploy` en GitHub
2. O mover el código del dashboard a `/deploy`
3. O cambiar la ruta a donde esté el código correcto

---

**Primero cambia la ruta a `/deploy` (si no está), guarda, y haz clic en "Implementar". Luego prueba de nuevo.**

