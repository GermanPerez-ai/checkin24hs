#!/bin/bash
# Verificar y corregir Traefik para que WhatsApp sea accesible en https://whatsapp.checkin24hs.com
# Ejecutar en el servidor (SSH): bash VERIFICAR_Y_CORREGIR_TRAEFIK_WHATSAPP.sh

set -e
echo "=============================================="
echo "🔍 TRAEFIK + WHATSAPP - Verificación y corrección"
echo "=============================================="
echo ""

# 1. Detectar nombre del servicio WhatsApp
echo "1️⃣ Buscando servicio WhatsApp..."
SERVICE_NAME=""
for name in checkin24hs_whatsapp whatsapp checkin24hs-whatsapp; do
    if docker service ls --format '{{.Name}}' 2>/dev/null | grep -q "^${name}$"; then
        SERVICE_NAME="$name"
        break
    fi
done
if [ -z "$SERVICE_NAME" ]; then
    echo "   Servicios Docker disponibles (con 'whatsapp' en el nombre):"
    docker service ls --format '{{.Name}}' 2>/dev/null | grep -i whatsapp || true
    SERVICE_NAME=$(docker service ls --format '{{.Name}}' 2>/dev/null | grep -i whatsapp | head -1)
fi
if [ -z "$SERVICE_NAME" ]; then
    echo "❌ No se encontró ningún servicio de WhatsApp."
    echo "   En EasyPanel verifica que el servicio WhatsApp esté creado y corriendo."
    exit 1
fi
echo "   ✅ Servicio: $SERVICE_NAME"
echo ""

# 2. Etiquetas Traefik actuales
echo "2️⃣ Etiquetas Traefik actuales:"
echo "----------------------------------------"
TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep "^traefik" | sort) || true
if [ -z "$TRAEFIK_LABELS" ]; then
    echo "   ❌ No hay etiquetas Traefik (por eso no se puede conectar por dominio)"
else
    echo "$TRAEFIK_LABELS"
fi
echo ""

# 3. Red del servicio
echo "3️⃣ Red del servicio:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null || echo "   (no se pudo leer)"
echo ""

# 4. Estado del servicio
echo "4️⃣ Estado del servicio:"
echo "----------------------------------------"
docker service ps "$SERVICE_NAME" --no-trunc 2>/dev/null | head -5
echo ""

# Decidir si aplicar corrección
FALTA_LABELS=0
echo "$TRAEFIK_LABELS" | grep -q "traefik.http.routers.whatsapp.rule" || FALTA_LABELS=1
echo "$TRAEFIK_LABELS" | grep -q "traefik.http.services.whatsapp.loadbalancer.server.port" || FALTA_LABELS=1

if [ "$FALTA_LABELS" -eq 1 ]; then
    echo "=============================================="
    echo "🔧 APLICAR ETIQUETAS TRAEFIK (necesario para conectar)"
    echo "=============================================="
    echo ""
    echo "Se van a agregar las etiquetas para que Traefik enrute:"
    echo "  https://whatsapp.checkin24hs.com → servicio WhatsApp (puerto 3001)"
    echo ""
    read -p "¿Aplicar ahora? (s/n): " -r
    if [[ $REPLY =~ ^[sS] ]]; then
        # Red easypanel si no está
        if ! docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null | grep -q "easypanel"; then
            echo "   Agregando servicio a la red easypanel..."
            docker service update --network-add easypanel "$SERVICE_NAME" 2>/dev/null || true
            sleep 3
        fi
        echo "   Agregando etiquetas Traefik..."
        docker service update \
          --label-add "traefik.enable=true" \
          --label-add "traefik.http.routers.whatsapp.rule=Host(\`whatsapp.checkin24hs.com\`)" \
          --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
          --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
          --label-add "traefik.http.routers.whatsapp.tls=true" \
          --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
          --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
          "$SERVICE_NAME"
        echo "   ✅ Etiquetas aplicadas."
        echo ""
        echo "   Espera 30–60 segundos y prueba:"
        echo "   - https://whatsapp.checkin24hs.com/api/health"
        echo "   - https://whatsapp.checkin24hs.com/api/qr"
    else
        echo "   No se aplicaron cambios. Para hacerlo manualmente:"
        echo ""
        echo "   docker service update \\"
        echo "     --label-add \"traefik.enable=true\" \\"
        echo "     --label-add \"traefik.http.routers.whatsapp.rule=Host(\\\`whatsapp.checkin24hs.com\\\`)\" \\"
        echo "     --label-add \"traefik.http.routers.whatsapp.entrypoints=websecure\" \\"
        echo "     --label-add \"traefik.http.routers.whatsapp.service=whatsapp\" \\"
        echo "     --label-add \"traefik.http.routers.whatsapp.tls=true\" \\"
        echo "     --label-add \"traefik.http.routers.whatsapp.tls.certresolver=letsencrypt\" \\"
        echo "     --label-add \"traefik.http.services.whatsapp.loadbalancer.server.port=3001\" \\"
        echo "     $SERVICE_NAME"
    fi
else
    echo "=============================================="
    echo "✅ Las etiquetas Traefik ya están configuradas"
    echo "=============================================="
    echo ""
    echo "Si igual no podés conectar:"
    echo "  1. Verificá DNS:  nslookup whatsapp.checkin24hs.com"
    echo "  2. Probá:        https://whatsapp.checkin24hs.com/api/health"
    echo "  3. Reiniciar Traefik:  docker service update --force \$(docker service ls -q --filter name=traefik)"
fi
echo ""
