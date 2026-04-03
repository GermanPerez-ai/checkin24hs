# 🔧 Solución: Recrear el Servicio con Nombre Correcto

## 🎯 Problema

- No puedes crear un servicio llamado "dashboard" porque ya existe
- EasyPanel genera `http://checkin24hs_dashboard:80/` (guión bajo)
- El alias real es `checkin24hs-dashboard` (guión)
- No coinciden → 404

## ✅ Solución: Recrear el Servicio

### Opción 1: Eliminar y Recrear el Servicio Actual

**⚠️ ADVERTENCIA: Esto eliminará temporalmente el servicio.**

1. En EasyPanel, ve al servicio `dashboard`
2. **Elimina** el servicio (icono de basura)
3. Espera a que se elimine completamente
4. Crea un **nuevo servicio** llamado `dashboard` (sin prefijo)
5. Configura:
   - Build Path: `/deploy`
   - Dockerfile: `Dockerfile`
   - Puerto: `80`
   - Variables de entorno: `PORT=80`
6. Agrega el dominio `dashboard.checkin24hs.com`
7. EasyPanel debería generar: `http://dashboard:80/` (coincide con el alias)

### Opción 2: Renombrar el Servicio Actual

1. En EasyPanel, ve al servicio `dashboard`
2. Haz clic en el **lápiz** (editar) al lado del nombre
3. Intenta renombrarlo a algo como `dashboard-app` o `dash`
4. Guarda los cambios
5. Verifica si el destino cambia automáticamente

### Opción 3: Cambiar el Nombre del Proyecto

Si EasyPanel usa `proyecto_servicio`:

1. Busca una opción para cambiar el nombre del proyecto `checkin24hs`
2. Cámbialo a algo que genere un alias correcto
3. O crea un nuevo proyecto y mueve el servicio allí

### Opción 4: Usar un Nombre Diferente para el Servicio

1. Renombra el servicio actual a `dashboard-main` o `dash-app`
2. Crea un nuevo servicio llamado `dashboard` (ahora que el anterior tiene otro nombre)
3. Configura el nuevo servicio igual que el anterior
4. Agrega el dominio al nuevo servicio

---

## 🎯 Recomendación

**Intenta primero la Opción 2**: Renombrar el servicio actual a algo diferente (como `dashboard-main`), luego crea un nuevo servicio llamado `dashboard`.

**¿Puedes renombrar el servicio actual a `dashboard-main` y luego crear uno nuevo llamado `dashboard`?**
