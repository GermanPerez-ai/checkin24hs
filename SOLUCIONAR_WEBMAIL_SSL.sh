#!/bin/bash
# Script para solucionar el error de certificado SSL en webmail

cd /root/checkin24hs

echo "=========================================="
echo "🔧 SOLUCIONANDO ERROR SSL EN WEBMAIL"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"

# 1. Verificar que el servicio existe
echo "1️⃣ Verificando servicio webmail..."
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "❌ Servicio $SERVICE_NAME no encontrado"
    docker service ls | grep -i webmail
    exit 1
fi
echo "✅ Servicio encontrado"
echo ""

# 2. Verificar configuración actual de Traefik
echo "2️⃣ Verificando configuración actual de Traefik..."
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik
echo ""

# 3. Obtener red de EasyPanel/Traefik
echo "3️⃣ Obteniendo red de Traefik..."
EASYPANEL_NET=$(docker network ls | grep easypanel | head -1 | awk '{print $1}')
if [ -z "$EASYPANEL_NET" ]; then
    echo "⚠️ No se encontró red easypanel, buscando red de Traefik..."
    EASYPANEL_NET=$(docker network ls | grep traefik | head -1 | awk '{print $1}')
fi

if [ -z "$EASYPANEL_NET" ]; then
    echo "❌ No se encontró red de Traefik"
    echo "Redes disponibles:"
    docker network ls
    exit 1
fi

echo "✅ Red encontrada: $EASYPANEL_NET"
echo ""

# 4. Agregar webmail a la red de Traefik (si no está)
echo "4️⃣ Agregando webmail a la red de Traefik..."
docker service update --network-add $EASYPANEL_NET $SERVICE_NAME 2>/dev/null && echo "✅ Agregado a la red" || echo "⚠️ Ya estaba en la red o error"
sleep 5
echo ""

# 5. Configurar Traefik con SSL (Let's Encrypt)
echo "5️⃣ Configurando Traefik con SSL para webmail..."

# Verificar si Traefik tiene Let's Encrypt configurado
TRAEFIK_SERVICE=$(docker service ls | grep traefik | awk '{print $2}' | head -1)
if [ -z "$TRAEFIK_SERVICE" ]; then
    echo "❌ No se encontró servicio Traefik"
    exit 1
fi

# Verificar si Traefik tiene certificadosresolvers
TRAEFIK_HAS_ACME=$(docker service inspect $TRAEFIK_SERVICE --format '{{range .Spec.TaskTemplate.ContainerSpec.Args}}{{.}}{{"\n"}}{{end}}' | grep -i "certificatesresolvers\|letsencrypt\|acme" | head -1)

if [ -z "$TRAEFIK_HAS_ACME" ]; then
    echo "⚠️ Traefik NO tiene Let's Encrypt configurado"
    echo ""
    echo "📋 OPCIÓN 1: Usar HTTP temporalmente (más rápido)"
    echo "   Accede a: http://webmail.checkin24hs.com (sin 's')"
    echo ""
    echo "📋 OPCIÓN 2: Configurar Let's Encrypt en Traefik (recomendado)"
    echo "   Esto requiere recrear Traefik con Let's Encrypt"
    echo ""
    read -p "¿Quieres configurar Let's Encrypt ahora? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "✅ Configurando solo HTTP por ahora..."
        HTTP_ONLY=true
    else
        HTTP_ONLY=false
    fi
else
    echo "✅ Traefik tiene Let's Encrypt configurado"
    HTTP_ONLY=false
fi

# 6. Agregar etiquetas de Traefik
echo ""
echo "6️⃣ Agregando etiquetas de Traefik..."

if [ "$HTTP_ONLY" = true ]; then
    # Solo HTTP
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
      --label-add "traefik.http.routers.webmail.entrypoints=web" \
      --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
      $SERVICE_NAME
else
    # HTTP y HTTPS con Let's Encrypt
    docker service update \
      --label-add "traefik.enable=true" \
      --label-add "traefik.http.routers.webmail.rule=Host(\`$DOMAIN\`)" \
      --label-add "traefik.http.routers.webmail.entrypoints=web" \
      --label-add "traefik.http.routers.webmail-secure.rule=Host(\`$DOMAIN\`)" \
      --label-add "traefik.http.routers.webmail-secure.entrypoints=websecure" \
      --label-add "traefik.http.routers.webmail-secure.tls=true" \
      --label-add "traefik.http.routers.webmail-secure.tls.certresolver=letsencrypt" \
      --label-add "traefik.http.services.webmail.loadbalancer.server.port=80" \
      $SERVICE_NAME
fi

echo "✅ Etiquetas agregadas"
echo ""

# 7. Esperar y verificar
echo "7️⃣ Esperando 15 segundos para que Traefik detecte los cambios..."
sleep 15

# 8. Verificar configuración
echo ""
echo "8️⃣ Verificando configuración aplicada:"
docker service inspect $SERVICE_NAME --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik
echo ""

# 9. Verificar logs de Traefik
echo "9️⃣ Verificando logs de Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo "Logs recientes de Traefik relacionados con webmail:"
    docker logs $TRAEFIK_CONTAINER --tail 50 2>&1 | grep -i "webmail\|$DOMAIN" | tail -10 || echo "No se encontraron logs específicos"
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi

echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETA"
echo "=========================================="
echo ""
if [ "$HTTP_ONLY" = true ]; then
    echo "📋 ACCESO TEMPORAL (HTTP):"
    echo "   http://$DOMAIN"
    echo ""
    echo "⚠️ Para HTTPS, necesitas configurar Let's Encrypt en Traefik"
else
    echo "📋 ACCESO:"
    echo "   http://$DOMAIN (redirige a HTTPS)"
    echo "   https://$DOMAIN (con certificado SSL)"
    echo ""
    echo "⏳ Espera 1-2 minutos para que Let's Encrypt genere el certificado"
fi
echo ""
echo "🔍 Si aún no funciona:"
echo "   1. Verifica el DNS: nslookup $DOMAIN"
echo "   2. Verifica logs: docker service logs $SERVICE_NAME --tail 50"
echo "   3. Verifica Traefik: docker service logs traefik --tail 100"
echo "=========================================="






