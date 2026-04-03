# 🔧 Solucionar Bind Mount de supabase-client.js en EasyPanel

## 🎯 Problema

El bind mount de `supabase-client.js` está configurado en EasyPanel, pero no se está aplicando al servicio de Docker Swarm.

## ✅ Solución Paso a Paso

### Paso 1: Verificar que el Mount Está Configurado

1. Ve a **EasyPanel** → **Servicio `checkin24hs_dashboard`**
2. Busca la sección **"Puntos de montaje"** o **"Mounts"**
3. Verifica que aparezca:
   - `/root/checkin24hs/supabase-client.js` → `/app/supabase-client.js`

### Paso 2: Aplicar los Cambios

**Opción A: Buscar Botón de Deploy/Update**

1. Busca en la interfaz de EasyPanel un botón que diga:
   - **"Deploy"**
   - **"Update"**
   - **"Apply"**
   - **"Aplicar cambios"**
   - **"Guardar y desplegar"**

2. Haz clic en ese botón

**Opción B: Recrear el Mount**

Si no encuentras un botón de deploy, intenta recrear el mount:

1. **Elimina** el mount de `supabase-client.js` (botón "Eliminar")
2. **Guarda** los cambios
3. **Espera** a que EasyPanel actualice el servicio (30-60 segundos)
4. **Vuelve a agregar** el mount de `supabase-client.js`:
   - Source: `/root/checkin24hs/supabase-client.js`
   - Destination: `/app/supabase-client.js`
   - Read Only: Desactivado
5. **Guarda** los cambios nuevamente
6. **Espera** a que EasyPanel actualice el servicio

**Opción C: Guardar Configuración Completa**

1. Ve a cualquier sección del servicio (Settings, Environment, etc.)
2. Haz clic en **"Guardar"** o **"Save"** (aunque no hayas cambiado nada)
3. Esto puede forzar a EasyPanel a aplicar todos los cambios pendientes

### Paso 3: Verificar que Funcionó

Después de aplicar los cambios, espera 30-60 segundos y ejecuta:

```bash
# Verificar que el mount está en el servicio
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}{{.Type}}|{{.Source}}|{{.Destination}}{{"\n"}}{{end}}' | grep supabase

# Verificar que el contenedor tiene el mount
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
docker inspect "$CONTAINER" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}{{end}}' | grep supabase

# Verificar corrección
docker exec "$CONTAINER" grep -q "SIEMPRE devolver las cotizaciones obtenidas de Supabase" /app/supabase-client.js && echo "✅ OK" || echo "❌ NO OK"
```

## 🔍 Si Nada Funciona

Si después de intentar todas las opciones el mount sigue sin aplicarse:

1. **Verifica los logs de EasyPanel** para ver si hay errores
2. **Reinicia el servicio manualmente** desde SSH:
   ```bash
   docker service update --force checkin24hs_dashboard
   ```
   (Esto no aplicará el mount, pero puede ayudar a que EasyPanel detecte cambios pendientes)

3. **Contacta al soporte de EasyPanel** - puede ser un bug en su sistema

## 📋 Nota Importante

Los otros dos mounts (`dashboard.html` y `server.js`) están funcionando correctamente, lo que significa que:
- ✅ El sistema de mounts funciona
- ✅ El archivo en el servidor existe y tiene permisos correctos
- ❌ EasyPanel simplemente no está aplicando el nuevo mount al servicio

La solución está en hacer que EasyPanel aplique los cambios correctamente.
