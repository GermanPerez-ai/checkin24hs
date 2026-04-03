#!/bin/bash
# Script para verificar y configurar Traefik con Let's Encrypt para SSL

echo "=== VERIFICACIÓN Y CONFIGURACIÓN DE TRAEFIK SSL ==="
echo ""

# Encontrar contenedor de Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ Error: No se encontró contenedor de Traefik"
    echo "   Verifica que Traefik esté corriendo: docker ps | grep traefik"
    exit 1
fi

echo "✅ Contenedor de Traefik encontrado: $TRAEFIK_CONTAINER"
echo ""

# Verificar configuración de Traefik
echo "📋 Verificando configuración de Traefik..."
echo ""

# Verificar si tiene archivo de configuración
if docker exec $TRAEFIK_CONTAINER test -f /etc/traefik/traefik.yml; then
    echo "✅ Archivo traefik.yml encontrado"
    echo ""
    echo "=== CONTENIDO DE TRAEFIK.YML ==="
    docker exec $TRAEFIK_CONTAINER cat /etc/traefik/traefik.yml
    echo ""
else
    echo "⚠️ No se encontró traefik.yml en el contenedor"
    echo "   Traefik podría estar usando solo labels de Docker"
fi

# Verificar si Let's Encrypt está configurado
echo "=== VERIFICANDO CONFIGURACIÓN DE LET'S ENCRYPT ==="
echo ""

if docker exec $TRAEFIK_CONTAINER cat /etc/traefik/traefik.yml 2>/dev/null | grep -q "letsencrypt\|certificatesResolvers"; then
    echo "✅ Let's Encrypt parece estar configurado"
    docker exec $TRAEFIK_CONTAINER cat /etc/traefik/traefik.yml 2>/dev/null | grep -A 10 "certificatesResolvers\|letsencrypt"
else
    echo "⚠️ Let's Encrypt NO está configurado en traefik.yml"
    echo ""
    echo "=== CONFIGURACIÓN RECOMENDADA PARA TRAEFIK ==="
    echo ""
    cat << 'EOF'
# Ejemplo de configuración para traefik.yml con Let's Encrypt:

certificatesResolvers:
  letsencrypt:
    acme:
      email: tu-email@ejemplo.com  # CAMBIA ESTO
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
EOF
    echo ""
fi

# Verificar servicios de WhatsApp
echo "=== VERIFICANDO SERVICIOS DE WHATSAPP ==="
echo ""
docker service ls | grep -E "NAME|whatsapp|api" || echo "⚠️ No se encontraron servicios de WhatsApp"

echo ""
echo "=== VERIFICANDO DNS ==="
echo ""
for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    echo -n "Verificando $SUBDOMAIN... "
    IP=$(dig +short $SUBDOMAIN 2>/dev/null | head -n 1)
    if [ -n "$IP" ]; then
        echo "✅ -> $IP"
    else
        echo "❌ No resuelve"
    fi
done

echo ""
echo "=== INSTRUCCIONES ==="
echo ""
echo "Para configurar SSL correctamente:"
echo ""
echo "1. Si Let's Encrypt NO está configurado:"
echo "   - Edita el archivo de configuración de Traefik"
echo "   - Agrega la configuración de certificatesResolvers mostrada arriba"
echo "   - Reinicia Traefik"
echo ""
echo "2. Para los servicios de WhatsApp, agrega estos labels:"
echo "   traefik.enable=true"
echo "   traefik.http.routers.whatsapp-api1.rule=Host(\`api1.checkin24hs.com\`)"
echo "   traefik.http.routers.whatsapp-api1.entrypoints=websecure"
echo "   traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt"
echo ""
echo "3. Verifica que los DNS apuntan al servidor"
echo ""
echo "¿Quieres que cree un script para aplicar los labels a los servicios? (s/n)"
read -r respuesta

if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
    echo ""
    echo "📝 Creando script de aplicación de labels..."
    
    cat > /root/checkin24hs/APLICAR_LABELS_SSL_WHATSAPP.sh << 'EOFLABELS'
#!/bin/bash
# Aplicar labels de SSL a servicios de WhatsApp

echo "=== APLICANDO LABELS SSL A SERVICIOS WHATSAPP ==="
echo ""

# Buscar servicios de WhatsApp
SERVICES=$(docker service ls --format "{{.Name}}" | grep -i whatsapp)

if [ -z "$SERVICES" ]; then
    echo "⚠️ No se encontraron servicios de WhatsApp"
    echo "   Buscando servicios con 'api' en el nombre..."
    SERVICES=$(docker service ls --format "{{.Name}}" | grep -i api)
fi

if [ -z "$SERVICES" ]; then
    echo "❌ No se encontraron servicios. Listando todos los servicios:"
    docker service ls
    exit 1
fi

echo "Servicios encontrados:"
echo "$SERVICES"
echo ""

# Para cada servicio de WhatsApp (1-4)
for i in 1 2 3 4; do
    # Intentar diferentes nombres posibles
    for SERVICE_NAME in "checkin24hs_whatsapp_${i}" "whatsapp_${i}" "whatsapp-api${i}" "api${i}"; do
        if docker service ls | grep -q "^${SERVICE_NAME} "; then
            echo "✅ Encontrado: $SERVICE_NAME"
            echo "   Aplicando labels SSL para api${i}.checkin24hs.com..."
            
            docker service update \
                --label-add "traefik.enable=true" \
                --label-add "traefik.http.routers.whatsapp-api${i}.rule=Host(\`api${i}.checkin24hs.com\`)" \
                --label-add "traefik.http.routers.whatsapp-api${i}.entrypoints=websecure" \
                --label-add "traefik.http.routers.whatsapp-api${i}.tls.certresolver=letsencrypt" \
                --label-add "traefik.http.services.whatsapp-api${i}.loadbalancer.server.port=3000" \
                $SERVICE_NAME 2>&1
            
            if [ $? -eq 0 ]; then
                echo "   ✅ Labels aplicados correctamente"
            else
                echo "   ⚠️ Hubo un problema aplicando los labels"
            fi
            echo ""
            break
        fi
    done
done

echo "✅ Proceso completado"
echo ""
echo "Espera 2-5 minutos para que Let's Encrypt genere los certificados"
echo "Luego verifica con: curl -I https://api1.checkin24hs.com"
EOFLABELS
    
    chmod +x /root/checkin24hs/APLICAR_LABELS_SSL_WHATSAPP.sh
    echo "✅ Script creado: /root/checkin24hs/APLICAR_LABELS_SSL_WHATSAPP.sh"
fi

echo ""
echo "=== FINALIZADO ==="

