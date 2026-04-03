#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO Y RECONFIGURANDO WHATSAPP"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Verificar que el servicio existe y está corriendo
echo "1️⃣ Verificando estado del servicio..."
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ Error: El servicio $SERVICE_NAME no existe"
    exit 1
fi

echo "✅ Servicio encontrado"
docker service ls | grep "$SERVICE_NAME"
echo ""

# 2. Verificar logs recientes
echo "2️⃣ Últimos logs del servicio:"
docker service logs "$SERVICE_NAME" --tail 10 --no-trunc
echo ""

# 3. Verificar etiquetas de Traefik
echo "3️⃣ Etiquetas de Traefik actuales:"
TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik")
if [ -z "$TRAEFIK_LABELS" ]; then
    echo "⚠️ No hay etiquetas de Traefik configuradas"
    echo ""
    echo "4️⃣ Configurando Traefik..."
    
    # Remover etiquetas existentes (por si acaso)
    docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}{{"\n"}}{{end}}' | grep "^traefik" | while read label; do
        docker service update --label-rm "$label" "$SERVICE_NAME" 2>/dev/null
    done
    
    sleep 3
    
    # Agregar etiquetas correctas
    docker service update \
      --label-add 'traefik.enable=true' \
      --label-add 'traefik.http.routers.whatsapp-api1.rule=Host("api1.checkin24hs.com")' \
      --label-add 'traefik.http.routers.whatsapp-api1.entrypoints=websecure' \
      --label-add 'traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt' \
      --label-add 'traefik.http.routers.whatsapp-api1.tls=true' \
      --label-add 'traefik.http.routers.whatsapp-api1.service=whatsapp-service' \
      --label-add 'traefik.http.services.whatsapp-service.loadbalancer.server.port=3001' \
      "$SERVICE_NAME"
    
    if [ $? -eq 0 ]; then
        echo "✅ Etiquetas de Traefik agregadas"
    else
        echo "❌ Error al agregar etiquetas"
        exit 1
    fi
else
    echo "$TRAEFIK_LABELS"
    echo ""
    echo "✅ Etiquetas de Traefik encontradas"
fi

echo ""
echo "Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

# 4. Verificar que el servicio está escuchando en el puerto correcto
echo ""
echo "4️⃣ Verificando puerto interno del servicio..."
CONTAINER=$(docker ps | grep "checkin24hs_whatsapp.1" | awk '{print $1}' | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    echo "Verificando si está escuchando en puerto 3001..."
    docker exec "$CONTAINER" netstat -tlnp 2>/dev/null | grep 3001 || echo "⚠️ No se pudo verificar el puerto (puede ser normal)"
else
    echo "⚠️ No se encontró contenedor activo"
fi

# 5. Probar conexión directa al contenedor
echo ""
echo "5️⃣ Probando conexión directa al contenedor (si está disponible)..."
if [ -n "$CONTAINER" ]; then
    docker exec "$CONTAINER" curl -s http://localhost:3001/api/health 2>/dev/null | head -3 || echo "⚠️ No se pudo conectar al contenedor"
fi

# 6. Probar conexión a través de Traefik
echo ""
echo "6️⃣ Probando conexión a través de Traefik..."
echo "GET https://api1.checkin24hs.com/"
curl -I https://api1.checkin24hs.com/ 2>&1 | head -5

echo ""
echo "GET https://api1.checkin24hs.com/favicon.ico"
curl -I https://api1.checkin24hs.com/favicon.ico 2>&1 | head -5

echo ""
echo "GET https://api1.checkin24hs.com/api/health"
curl -I https://api1.checkin24hs.com/api/health 2>&1 | head -5

echo ""
echo "=========================================="
echo "📋 RESUMEN:"
echo "=========================================="
echo ""
echo "Si ves 404 en todas las rutas:"
echo "  1. El servicio podría no estar iniciado correctamente"
echo "  2. Traefik podría no estar enrutando correctamente"
echo "  3. Verifica los logs: docker service logs $SERVICE_NAME --tail 50"
echo ""
echo "Si ves 200 o 204: ¡Todo está funcionando! ✅"
echo ""
