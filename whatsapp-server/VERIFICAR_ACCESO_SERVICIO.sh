#!/bin/bash

# Script para verificar acceso al servicio WhatsApp

echo "=========================================="
echo "🔍 VERIFICANDO ACCESO AL SERVICIO"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_whatsapp"

# 1. Verificar etiquetas de Traefik
echo "1️⃣ Etiquetas Traefik:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep "^traefik" | sort
echo ""

# 2. Verificar puertos publicados
echo "2️⃣ Puertos publicados del servicio:"
echo "----------------------------------------"
docker service inspect "$SERVICE_NAME" --format '{{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} ({{.Protocol}}){{println}}{{end}}'
echo ""

# 3. Verificar contenedores del servicio
echo "3️⃣ Contenedores del servicio:"
echo "----------------------------------------"
docker service ps "$SERVICE_NAME" --no-trunc --format "table {{.ID}}\t{{.Name}}\t{{.Node}}\t{{.CurrentState}}"
echo ""

# 4. Obtener IP del nodo donde corre el servicio
echo "4️⃣ Información del nodo:"
NODE=$(docker service ps "$SERVICE_NAME" --no-trunc --format "{{.Node}}" | head -1)
echo "   Nodo: $NODE"
echo ""

# 5. Probar acceso a través de Traefik
echo "5️⃣ Probando acceso a través de Traefik:"
echo "----------------------------------------"
echo "   /api/qr:"
curl -I https://whatsapp.checkin24hs.com/api/qr 2>&1 | head -5
echo ""
echo "   /qr:"
curl -I https://whatsapp.checkin24hs.com/qr 2>&1 | head -5
echo ""

# 6. Verificar si el servicio está escuchando dentro del contenedor
echo "6️⃣ Verificando logs del servicio (últimas 10 líneas):"
echo "----------------------------------------"
docker service logs "$SERVICE_NAME" --tail 10 --timestamps | grep -E "(Servidor iniciado|puerto|listening|error|Error)" || echo "   No se encontraron mensajes relevantes"
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "Si curl a localhost:3001 falla, es porque:"
echo "  - El puerto 3001 está dentro del contenedor Docker"
echo "  - No está publicado directamente en el host"
echo "  - El acceso debe ser a través de Traefik"
echo ""
echo "Si /api/qr funciona pero /qr no:"
echo "  - Usa siempre /api/qr (ya funciona)"
echo "  - O verifica configuración de Traefik en EasyPanel"
echo ""
