# 🔧 Solución: Bad Gateway con Dominio Configurado

## 🚨 Problema
El dominio `dashboard.checkin24hs.com` muestra "Bad Gateway" aunque el servicio está corriendo.

## ✅ Pasos de Diagnóstico y Solución

### 1. Verificar que el Dominio Apunta al Servicio Correcto

En EasyPanel:
1. Ve a **Domains** → `dashboard.checkin24hs.com`
2. Edita el dominio
3. Verifica que el campo **"Target Service"** o **"Servicio de destino"** sea `checkin24hs-dashboard`
4. Verifica que el **Puerto** sea `3000`

### 2. Verificar que el Servicio Está en la Red Correcta

El servicio debe estar en la red `easypanel` para que Traefik pueda alcanzarlo.

**Desde SSH:**
```bash
# Ver en qué red está el servicio
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' | xargs -I {} docker network inspect {} --format '{{.Name}}'
```

**Debe mostrar:** `easypanel`

Si no está en esa red, agrégalo desde EasyPanel:
- Ve al servicio `checkin24hs-dashboard`
- Pestaña **Networking** o **Red**
- Asegúrate de que esté en la red `easypanel`

### 3. Verificar Conectividad desde Traefik

**Desde SSH:**
```bash
# Probar conexión desde Traefik al servicio
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -20
```

**Si funciona:** Deberías ver el HTML del dashboard
**Si no funciona:** El problema es de red o alias

### 4. Verificar el Alias del Servicio

**Desde SSH:**
```bash
# Ver los alias del servicio
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' | xargs -I {} docker network inspect {} --format '{{range .Containers}}{{.Name}} {{end}}'
```

El alias debe ser `checkin24hs-dashboard` (con guión, no guión bajo).

### 5. Verificar que el Servicio Está Escuchando Correctamente

**Desde SSH:**
```bash
# Ver logs del servicio
docker service logs checkin24hs_dashboard --tail 20
```

**Debe mostrar:** `🚀 Server running at http://0.0.0.0:3000/`

### 6. Probar Acceso Directo al Puerto Publicado

**Desde SSH:**
```bash
# Ver qué puerto está publicado
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# Probar con el puerto publicado (ej: 30002)
curl http://localhost:30002 | head -20
```

---

## 🎯 Solución Más Común

Si el servicio está corriendo pero Traefik no puede alcanzarlo:

1. **Verifica el campo "Target Service" en el dominio** - Debe ser exactamente `checkin24hs-dashboard`
2. **Verifica que el servicio esté en la red `easypanel`**
3. **Verifica que el puerto en el dominio sea `3000`** (puerto interno del contenedor, no el publicado)

---

## 📝 Si Nada Funciona

1. **Elimina el dominio** `dashboard.checkin24hs.com`
2. **Ve al servicio** `checkin24hs-dashboard`
3. **Crea el dominio desde ahí** (debería detectar automáticamente el servicio)
4. **Configura:**
   - Host: `dashboard.checkin24hs.com`
   - Puerto: `3000`
   - Protocolo: `HTTP`

