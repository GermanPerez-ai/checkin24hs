# 🔍 Verificar Etiquetas de Traefik

## Problema:
- El dominio no aparece en los logs de Traefik
- Traefik puede no estar detectando el servicio dashboard-proxy

## Comandos para verificar:

```bash
# 1. Ver las etiquetas de Traefik del servicio dashboard-proxy
echo "=== Etiquetas del servicio dashboard-proxy ==="
docker service inspect checkin24hs_dashboard-proxy --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq

# 2. Ver todos los servicios que Traefik está detectando
echo ""
echo "=== Servicios detectados por Traefik ==="
docker service logs traefik --tail 200 | grep -i "dashboard" | head -20

# 3. Verificar si el servicio dashboard-proxy tiene las etiquetas correctas
echo ""
echo "=== Buscando etiquetas traefik en dashboard-proxy ==="
docker service inspect checkin24hs_dashboard-proxy | grep -A 20 "Labels" | grep -i traefik

# 4. Verificar la configuración del dominio en EasyPanel (desde Docker)
echo ""
echo "=== Verificando configuración del dominio ==="
docker service inspect checkin24hs_dashboard-proxy | grep -i "dashboard.checkin24hs.com" || echo "Dominio no encontrado en la configuración del servicio"
```
