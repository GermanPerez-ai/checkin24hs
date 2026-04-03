#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICANDO CERTIFICADO SSL DE API1"
echo "=========================================="
echo ""

# 1. Verificar certificado SSL directamente
echo "1️⃣ Verificando certificado SSL:"
echo "=========================================="
echo | openssl s_client -connect api1.checkin24hs.com:443 -servername api1.checkin24hs.com 2>/dev/null | openssl x509 -noout -dates -subject -issuer 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Certificado SSL válido"
else
    echo "❌ Error verificando certificado SSL"
fi
echo ""

# 2. Probar conexión HTTPS
echo "2️⃣ Probando conexión HTTPS:"
echo "=========================================="
curl -I https://api1.checkin24hs.com/api/status?card=1 2>&1 | head -10
echo ""

# 3. Verificar configuración de Traefik
echo "3️⃣ Verificando configuración de Traefik:"
echo "=========================================="
TRAEFIK=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
if [ -n "$TRAEFIK" ]; then
    echo "Contenedor Traefik: $TRAEFIK"
    docker logs "$TRAEFIK" --tail 20 | grep -i "api1\|letsencrypt\|certificate\|tls" | tail -10
else
    echo "⚠️ No se encontró contenedor de Traefik"
fi
echo ""

# 4. Verificar etiquetas del servicio de WhatsApp
echo "4️⃣ Verificando etiquetas del servicio WhatsApp:"
echo "=========================================="
docker service inspect checkin24hs_whatsapp --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep -i "traefik\|tls\|cert" | head -10
echo ""

# 5. Verificar si el certificado está expirado
echo "5️⃣ Verificando fecha de expiración del certificado:"
echo "=========================================="
echo | openssl s_client -connect api1.checkin24hs.com:443 -servername api1.checkin24hs.com 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null
echo ""

echo "=========================================="
echo "📋 DIAGNÓSTICO:"
echo "=========================================="
echo ""
echo "Si el certificado está expirado o inválido:"
echo "  1. Traefik debería renovarlo automáticamente con Let's Encrypt"
echo "  2. Si no se renueva, verifica la configuración de Traefik"
echo ""
echo "Si el certificado es válido pero el dashboard muestra error:"
echo "  1. Puede ser un problema de caché del navegador"
echo "  2. Intenta limpiar la caché o usar modo incógnito"
echo "  3. Verifica que el dashboard esté usando HTTPS correctamente"
echo ""



