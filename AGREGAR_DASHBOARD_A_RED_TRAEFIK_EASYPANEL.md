# 🔧 Guía: Agregar Dashboard a la Red de Traefik en EasyPanel

## 📍 Ubicación Actual

Estás en: **SERVER → General**

## 🎯 Pasos para Configurar el Dashboard

### Paso 1: Ir al Servicio Dashboard

1. **Cierra esta página** (puedes hacer clic en "SERVICIOS" en el menú lateral izquierdo)
2. O busca en el menú lateral:
   - Busca la sección **"SERVICIOS"** o **"SERVICES"**
   - Haz clic en **"dashboard"** o **"checkin24hs_dashboard"**

### Paso 2: Abrir la Configuración del Servicio

Una vez que estés en la página del servicio dashboard:

1. Busca una pestaña o sección que diga:
   - **"Configuration"** o **"Configuración"**
   - **"Settings"** o **"Ajustes"**
   - **"Network"** o **"Red"**
   - **"Networks"** o **"Redes"**

2. O busca un botón de **"Editar"** o **"Edit"** en la parte superior

### Paso 3: Agregar la Red de Traefik

En la configuración del servicio, busca:

1. **Sección "Network" o "Red" o "Networks"**:
   - Debería haber una lista de redes disponibles
   - Busca una red llamada:
     - `traefik`
     - `traefik_web`
     - `traefik_default`
     - O cualquier red que contenga "traefik"

2. **Agrega la red**:
   - Haz clic en el botón **"+"** o **"Agregar"** o **"Add Network"**
   - Selecciona la red de Traefik de la lista
   - O escribe `traefik` en un campo de texto

3. **Guarda los cambios**:
   - Haz clic en **"Guardar"** o **"Save"**
   - O haz clic en **"Deploy"** o **"Implementar"**

### Paso 4: Verificar los Puertos

Mientras estás en la configuración del servicio:

1. Busca la sección **"Ports"** o **"Puertos"**
2. Verifica que esté configurado:
   - **Puerto externo**: `3000`
   - **Puerto interno**: `3000`
   - O simplemente: `3000:3000`

3. Si no está configurado, agrégalo:
   - Haz clic en **"+"** o **"Agregar puerto"**
   - Puerto externo: `3000`
   - Puerto interno: `3000`

4. **Guarda** los cambios

### Paso 5: Verificar la Configuración del Dominio

1. Ve a la sección **"Dominios"** o **"Domains"** en el servicio dashboard
2. O ve a **SERVER → Dominios** en el menú lateral
3. Busca el dominio del dashboard (ej: `dashboard.checkin24hs.com`)
4. Haz clic en el dominio para editarlo
5. Verifica:
   - **Protocolo**: `HTTP`
   - **Puerto**: `3000`
   - **Target Service**: `checkin24hs_dashboard` o `checkin24hs-dashboard`
6. **Guarda** los cambios

### Paso 6: Reiniciar el Servicio

Después de hacer los cambios:

1. En la página del servicio dashboard
2. Busca el botón **"Reiniciar"** o **"Restart"** o **"Deploy"**
3. Haz clic para reiniciar el servicio
4. Espera 10-15 segundos a que el servicio se reinicie

## 🔍 Si No Encuentras la Opción de Red

Si EasyPanel no tiene una opción visible para agregar redes, puedes hacerlo desde SSH:

```bash
# Conectar el servicio a la red de Traefik
docker service update --network-add traefik checkin24hs_dashboard

# O si la red tiene otro nombre, primero verifica:
docker network ls | grep traefik

# Luego usa el nombre correcto:
docker service update --network-add <NOMBRE_DE_LA_RED> checkin24hs_dashboard
```

## ✅ Verificación Final

Después de hacer los cambios, desde SSH ejecuta:

```bash
# Verificar que el servicio esté en la red
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq

# Probar desde Traefik
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs_dashboard:3000 2>&1 | head -20
```

## 📸 Ubicaciones en EasyPanel

**Menú lateral izquierdo:**
- **SERVICIOS** → dashboard → Configuration/Network
- **SERVER** → Dominios → (editar dominio del dashboard)

**En la página del servicio:**
- Pestañas: **Configuration**, **Network**, **Ports**, **Domains**
- Botones: **Edit**, **Save**, **Deploy**, **Restart**

---

**Si no encuentras alguna de estas opciones, comparte una captura de pantalla de la página del servicio dashboard y te guío más específicamente.**

