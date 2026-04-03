#!/bin/bash
# Configurar Let's Encrypt en Traefik

echo "=== CONFIGURACIÓN DE LET'S ENCRYPT EN TRAEFIK ==="
echo ""

TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ Error: No se encontró contenedor de Traefik"
    exit 1
fi

echo "✅ Contenedor de Traefik: $TRAEFIK_CONTAINER"
echo ""

# Verificar si Traefik está usando EasyPanel
if docker inspect $TRAEFIK_CONTAINER | grep -q "easypanel"; then
    echo "📋 Traefik está siendo gestionado por EasyPanel"
    echo ""
    echo "⚠️ IMPORTANTE: Si usas EasyPanel, la configuración de SSL se hace desde el panel web"
    echo ""
    echo "Para configurar SSL en EasyPanel:"
    echo "1. Accede al panel de EasyPanel"
    echo "2. Ve a la configuración de Traefik"
    echo "3. Habilita Let's Encrypt"
    echo "4. Configura el email para los certificados"
    echo ""
    echo "¿Quieres continuar con la configuración manual de Traefik? (s/n)"
    read -r continuar
    
    if [ "$continuar" != "s" ] && [ "$continuar" != "S" ]; then
        echo "✅ Usa EasyPanel para configurar SSL"
        exit 0
    fi
fi

# Solicitar email para Let's Encrypt
echo ""
echo "📧 Ingresa el email para Let's Encrypt (requerido):"
read -r EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email requerido"
    exit 1
fi

echo ""
echo "🔍 Verificando configuración actual de Traefik..."

# Buscar archivo de configuración de Traefik
TRAEFIK_CONFIG_PATH=""
POSSIBLE_PATHS=(
    "/etc/traefik/traefik.yml"
    "/traefik/traefik.yml"
    "/config/traefik.yml"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if docker exec $TRAEFIK_CONTAINER test -f "$path" 2>/dev/null; then
        TRAEFIK_CONFIG_PATH="$path"
        echo "✅ Archivo de configuración encontrado: $path"
        break
    fi
done

# Si no se encuentra en el contenedor, buscar volúmenes montados
if [ -z "$TRAEFIK_CONFIG_PATH" ]; then
    echo "⚠️ No se encontró archivo de configuración en el contenedor"
    echo "   Buscando volúmenes montados..."
    
    VOLUMES=$(docker inspect $TRAEFIK_CONTAINER --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' | grep -i traefik)
    if [ -n "$VOLUMES" ]; then
        echo "   Volúmenes encontrados:"
        echo "$VOLUMES"
    fi
fi

echo ""
echo "=== OPCIONES DE CONFIGURACIÓN ==="
echo ""
echo "Opción 1: Configurar usando labels de Docker (recomendado si usas EasyPanel)"
echo "Opción 2: Crear archivo traefik.yml con Let's Encrypt"
echo ""
echo "¿Qué opción prefieres? (1/2)"
read -r opcion

if [ "$opcion" = "1" ]; then
    echo ""
    echo "📝 Configurando usando labels de Docker..."
    echo ""
    echo "Para configurar Let's Encrypt usando labels, necesitas actualizar el servicio de Traefik:"
    echo ""
    echo "docker service update \\"
    echo "  --label-add 'traefik.certificatesresolvers.letsencrypt.acme.email=${EMAIL}' \\"
    echo "  --label-add 'traefik.certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json' \\"
    echo "  --label-add 'traefik.certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web' \\"
    echo "  traefik"
    echo ""
    echo "¿Quieres aplicar esta configuración ahora? (s/n)"
    read -r aplicar
    
    if [ "$aplicar" = "s" ] || [ "$aplicar" = "S" ]; then
        TRAEFIK_SERVICE=$(docker service ls --filter "name=traefik" --format "{{.Name}}" | head -n 1)
        if [ -n "$TRAEFIK_SERVICE" ]; then
            echo ""
            echo "🔧 Aplicando configuración a $TRAEFIK_SERVICE..."
            
            docker service update \
                --label-add "traefik.certificatesresolvers.letsencrypt.acme.email=${EMAIL}" \
                --label-add "traefik.certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json" \
                --label-add "traefik.certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web" \
                $TRAEFIK_SERVICE
            
            if [ $? -eq 0 ]; then
                echo "✅ Configuración aplicada"
                echo ""
                echo "⏳ Espera unos segundos y verifica los logs:"
                echo "   docker service logs $TRAEFIK_SERVICE --tail 20"
            else
                echo "❌ Error aplicando configuración"
            fi
        else
            echo "⚠️ No se encontró servicio de Traefik en Docker Swarm"
            echo "   Traefik podría estar corriendo como contenedor individual"
        fi
    fi
    
elif [ "$opcion" = "2" ]; then
    echo ""
    echo "📝 Creando archivo traefik.yml con Let's Encrypt..."
    echo ""
    
    cat > /tmp/traefik.yml << EOF
api:
  dashboard: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

certificatesResolvers:
  letsencrypt:
    acme:
      email: ${EMAIL}
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    swarmMode: true
EOF
    
    echo "✅ Archivo traefik.yml creado en /tmp/traefik.yml"
    echo ""
    echo "📋 Contenido del archivo:"
    cat /tmp/traefik.yml
    echo ""
    echo "⚠️ IMPORTANTE: Necesitas montar este archivo en Traefik"
    echo "   Si usas EasyPanel, esto se hace desde el panel web"
    echo ""
fi

echo ""
echo "=== SIGUIENTE PASO ==="
echo ""
echo "Después de configurar Let's Encrypt, ejecuta:"
echo "   bash /root/checkin24hs/APLICAR_LABELS_SSL_WHATSAPP.sh"
echo ""
echo "Esto aplicará los labels SSL a los servicios de WhatsApp"
echo ""






