#!/bin/bash

echo "=========================================="
echo "🔍 VERIFICAR TODAS LAS LABELS DEL SERVICIO"
echo "=========================================="
echo ""

cd /root/checkin24hs

echo "=== TODAS LAS LABELS ==="
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' 2>/dev/null

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""
echo "💡 Si no hay labels de Traefik pero el dominio está configurado en EasyPanel,"
echo "   puede haber un problema con la configuración de EasyPanel o con Traefik mismo."
echo ""
