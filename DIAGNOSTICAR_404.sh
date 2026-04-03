#!/bin/bash
# =====================================================
# DIAGNOSTICAR ERROR 404
# =====================================================
# Este script verifica posibles causas del error 404
# =====================================================

echo "=========================================="
echo "🔍 DIAGNOSTICANDO ERROR 404"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_dashboard"

# Verificar que el servicio está corriendo
echo "=========================================="
echo "1. ESTADO DEL SERVICIO"
echo "=========================================="
echo ""

if docker service ls | grep -q "${SERVICE_NAME}"; then
    echo "✅ Servicio existe"
    docker service ps "${SERVICE_NAME}" --no-trunc --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}" | head -5
else
    echo "❌ Servicio NO existe"
    exit 1
fi

echo ""

# Verificar contenedor
echo "=========================================="
echo "2. CONTENEDOR"
echo "=========================================="
echo ""

CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" --format "{{.ID}}" | head -1)

if [ -z "${CONTAINER_ID}" ]; then
    echo "❌ No se encontró contenedor en ejecución"
    exit 1
fi

echo "✅ Contenedor: ${CONTAINER_ID}"
echo ""

# Verificar archivos en el contenedor
echo "=========================================="
echo "3. ARCHIVOS EN /app/"
echo "=========================================="
echo ""

echo "📋 Archivos principales:"
docker exec "${CONTAINER_ID}" ls -lh /app/*.html /app/*.js 2>/dev/null | head -10 || echo "   (Error al listar archivos)"

echo ""

# Verificar que dashboard.html existe
if docker exec "${CONTAINER_ID}" test -f /app/dashboard.html 2>/dev/null; then
    echo "✅ dashboard.html existe"
    DASHBOARD_SIZE=$(docker exec "${CONTAINER_ID}" stat -c%s /app/dashboard.html 2>/dev/null || echo "0")
    echo "   Tamaño: $(numfmt --to=iec-i --suffix=B ${DASHBOARD_SIZE} 2>/dev/null || echo "${DASHBOARD_SIZE} bytes")"
else
    echo "❌ dashboard.html NO existe"
fi

# Verificar que supabase-client.js existe
if docker exec "${CONTAINER_ID}" test -f /app/supabase-client.js 2>/dev/null; then
    echo "✅ supabase-client.js existe"
    SUPABASE_SIZE=$(docker exec "${CONTAINER_ID}" stat -c%s /app/supabase-client.js 2>/dev/null || echo "0")
    echo "   Tamaño: $(numfmt --to=iec-i --suffix=B ${SUPABASE_SIZE} 2>/dev/null || echo "${SUPABASE_SIZE} bytes")"
else
    echo "❌ supabase-client.js NO existe"
fi

echo ""

# Verificar puerto
echo "=========================================="
echo "4. PUERTO Y CONECTIVIDAD"
echo "=========================================="
echo ""

# Verificar puerto del servicio
SERVICE_PORT=$(docker service inspect "${SERVICE_NAME}" --format '{{range .Endpoint.Ports}}{{.PublishedPort}} -> {{.TargetPort}}{{"\n"}}{{end}}' 2>/dev/null | head -1)
echo "📌 Puerto del servicio: ${SERVICE_PORT}"

# Verificar si el contenedor está escuchando
if docker exec "${CONTAINER_ID}" netstat -tuln 2>/dev/null | grep -q LISTEN; then
    echo "✅ Contenedor está escuchando en algún puerto"
    docker exec "${CONTAINER_ID}" netstat -tuln 2>/dev/null | grep LISTEN | head -5
else
    echo "⚠️  No se pudo verificar puertos (netstat puede no estar disponible)"
fi

echo ""

# Verificar logs recientes
echo "=========================================="
echo "5. LOGS RECIENTES (últimas 20 líneas)"
echo "=========================================="
echo ""

docker service logs "${SERVICE_NAME}" --tail 20 2>&1 | tail -20

echo ""

# Verificar Traefik (si está configurado)
echo "=========================================="
echo "6. VERIFICAR TRAEFIK"
echo "=========================================="
echo ""

TRAEFIK_SERVICE=$(docker service ls | grep -i traefik | awk '{print $1}' | head -1)

if [ ! -z "${TRAEFIK_SERVICE}" ]; then
    echo "✅ Servicio Traefik encontrado: ${TRAEFIK_SERVICE}"
    echo ""
    echo "📋 Labels del servicio dashboard relacionados con Traefik:"
    docker service inspect "${SERVICE_NAME}" --format '{{range $key, $value := .Spec.Labels}}{{if or (contains $key "traefik") (contains $key "traefik")}}{{$key}}={{$value}}{{"\n"}}{{end}}{{end}}' 2>/dev/null | head -10 || echo "   (No se encontraron labels de Traefik)"
else
    echo "⚠️  No se encontró servicio Traefik"
fi

echo ""

# Verificar rutas en dashboard.html
echo "=========================================="
echo "7. VERIFICAR RUTAS EN dashboard.html"
echo "=========================================="
echo ""

if docker exec "${CONTAINER_ID}" test -f /app/dashboard.html 2>/dev/null; then
    echo "🔍 Buscando referencias a supabase-client.js:"
    docker exec "${CONTAINER_ID}" grep -o 'supabase-client\.js[^"]*' /app/dashboard.html 2>/dev/null | head -5 || echo "   (No se encontraron referencias)"
    
    echo ""
    echo "🔍 Buscando rutas de API o recursos:"
    docker exec "${CONTAINER_ID}" grep -oE '(src|href)=["'"'"'][^"'"'"']*' /app/dashboard.html 2>/dev/null | head -10 || echo "   (No se encontraron rutas)"
fi

echo ""

# Resumen
echo "=========================================="
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "=========================================="
echo ""
echo "📝 Información recopilada arriba"
echo ""
echo "💡 Para más información sobre el 404:"
echo "   1. Verifica la URL exacta que muestra el error"
echo "   2. Revisa la consola del navegador (F12) para ver errores"
echo "   3. Verifica los logs del servicio: docker service logs ${SERVICE_NAME}"
echo ""
