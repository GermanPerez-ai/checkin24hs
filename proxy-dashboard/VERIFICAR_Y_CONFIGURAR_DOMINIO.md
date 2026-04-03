# ✅ Verificar y Configurar Dominio

## 📊 Pasos Finales

### Paso 1: Verificar que el proxy funciona

```bash
# Obtener IP del contenedor del proxy
PROXY_CONTAINER_ID=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.ID}}" | head -1)
PROXY_IP=$(docker inspect $PROXY_CONTAINER_ID | grep -A 10 "easypanel-checkin24hs" | grep "IPv4Address" | head -1 | cut -d'"' -f4 | cut -d'/' -f1)
echo "IP del contenedor del proxy: $PROXY_IP"

# Probar acceso al proxy
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://$PROXY_IP:80/
```

Debería devolver **HTTP/1.1 200 OK**.

### Paso 2: Configurar dominio en EasyPanel

1. Ve a EasyPanel → Servicios → `dashboard`
2. En la sección "Dominios", busca `dashboard.checkin24hs.com`
3. Haz clic en el icono de lápiz (editar)
4. En "Destino", cambia a:
   - Protocolo: HTTP
   - Puerto: `80`
   - Ruta: `/`
5. En "Host" (arriba), cambia a: `$PROXY_IP` (usa la IP obtenida en el Paso 1)
6. Guarda los cambios

### Paso 3: Esperar y probar

1. Espera 30 segundos para que Traefik se actualice
2. Abre tu navegador
3. Ve a: `https://dashboard.checkin24hs.com/`
4. Debería cargar el dashboard correctamente

---

**Ejecuta el Paso 1 para obtener la IP del proxy. Luego configura el dominio en EasyPanel (Paso 2) con esa IP.**
