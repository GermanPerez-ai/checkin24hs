#!/bin/bash
# Deshabilitar detección automática de Traefik y configurar manualmente

echo "=========================================="
echo "🔧 Deshabilitando detección automática de Traefik"
echo "=========================================="
echo ""

# 1. Verificar configuración actual de Traefik
echo "1️⃣ Verificando configuración de Traefik..."
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.ID}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ No se encontró contenedor de Traefik"
    exit 1
fi

echo "Contenedor Traefik: $TRAEFIK_CONTAINER"
echo ""

# 2. Ver configuración actual
echo "2️⃣ Verificando si Traefik tiene detección automática habilitada..."
docker exec "$TRAEFIK_CONTAINER" cat /etc/traefik/traefik.yml 2>/dev/null | grep -iE "docker|exposedbydefault|autodetect" || echo "No se encontró configuración explícita"

echo ""
echo "3️⃣ El problema es que Traefik está detectando automáticamente servicios"
echo "   y creando routers basados en los nombres de los servicios."
echo ""
echo "   Solución: Configurar explícitamente los routers con nombres únicos"
echo ""

# 3. Configurar dashboard con router explícito y único
echo "4️⃣ Configurando dashboard con router explícito..."
DASHBOARD_SERVICE="checkin24hs_dashboard"

# Primero, asegurarnos de que no hay etiquetas automáticas
docker service update \
  --label-rm "traefik.enable" \
  --label-rm "traefik.http.routers.dashboard.rule" \
  --label-rm "traefik.http.routers.dashboard.entrypoints" \
  --label-rm "traefik.http.routers.dashboard.tls" \
  --label-rm "traefik.http.routers.dashboard.tls.certresolver" \
  --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
  --label-rm "traefik.http.routers.dashboard-main.rule" \
  --label-rm "traefik.http.routers.dashboard-main.entrypoints" \
  --label-rm "traefik.http.routers.dashboard-main.tls" \
  --label-rm "traefik.http.routers.dashboard-main.tls.certresolver" \
  --label-rm "traefik.http.services.dashboard-main.loadbalancer.server.port" \
  "$DASHBOARD_SERVICE" 2>/dev/null || echo "Algunas etiquetas no existían"

sleep 5

# Agregar etiquetas con router único y explícito
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=web" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.dashboard-checkin24hs.tls=true" \
  --label-add "traefik.http.services.dashboard-checkin24hs.loadbalancer.server.port=3000" \
  "$DASHBOARD_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Dashboard configurado con router único: dashboard-checkin24hs"
else
    echo "❌ Error al configurar dashboard"
    exit 1
fi

# 4. Configurar CRM con router único (si es necesario)
echo ""
echo "5️⃣ Verificando si el CRM necesita configuración..."
CRM_SERVICE="checkin24hs_crm"

# Verificar si el CRM tiene dominio configurado
CRM_DOMAIN=$(docker service inspect "$CRM_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' 2>/dev/null | grep -i "domain\|host" || echo "")

if [ ! -z "$CRM_DOMAIN" ]; then
    echo "⚠️  El CRM tiene configuración de dominio"
    echo "   Asegurándonos de que tenga router único..."
    
    docker service update \
      --label-rm "traefik.enable" \
      --label-rm "traefik.http.routers.crm.rule" \
      --label-rm "traefik.http.routers.crm.entrypoints" \
      --label-rm "traefik.http.routers.crm.tls" \
      --label-rm "traefik.http.routers.crm.tls.certresolver" \
      --label-rm "traefik.http.services.crm.loadbalancer.server.port" \
      --label-rm "traefik.http.routers.dashboard.rule" \
      --label-rm "traefik.http.routers.dashboard.entrypoints" \
      --label-rm "traefik.http.routers.dashboard.tls" \
      --label-rm "traefik.http.routers.dashboard.tls.certresolver" \
      --label-rm "traefik.http.services.dashboard.loadbalancer.server.port" \
      "$CRM_SERVICE" 2>/dev/null || echo "Algunas etiquetas no existían"
    
    echo "✅ Etiquetas conflictivas del CRM eliminadas"
else
    echo "ℹ️  El CRM no tiene configuración de dominio, no necesita etiquetas Traefik"
fi

# 5. Esperar y verificar
echo ""
echo "6️⃣ Esperando 30 segundos para que Traefik detecte los cambios..."
sleep 30

echo ""
echo "7️⃣ Verificando logs de Traefik..."
docker service logs traefik --tail 30 | grep -iE "error|dashboard|router" | tail -10

echo ""
echo "8️⃣ Verificando si hay conflictos..."
CONFLICTS=$(docker service logs traefik --tail 20 | grep -iE "cannot be linked automatically|multiple Services" | wc -l)

if [ "$CONFLICTS" -eq 0 ]; then
    echo "✅ No se detectaron conflictos"
else
    echo "⚠️  Aún hay conflictos (puede ser caché antiguo):"
    docker service logs traefik --tail 20 | grep -iE "cannot be linked automatically|multiple Services" | tail -3
    echo ""
    echo "   Si persisten, espera 1-2 minutos más y verifica de nuevo"
fi

# 6. Verificar configuración final
echo ""
echo "9️⃣ Verificando configuración final..."
echo ""
echo "--- Dashboard ---"
docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep -i traefik

echo ""
echo "=========================================="
echo "✅ Configuración completada"
echo "=========================================="
echo ""
echo "Dashboard configurado con router: dashboard-checkin24hs"
echo "Dominio: dashboard.checkin24hs.com"
echo ""
echo "Espera 1-2 minutos y prueba acceder a:"
echo "  https://dashboard.checkin24hs.com"
echo ""
