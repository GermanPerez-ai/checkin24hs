#!/bin/bash
# 🔍 Verificar Traefik y mapeo de puertos después del redeploy

echo "=============================================================="
echo "🔍 VERIFICANDO TRAEFIK Y MAPEO DE PUERTOS"
echo "=============================================================="
echo ""

cd /root/checkin24hs

# 1. Verificar mapeo de puertos del servicio
echo "1️⃣  Mapeo de puertos del servicio Docker Swarm:"
docker service inspect checkin24hs_whatsapp --format '{{json .Endpoint.Ports}}' | python3 -m json.tool
echo ""

# 2. Verificar puerto en el host
echo "2️⃣  Puerto escuchando en el host:"
ss -tuln | grep 3001 && echo "   ✅ Puerto 3001 está escuchando" || echo "   ❌ Puerto 3001 NO está escuchando"
echo ""

# 3. Verificar servicio Traefik
echo "3️⃣  Servicio Traefik:"
docker service ls | grep traefik || docker ps | grep traefik | head -1
echo ""

# 4. Verificar labels de Traefik en el servicio
echo "4️⃣  Labels de Traefik en el servicio:"
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.Labels}}' | python3 -m json.tool | grep -E "traefik|router|rule" || echo "   ⚠️  No se encontraron labels de Traefik"
echo ""

# 5. Verificar configuración de red del servicio
echo "5️⃣  Redes del servicio:"
docker service inspect checkin24hs_whatsapp --format '{{json .Spec.Networks}}' | python3 -m json.tool
echo ""

# 6. Verificar contenedor y sus redes
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | grep -v "whatsapp2\|whatsapp3\|whatsapp4" | awk '{print $1}' | head -1)
echo "6️⃣  Redes del contenedor:"
docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{$value.IPAddress}}{{println}}{{end}}'
echo ""

# 7. Verificar si Traefik puede alcanzar el servicio
echo "7️⃣  Verificando conectividad desde Traefik:"
TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}' | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "   Contenedor Traefik: $TRAEFIK_CONTAINER"
    CONTAINER_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{println}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$CONTAINER_IP" ] && [ "$CONTAINER_IP" != "10.0.0.10" ]; then
        echo "   Probando conexión desde Traefik a $CONTAINER_IP:3001..."
        docker exec $TRAEFIK_CONTAINER sh -c "wget -qO- --timeout=3 http://$CONTAINER_IP:3001/api/health 2>&1 || echo 'No responde'" && echo "   ✅ Traefik puede alcanzar el servicio" || echo "   ❌ Traefik NO puede alcanzar el servicio"
    else
        echo "   ⚠️  No se pudo obtener IP del contenedor"
    fi
else
    echo "   ⚠️  Contenedor Traefik no encontrado"
fi
echo ""

# 8. Verificar reglas de Traefik (si está usando file provider)
echo "8️⃣  Buscando configuración de Traefik para whatsapp:"
docker exec $TRAEFIK_CONTAINER sh -c "cat /etc/traefik/traefik.yml 2>/dev/null | grep -i whatsapp || echo 'No se encontró configuración'" 2>/dev/null || echo "   ⚠️  No se puede acceder a configuración de Traefik"
echo ""

# 9. Si el puerto no está mapeado, mapearlo
if ! ss -tuln | grep -q 3001; then
    echo "9️⃣  ⚠️  Puerto no está mapeado. Mapeando ahora..."
    docker service update --publish-add published=3001,target=3001,protocol=tcp checkin24hs_whatsapp
    echo "   ✅ Comando de mapeo ejecutado"
    echo ""
    echo "   Esperando 30 segundos..."
    sleep 30
    echo ""
    echo "   Verificando nuevamente:"
    ss -tuln | grep 3001 && echo "   ✅ Puerto ahora está escuchando" || echo "   ❌ Puerto aún no está escuchando"
else
    echo "9️⃣  ✅ Puerto está mapeado correctamente"
fi
echo ""

# 10. Probar conexión directa
echo "🔟 Probando conexión directa:"
timeout 5 curl -s --max-time 3 http://127.0.0.1:3001/api/health && echo "   ✅ Servidor responde directamente" || echo "   ❌ Servidor no responde directamente"
echo ""

# 11. Probar a través de Traefik (si hay dominio configurado)
echo "1️⃣1️⃣  Si tienes un dominio configurado en Traefik, prueba:"
echo "   curl http://tu-dominio.com/api/health"
echo "   (Reemplaza 'tu-dominio.com' con tu dominio real)"
echo ""

echo "=============================================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=============================================================="
echo ""
