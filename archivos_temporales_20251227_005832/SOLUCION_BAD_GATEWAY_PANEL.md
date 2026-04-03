# 🔧 Solución: Bad Gateway en panel.checkin24hs.com

## 🚨 Problema
El DNS funciona (puedes acceder al dominio), pero aparece "Bad Gateway" (502).

## ✅ Verificación Rápida

### 1. Verificar que el Dominio Esté Creado en EasyPanel

1. En EasyPanel, ve al servicio `checkin24hs-dashboard`
2. Pestaña **"🔗 Dominios"**
3. Verifica que `panel.checkin24hs.com` esté en la lista
4. Si NO está, créalo:
   - Host: `panel.checkin24hs.com`
   - Protocolo: `HTTP`
   - Puerto: `3000`
   - Rutas: `/`

### 2. Verificar desde SSH

Ejecuta este comando para verificar que el servicio está corriendo:

```bash
docker service ps checkin24hs_checkin24hs-dashboard --no-trunc | head -3
```

Y verificar los logs:

```bash
docker service logs checkin24hs_checkin24hs-dashboard --tail 10
```

### 3. Verificar IP Actual del Servicio

```bash
CONTAINER_ID=$(docker ps | grep checkin24hs_checkin24hs-dashboard | awk '{print $1}' | head -1)
docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "easypanel"}}{{$value.IPAddress}}{{end}}{{end}}'
```

### 4. Probar Conexión desde Traefik

```bash
# Obtener IP actual
CONTAINER_ID=$(docker ps | grep checkin24hs_checkin24hs-dashboard | awk '{print $1}' | head -1)
CURRENT_IP=$(docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "easypanel"}}{{$value.IPAddress}}{{end}}{{end}}')

# Probar conexión
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://$CURRENT_IP:3000 2>&1 | head -10
```

---

## 🎯 Solución Más Común

El problema es que el dominio no está asociado correctamente al servicio. 

**Solución:**
1. **Elimina** el dominio `panel.checkin24hs.com` desde la sección general de Domains
2. **Créalo de nuevo** desde el servicio `checkin24hs-dashboard` → pestaña "🔗 Dominios"
3. Esto asegura que EasyPanel lo asocie automáticamente al servicio correcto

---

## 📝 Verificar Configuración del Dominio

En EasyPanel, al editar el dominio `panel.checkin24hs.com`, verifica:
- **Protocolo**: `HTTP`
- **Puerto**: `3000`
- Que esté asociado al servicio `checkin24hs-dashboard`

