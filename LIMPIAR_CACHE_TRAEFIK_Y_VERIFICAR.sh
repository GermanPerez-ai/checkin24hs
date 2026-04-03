#!/bin/bash
# Limpiar caché de Traefik y verificar etiquetas en contenedores

echo "=========================================="
echo "🧹 Limpiando caché de Traefik y verificando"
echo "=========================================="
echo ""

# 1. Verificar etiquetas en contenedores directamente
echo "1️⃣ Verificando etiquetas en contenedores del dashboard..."
DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ ! -z "$DASHBOARD_CONTAINER" ]; then
    echo "Contenedor encontrado: $DASHBOARD_CONTAINER"
    echo "Etiquetas Traefik:"
    docker inspect "$DASHBOARD_CONTAINER" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "No tiene etiquetas Traefik"
else
    echo "⚠️  No se encontró contenedor del dashboard"
fi
echo ""

echo "2️⃣ Verificando etiquetas en contenedores del CRM..."
CRM_CONTAINER=$(docker ps --filter "name=crm" --format "{{.ID}}" | head -1)

if [ ! -z "$CRM_CONTAINER" ]; then
    echo "Contenedor encontrado: $CRM_CONTAINER"
    echo "Etiquetas Traefik:"
    docker inspect "$CRM_CONTAINER" --format '{{range $key, $value := .Config.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik || echo "No tiene etiquetas Traefik"
else
    echo "⚠️  No se encontró contenedor del CRM"
fi
echo ""

# 3. Reiniciar Traefik para limpiar caché
echo "3️⃣ Reiniciando Traefik para limpiar caché..."
docker service update --force traefik

if [ $? -eq 0 ]; then
    echo "✅ Traefik reiniciado"
    echo "Esperando 30 segundos para que Traefik se reinicie completamente..."
    sleep 30
else
    echo "❌ Error al reiniciar Traefik"
    exit 1
fi
echo ""

# 4. Verificar logs después del reinicio
echo "4️⃣ Verificando logs de Traefik después del reinicio..."
sleep 10
docker service logs traefik --tail 50 | grep -iE "error|dashboard|crm|router" | tail -15

echo ""
echo "5️⃣ Verificando si hay conflictos..."
CONFLICTS=$(docker service logs traefik --tail 30 | grep -iE "cannot be linked automatically|multiple Services" | wc -l)

if [ "$CONFLICTS" -eq 0 ]; then
    echo "✅ No se detectaron conflictos después del reinicio"
else
    echo "⚠️  Aún hay conflictos:"
    docker service logs traefik --tail 30 | grep -iE "cannot be linked automatically|multiple Services"
fi

# 6. Verificar configuración final del dashboard
echo ""
echo "6️⃣ Verificando configuración final del dashboard..."
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "=========================================="
echo "✅ Verificación completada"
echo "=========================================="
echo ""
echo "Si aún hay conflictos, puede ser necesario:"
echo "  1. Esperar más tiempo (Traefik puede tardar en actualizar)"
echo "  2. Verificar si hay etiquetas en archivos de configuración"
echo "  3. Verificar la configuración de EasyPanel"
echo ""
