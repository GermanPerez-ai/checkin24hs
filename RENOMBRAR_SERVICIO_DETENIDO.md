# 🔧 Renombrar Servicio: Detener Primero

## 🎯 Pasos para Renombrar el Servicio

### Paso 1: Detener el Servicio

1. En EasyPanel, ve al servicio `dashboard`
2. Haz clic en el icono de **"Detener"** (cuadrado) en la barra de acciones
3. Espera a que el servicio se detenga completamente (puede tardar 30-60 segundos)
4. Verifica que el estado muestre "Detenido" o similar

### Paso 2: Renombrar el Servicio

1. Con el servicio detenido, haz clic en el **lápiz** (editar) al lado del nombre
2. Cambia el nombre a: `dashboard-old` o `dashboard-main`
3. Haz clic en **"Guardar"**
4. El servicio ahora se llamará `dashboard-old` o `dashboard-main`

### Paso 3: Crear Nuevo Servicio "dashboard"

1. Crea un **nuevo servicio** llamado `dashboard` (ahora que el anterior tiene otro nombre)
2. Configura:
   - Build Path: `/deploy`
   - Dockerfile: `Dockerfile`
   - Puerto: `80`
   - Variables de entorno: `PORT=80`
3. Haz clic en **"Implementar"** para construir e iniciar el servicio
4. Espera a que se construya e inicie completamente

### Paso 4: Agregar el Dominio

1. Ve a la pestaña **"Dominios"** del nuevo servicio `dashboard`
2. Agrega el dominio: `dashboard.checkin24hs.com`
3. EasyPanel debería generar: `http://dashboard:80/` (coincide con el alias `dashboard`)

### Paso 5: Probar

1. Espera 30-60 segundos
2. Prueba acceder a: `https://dashboard.checkin24hs.com/`

### Paso 6: Limpiar (Opcional)

Si el nuevo servicio funciona:
1. Elimina el servicio anterior (`dashboard-old` o `dashboard-main`)
2. O déjalo detenido por si necesitas volver atrás

---

## ⚠️ Nota

El servicio estará temporalmente no disponible mientras lo renombras y creas el nuevo. Esto es normal y necesario.

---

**Detén el servicio, renómbralo, y luego crea uno nuevo llamado `dashboard`.**
