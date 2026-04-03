# 🔧 Solución: 502 - Dominio No Conectado Correctamente

## 🚨 Problema
El dominio `dashboard.checkin24hs.com` muestra 502, pero el servicio funciona con la IP directa.

## ✅ Solución: Recrear el Dominio desde el Servicio

### Paso 1: Eliminar el Dominio Actual

1. En EasyPanel, ve a **Domains** (sección general, no desde el servicio)
2. Busca `dashboard.checkin24hs.com`
3. Haz clic en el icono de **eliminar** (papelera) o en **"Eliminar"**
4. Confirma la eliminación

### Paso 2: Crear el Dominio desde el Servicio

1. En el menú lateral izquierdo, haz clic en el servicio **`checkin24hs-dashboard`**
2. Ve a la pestaña **"🔗 Dominios"**
3. Haz clic en **"+"** o **"Crear dominio"**
4. Configura:
   - **Host**: `dashboard.checkin24hs.com`
   - **Protocolo**: `HTTP`
   - **Puerto**: `3000`
   - **Ruta externa**: `/`
   - **Ruta interna**: `/`
5. Haz clic en **"Crear"** o **"Guardar"**

### Paso 3: Verificar

1. Espera unos segundos (30-60 segundos) para que se propague la configuración
2. Abre `https://dashboard.checkin24hs.com` en tu navegador
3. Deberías ver la aplicación React funcionando

---

## 🔍 Si Aún No Funciona

### Verificar desde SSH:

```bash
# Verificar que el servicio está corriendo
docker service ps checkin24hs_checkin24hs-dashboard --no-trunc | head -3

# Verificar IP actual
CONTAINER_ID=$(docker ps | grep checkin24hs_checkin24hs-dashboard | awk '{print $1}' | head -1)
docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "easypanel"}}{{$value.IPAddress}}{{end}}{{end}}'

# Verificar logs del servicio
docker service logs checkin24hs_checkin24hs-dashboard --tail 10
```

### Verificar Configuración del Dominio en EasyPanel:

1. Ve al dominio `dashboard.checkin24hs.com`
2. Verifica que esté asociado al servicio `checkin24hs-dashboard`
3. Si no está asociado, elimínalo y créalo desde el servicio

---

## 💡 Nota Importante

Al crear el dominio **desde el servicio**, EasyPanel lo asocia automáticamente y configura la ruta interna correctamente. Esto es más confiable que crearlo desde la sección general de Domains.

