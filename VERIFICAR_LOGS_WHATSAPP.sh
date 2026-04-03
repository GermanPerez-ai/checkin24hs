#!/bin/bash
# Verificar logs del servicio WhatsApp para diagnosticar problemas

SERVICE_NAME="checkin24hs_whatsapp"

echo "=========================================="
echo "📋 LOGS DEL SERVICIO WHATSAPP"
echo "=========================================="
echo ""

# Mostrar últimas 50 líneas de logs
echo "🔍 Últimas 50 líneas de logs:"
echo "=========================================="
docker service logs $SERVICE_NAME --tail 50 --no-trunc 2>&1
echo ""

# Buscar errores específicos
echo "=========================================="
echo "🔍 BUSCANDO ERRORES ESPECÍFICOS"
echo "=========================================="
echo ""

echo "📌 Errores de conexión:"
docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -i "error\|fail\|exception" | tail -20
echo ""

echo "📌 Mensajes sobre QR:"
docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -i "qr\|scan\|waiting" | tail -20
echo ""

echo "📌 Mensajes sobre autenticación:"
docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -i "auth\|login\|connect\|428" | tail -20
echo ""

echo "📌 Mensajes sobre Flor IA:"
docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -i "flor\|gemini\|api.*key" | tail -20
echo ""

echo "📌 Mensajes sobre Supabase:"
docker service logs $SERVICE_NAME --tail 200 --no-trunc 2>&1 | grep -i "supabase\|database\|save" | tail -20
echo ""

echo "=========================================="
echo "💡 Para ver logs en tiempo real:"
echo "   docker service logs -f $SERVICE_NAME"
echo "=========================================="
