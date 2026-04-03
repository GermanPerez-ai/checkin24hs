#!/bin/bash

# Diagnóstico completo del problema 404

echo "=========================================="
echo "🔍 DIAGNÓSTICO COMPLETO - ERROR 404"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Verificar etiquetas de Traefik
echo "1️⃣ ETIQUETAS DE TRAEFIK:"
echo "----------------------------------------"
TRAEFIK_LABELS=$(docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik")
if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ NO HAY ETIQUETAS DE TRAEFIK"
    echo "   Esto es el problema principal"
else
    echo "$TRAEFIK_LABELS"
fi
echo ""

# 2. Verificar estado del servicio
echo "2️⃣ ESTADO DEL SERVICIO:"
echo "----------------------------------------"
docker service ps "$SERVICE_NAME" --no-trunc --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}"
echo ""

# 3. Verificar red
echo "3️⃣ RED DEL SERVICIO:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'
echo ""

# 4. Verificar logs recientes
echo "4️⃣ LOGS RECIENTES (últimas 30 líneas):"
echo "----------------------------------------"
docker service logs "$SERVICE_NAME" --tail 30 --timestamps | tail -20
echo ""

# 5. Verificar si el servicio está escuchando
echo "5️⃣ VERIFICANDO SI EL SERVIDOR INICIÓ:"
echo "----------------------------------------"
docker service logs "$SERVICE_NAME" --tail 100 | grep -E "(Servidor iniciado|puerto 3001|listening|Error iniciando)" || echo "   No se encontraron mensajes de inicio"
echo ""

# 6. Verificar contenedores
echo "6️⃣ CONTENEDORES DEL SERVICIO:"
echo "----------------------------------------"
docker ps --filter "name=whatsapp" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
if [ -z "$TRAEFIK_LABELS" ]; then
    echo "❌ PROBLEMA PRINCIPAL: No hay etiquetas de Traefik"
    echo ""
    echo "SOLUCIÓN: Ejecuta estos comandos:"
    echo ""
    echo "docker service update \\"
    echo "  --label-add \"traefik.enable=true\" \\"
    echo "  --label-add \"traefik.http.routers.whatsapp.rule=Host(\\\`whatsapp.checkin24hs.com\\\`)\" \\"
    echo "  --label-add \"traefik.http.routers.whatsapp.entrypoints=websecure\" \\"
    echo "  --label-add \"traefik.http.routers.whatsapp.tls=true\" \\"
    echo "  --label-add \"traefik.http.routers.whatsapp.tls.certresolver=letsencrypt\" \\"
    echo "  --label-add \"traefik.http.services.whatsapp.loadbalancer.server.port=3001\" \\"
    echo "  checkin24hs_whatsapp"
    echo ""
    echo "Luego espera 30-60 segundos y prueba nuevamente"
else
    echo "✅ Las etiquetas de Traefik están configuradas"
    echo "   El problema puede ser:"
    echo "   - El servidor HTTP no está iniciando"
    echo "   - Traefik necesita reiniciarse"
    echo "   - Hay un problema de red"
fi
echo ""
