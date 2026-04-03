# 🔍 Diagnosticar Punto Amarillo del Proxy

## 📊 Problema

- ⚠️ Servicio `dashboard-proxy` tiene punto amarillo
- ❌ Alias `dashboard-proxy` no se resuelve

## 🔍 Diagnóstico

### Paso 1: Ver logs del servicio

```bash
# Ver logs del servicio
docker service logs checkin24hs_dashboard-proxy --tail 50

# Ver estado del servicio
docker service ps checkin24hs_dashboard-proxy --no-trunc
```

### Paso 2: Verificar contenedores

```bash
# Ver contenedores del proxy
docker ps | grep dashboard-proxy

# Ver contenedores detenidos
docker ps -a | grep dashboard-proxy
```

### Paso 3: Verificar configuración en EasyPanel

En EasyPanel, verifica:

1. **Pestaña "Fuente" o "Source"**:
   - Build Path: `/proxy-dashboard`
   - Dockerfile: `Dockerfile`
   - Rama: `main`

2. **Pestaña "Implementar" o "Deploy"**:
   - Puerto interno: `80`
   - Comando: (debe estar vacío)

3. **Pestaña "Entorno" o "Environment"**:
   - No debe haber variables de entorno conflictivas

### Paso 4: Verificar que el contenedor esté funcionando

```bash
# Verificar que nginx esté corriendo
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
docker exec $PROXY_CONTAINER_ID ps aux | grep nginx

# Ver logs del contenedor
docker logs $PROXY_CONTAINER_ID --tail 30
```

### Paso 5: Si hay errores, verificar archivos en GitHub

```bash
# Verificar que los archivos estén en GitHub
curl -s https://api.github.com/repos/GermanPerez-ai/checkin24hs/contents/proxy-dashboard | grep name
```

---

**Ejecuta primero el Paso 1 para ver qué error específico está ocurriendo. Luego verifica la configuración en EasyPanel (Paso 3).**
