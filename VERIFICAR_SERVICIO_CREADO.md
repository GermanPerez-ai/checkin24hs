# ✅ Verificar Servicio Creado y Configurar Dominio

## 🎯 Pasos Siguientes

### Paso 1: Verificar que el Servicio se Creó

1. En el menú lateral izquierdo, en la sección "SERVICIOS", deberías ver tu nuevo servicio
2. Haz clic en el nuevo servicio (probablemente `dashboard-new` o `dashboard2`)
3. Verifica que esté corriendo (debe tener un punto verde)

### Paso 2: Verificar la Configuración

1. Ve a la pestaña **"Fuente"** y verifica:
   - Build Path: `/deploy`
   - Dockerfile Path: `Dockerfile`

2. Ve a la pestaña **"Puertos"** y verifica:
   - Puerto interno: `80`

3. Ve a la pestaña **"Entorno"** y verifica:
   - `PORT=80`

### Paso 3: Agregar el Dominio

1. Ve a la pestaña **"Dominios"** (en el menú lateral izquierdo)
2. Haz clic en **"Agregar dominio"** (botón en la parte inferior)
3. Ingresa: `dashboard.checkin24hs.com`
4. **IMPORTANTE**: Verifica qué destino genera EasyPanel automáticamente
   - Debería ser: `http://dashboard-new:80/` o `http://dashboard2:80/` (dependiendo del nombre que usaste)
   - Si genera `http://checkin24hs_dashboard-new:80/` (con guión bajo), ese es el problema

### Paso 4: Probar

1. Espera 30-60 segundos después de agregar el dominio
2. Abre tu navegador
3. Ve a: `https://dashboard.checkin24hs.com/`
4. **¿Funciona?** Si funciona, ¡perfecto! Si no, comparte qué error ves

---

## 🔍 Si el Dominio Genera un Destino con Guión Bajo

Si EasyPanel genera `http://checkin24hs_dashboard-new:80/` (con guión bajo), necesitamos verificar si el alias existe en Docker.

En el servidor, ejecuta:
```bash
docker service inspect checkin24hs_dashboard-new --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

O si el servicio se llama diferente, reemplaza `checkin24hs_dashboard-new` con el nombre real.

---

**¿Qué nombre le diste al nuevo servicio? ¿Ya agregaste el dominio? ¿Qué destino genera EasyPanel automáticamente?**
