#!/bin/bash
cd /root/checkin24hs
echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO: WEBMAIL BAD GATEWAY"
echo "=========================================="
echo ""
echo "=== 1. ESTADO DEL SERVICIO WEBMAIL ==="
docker service ls | grep webmail
echo ""
echo "=== 2. CONTENEDORES DEL WEBMAIL ==="
docker ps | grep webmail
echo ""
echo "=== 3. CONFIGURACIÓN DE TRAEFIK PARA WEBMAIL ==="
docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik || echo "⚠️ No se encontraron etiquetas de Traefik"
echo ""
echo "=== 4. VERIFICANDO REDES ==="
WEBMAIL_NET=$(docker service inspect checkin24hs_webmail --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1 | head -1)
TRAEFIK_NET=$(docker service inspect traefik --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}' 2>&1 | head -1)
echo "Red del webmail: $WEBMAIL_NET"
echo "Red de Traefik: $TRAEFIK_NET"
if [ "$WEBMAIL_NET" = "$TRAEFIK_NET" ]; then
    echo "✅ Están en la misma red"
else
    echo "❌ NO están en la misma red - ESTE ES EL PROBLEMA"
fi
echo ""
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
if [ "$WEBMAIL_NET" != "$TRAEFIK_NET" ]; then
    echo "❌ PROBLEMA: Webmail y Traefik NO están en la misma red"
    echo "🔧 Ejecuta: bash SOLUCIONAR_WEBMAIL_BAD_GATEWAY.sh"
fi
TRAEFIK_LABELS=$(docker service inspect checkin24hs_webmail --format='{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' 2>&1 | grep -i traefik | wc -l)
if [ "$TRAEFIK_LABELS" -eq "0" ]; then
    echo "❌ PROBLEMA: Webmail NO tiene etiquetas de Traefik"
    echo "🔧 Ejecuta: bash SOLUCIONAR_WEBMAIL_BAD_GATEWAY.sh"
fi
