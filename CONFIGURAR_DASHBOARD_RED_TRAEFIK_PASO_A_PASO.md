# 🔧 Configurar Dashboard en Red de Traefik - Paso a Paso

## 📍 Situación Actual

Estás en: **dashboard → Redirecciones**

## 🎯 Pasos para Solucionar el Problema

### Paso 1: Cerrar el Modal Actual

1. **Cierra el modal** "Crear redireccionamiento" haciendo clic en la **X** (esquina superior derecha)
2. O haz clic fuera del modal

### Paso 2: Verificar la Configuración de Dominios

1. En el menú lateral izquierdo, haz clic en **"Dominios"** (ya está visible en tu menú)
2. Verifica que el dominio del dashboard esté configurado:
   - **Protocolo**: `HTTP`
   - **Puerto**: `3000` (puerto interno del contenedor)
   - **Target Service**: `checkin24hs_dashboard` o `checkin24hs-dashboard`

### Paso 3: Verificar la Configuración de Red (Desde SSH)

EasyPanel puede no mostrar la opción de red directamente. Vamos a hacerlo desde SSH:

**Desde tu terminal SSH, ejecuta:**

```bash
# 1. Ver las redes disponibles
docker network ls | grep traefik

# 2. Ver la configuración actual del servicio
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq

# 3. Agregar el servicio a la red de Traefik
# (Reemplaza 'traefik' con el nombre real de la red si es diferente)
docker service update --network-add traefik checkin24hs_dashboard

# 4. Verificar que se agregó correctamente
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

### Paso 4: Verificar los Puertos en EasyPanel

1. En el menú lateral, busca una sección que diga:
   - **"Recursos"** (Resources)
   - **"Avanzado"** (Advanced)
   - O vuelve a la página principal del servicio (haz clic en "dashboard" en el menú)

2. Busca la sección **"Ports"** o **"Puertos"**
3. Verifica que esté configurado:
   - Puerto: `3000:3000` (externo:interno)
   - O simplemente: `3000`

### Paso 5: Verificar Variables de Entorno

1. En el menú lateral, haz clic en **"Entorno"** (Environment)
2. Verifica que exista:
   - `PORT=3000` (si es necesario)
   - O cualquier otra variable relacionada con el puerto

### Paso 6: Reiniciar el Servicio

Después de hacer los cambios:

1. En la parte superior de la página del servicio, busca el botón:
   - **"Reiniciar"** o **"Restart"**
   - **"Implementar"** o **"Deploy"**
   - O un botón de **"Actualizar"**

2. Haz clic para reiniciar/actualizar el servicio
3. Espera 10-15 segundos

### Paso 7: Probar la Conexión

Desde SSH, ejecuta:

```bash
# Probar desde Traefik
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs_dashboard:3000 2>&1 | head -20
```

Si funciona, deberías ver el HTML de la aplicación React.

## 🔍 Comandos SSH Completos

Si prefieres hacer todo desde SSH, ejecuta estos comandos en orden:

```bash
# 1. Ver redes de Traefik
echo "=== Redes de Traefik ==="
docker network ls | grep traefik

# 2. Ver configuración actual del servicio
echo "=== Configuración actual del servicio ==="
docker service inspect checkin24hs_dashboard --pretty | grep -A 10 Networks

# 3. Agregar a la red de Traefik (ajusta el nombre si es diferente)
echo "=== Agregando servicio a la red de Traefik ==="
docker service update --network-add traefik checkin24hs_dashboard

# 4. Verificar que se agregó
echo "=== Verificando redes del servicio ==="
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq

# 5. Esperar unos segundos y probar
echo "=== Esperando 5 segundos... ==="
sleep 5

# 6. Probar conexión desde Traefik
echo "=== Probando conexión desde Traefik ==="
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs_dashboard:3000 2>&1 | head -20
```

## ⚠️ Si el Nombre de la Red es Diferente

Si el comando `docker network ls | grep traefik` muestra un nombre diferente (ej: `traefik_web`, `traefik_default`), usa ese nombre en el comando:

```bash
docker service update --network-add <NOMBRE_REAL_DE_LA_RED> checkin24hs_dashboard
```

## ✅ Verificación Final

Después de ejecutar los comandos, deberías poder:

1. ✅ Ver el servicio en la red de Traefik
2. ✅ Conectarte desde Traefik al servicio
3. ✅ Acceder al dashboard desde el dominio configurado

---

**Ejecuta los comandos SSH y comparte el resultado para verificar que todo esté correcto.**

