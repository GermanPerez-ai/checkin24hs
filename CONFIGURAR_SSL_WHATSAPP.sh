#!/bin/bash
# Script para configurar certificados SSL con Let's Encrypt para los subdominios de WhatsApp
# api1.checkin24hs.com, api2.checkin24hs.com, api3.checkin24hs.com, api4.checkin24hs.com

echo "=== CONFIGURACIÓN DE CERTIFICADOS SSL PARA WHATSAPP ==="
echo ""

# Verificar que Traefik está corriendo
if ! docker ps | grep -q traefik; then
    echo "❌ Error: Traefik no está corriendo"
    echo "   Verifica que Traefik esté iniciado con: docker ps | grep traefik"
    exit 1
fi

echo "✅ Traefik está corriendo"
echo ""

# Verificar configuración de Traefik
echo "📋 Verificando configuración de Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -n 1)
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ No se encontró contenedor de Traefik"
    exit 1
fi

echo "✅ Contenedor de Traefik encontrado: $TRAEFIK_CONTAINER"
echo ""

# Verificar si Traefik tiene configuración de Let's Encrypt
echo "🔍 Verificando configuración de Let's Encrypt en Traefik..."
docker exec $TRAEFIK_CONTAINER cat /etc/traefik/traefik.yml 2>/dev/null | grep -q "letsencrypt" && echo "✅ Let's Encrypt configurado" || echo "⚠️ Let's Encrypt NO configurado"

# Obtener información del servicio de WhatsApp
echo ""
echo "📋 Verificando servicios de WhatsApp..."
docker service ls | grep -i whatsapp || echo "⚠️ No se encontraron servicios de WhatsApp en Docker Swarm"

echo ""
echo "=== OPCIONES DE CONFIGURACIÓN ==="
echo ""
echo "Para configurar SSL en Traefik, necesitas:"
echo ""
echo "1. Verificar que Traefik tiene configuración de Let's Encrypt"
echo "2. Configurar labels en los servicios de WhatsApp para usar HTTPS"
echo "3. Asegurar que los subdominios apuntan al servidor"
echo ""
echo "¿Quieres que verifique la configuración actual de Traefik? (s/n)"
read -r respuesta

if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
    echo ""
    echo "=== CONFIGURACIÓN ACTUAL DE TRAEFIK ==="
    docker exec $TRAEFIK_CONTAINER cat /etc/traefik/traefik.yml 2>/dev/null || echo "⚠️ No se pudo leer traefik.yml"
    
    echo ""
    echo "=== SERVICIOS CONFIGURADOS EN TRAEFIK ==="
    docker service ls --format "table {{.Name}}\t{{.Replicas}}" | grep -E "NAME|whatsapp|api"
fi

echo ""
echo "=== INSTRUCCIONES PARA CONFIGURAR SSL ==="
echo ""
echo "Para configurar SSL para api1.checkin24hs.com, api2.checkin24hs.com, etc., necesitas:"
echo ""
echo "1. Verificar que los DNS apuntan correctamente:"
echo "   - api1.checkin24hs.com -> IP del servidor"
echo "   - api2.checkin24hs.com -> IP del servidor"
echo "   - api3.checkin24hs.com -> IP del servidor"
echo "   - api4.checkin24hs.com -> IP del servidor"
echo ""
echo "2. Asegurar que Traefik tiene configuración de Let's Encrypt:"
echo "   - Email para certificados"
echo "   - Entrada websecure (HTTPS)"
echo ""
echo "3. Agregar labels a los servicios de WhatsApp:"
echo "   traefik.enable=true"
echo "   traefik.http.routers.whatsapp-api1.rule=Host(\`api1.checkin24hs.com\`)"
echo "   traefik.http.routers.whatsapp-api1.entrypoints=websecure"
echo "   traefik.http.routers.whatsapp-api1.tls.certresolver=letsencrypt"
echo ""
echo "¿Quieres que cree un script para aplicar estas configuraciones? (s/n)"
read -r crear_script

if [ "$crear_script" = "s" ] || [ "$crear_script" = "S" ]; then
    echo ""
    echo "📝 Creando script de configuración..."
    cat > /root/checkin24hs/APLICAR_SSL_WHATSAPP.sh << 'EOFSCRIPT'
#!/bin/bash
# Script para aplicar configuración SSL a servicios de WhatsApp

echo "=== APLICANDO CONFIGURACIÓN SSL A WHATSAPP ==="
echo ""

# Verificar que los servicios existen
for i in 1 2 3 4; do
    SERVICE_NAME="checkin24hs_whatsapp_${i}"
    if docker service ls | grep -q "$SERVICE_NAME"; then
        echo "✅ Servicio encontrado: $SERVICE_NAME"
        
        echo "   Aplicando labels de SSL..."
        docker service update \
            --label-add "traefik.enable=true" \
            --label-add "traefik.http.routers.whatsapp-api${i}.rule=Host(\`api${i}.checkin24hs.com\`)" \
            --label-add "traefik.http.routers.whatsapp-api${i}.entrypoints=websecure" \
            --label-add "traefik.http.routers.whatsapp-api${i}.tls.certresolver=letsencrypt" \
            --label-add "traefik.http.services.whatsapp-api${i}.loadbalancer.server.port=3000" \
            $SERVICE_NAME
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Labels aplicados a $SERVICE_NAME"
        else
            echo "   ❌ Error aplicando labels a $SERVICE_NAME"
        fi
    else
        echo "⚠️ Servicio no encontrado: $SERVICE_NAME"
    fi
    echo ""
done

echo "✅ Configuración completada"
echo ""
echo "Espera unos minutos para que Let's Encrypt genere los certificados"
echo "Luego verifica con: curl -I https://api1.checkin24hs.com"
EOFSCRIPT
    
    chmod +x /root/checkin24hs/APLICAR_SSL_WHATSAPP.sh
    echo "✅ Script creado: /root/checkin24hs/APLICAR_SSL_WHATSAPP.sh"
fi

echo ""
echo "=== VERIFICACIÓN DE DNS ==="
echo ""
echo "Verificando resolución DNS de los subdominios..."
for i in 1 2 3 4; do
    SUBDOMAIN="api${i}.checkin24hs.com"
    IP=$(dig +short $SUBDOMAIN | head -n 1)
    if [ -n "$IP" ]; then
        echo "✅ $SUBDOMAIN -> $IP"
    else
        echo "⚠️ $SUBDOMAIN -> No resuelve (verifica DNS)"
    fi
done

echo ""
echo "=== RESUMEN ==="
echo ""
echo "Para completar la configuración SSL:"
echo "1. Verifica que los DNS están configurados correctamente"
echo "2. Asegura que Traefik tiene Let's Encrypt configurado"
echo "3. Ejecuta el script APLICAR_SSL_WHATSAPP.sh si lo creaste"
echo "4. Espera 2-5 minutos para que Let's Encrypt genere los certificados"
echo "5. Verifica con: curl -I https://api1.checkin24hs.com"
echo ""






