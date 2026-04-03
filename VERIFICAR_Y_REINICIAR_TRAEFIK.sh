#!/bin/bash
# Verificar si el endpoint funciona y reiniciar Traefik si es necesario

echo "=========================================="
echo "🔍 Verificando endpoint y reiniciando Traefik"
echo "=========================================="
echo ""

echo "1️⃣ Verificando etiquetas actuales del dashboard..."
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "2️⃣ Los conflictos en Traefik pueden estar causando que no enrute correctamente"
echo "   Vamos a reiniciar Traefik para limpiar la caché y forzar la actualización"
echo ""

echo "3️⃣ Reiniciando Traefik..."
docker service update --force traefik

if [ $? -eq 0 ]; then
    echo "✅ Traefik reiniciado"
    echo "   Esperando 30 segundos para que Traefik se reinicie completamente..."
    sleep 30
else
    echo "❌ Error al reiniciar Traefik"
    exit 1
fi

echo ""
echo "4️⃣ Verificando logs de Traefik después del reinicio..."
docker service logs traefik --tail 30 | grep -iE "dashboard|api|error|router" | tail -15

echo ""
echo "5️⃣ Verificando si los conflictos desaparecieron..."
CONFLICTS=$(docker service logs traefik --tail 20 | grep -iE "cannot be linked automatically|multiple Services" | wc -l)

if [ "$CONFLICTS" -eq 0 ]; then
    echo "✅ No se detectaron conflictos después del reinicio"
else
    echo "⚠️  Aún hay conflictos (puede ser caché antiguo):"
    docker service logs traefik --tail 20 | grep -iE "cannot be linked automatically|multiple Services" | tail -3
    echo ""
    echo "   Espera 1-2 minutos más y verifica de nuevo"
fi

echo ""
echo "6️⃣ Probando acceso al endpoint desde el navegador..."
echo "   Abre: https://dashboard.checkin24hs.com/api/version"
echo "   Deberías ver: {\"version\":\"2.1.0\",\"buildTimestamp\":null,\"timestamp\":\"...\"}"
echo ""

echo "=========================================="
echo "✅ Proceso completado"
echo "=========================================="
echo ""
echo "Si el endpoint aún no funciona después del reinicio:"
echo "  1. Espera 1-2 minutos más (Traefik puede tardar en actualizar)"
echo "  2. Verifica en EasyPanel que el dominio esté configurado correctamente"
echo "  3. Verifica que no haya restricciones en las rutas en EasyPanel"
echo ""
