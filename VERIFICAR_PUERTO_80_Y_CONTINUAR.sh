#!/bin/bash
# Verificar puerto 80 y continuar con la solución

echo "=== Verificando uso del puerto 80 ==="

# 1. Ver servicios que usan puerto 80 internamente
echo ""
echo "1. Servicios que usan puerto 80 internamente:"
docker service ls --format "{{.Name}}" | while read service; do
    PORTS=$(docker service inspect $service --format '{{range .Endpoint.Ports}}{{.TargetPort}} {{end}}' 2>/dev/null)
    if echo "$PORTS" | grep -q "80"; then
        echo "  - $service usa puerto 80 interno"
        docker service inspect $service --format '  Puertos: {{range .Endpoint.Ports}}{{.PublishedPort}}->{{.TargetPort}} {{end}}' 2>/dev/null
    fi
done

# 2. Ver contenedores que escuchan en puerto 80
echo ""
echo "2. Contenedores escuchando en puerto 80:"
docker ps --format "{{.Names}}\t{{.Ports}}" | grep ":80"

# 3. Verificar webmail específicamente
echo ""
echo "3. Configuración de webmail:"
docker service inspect checkin24hs_webmail --format 'Nombre: {{.Spec.Name}}
Puerto interno: {{range .Endpoint.Ports}}{{.TargetPort}} {{end}}
Puerto externo: {{range .Endpoint.Ports}}{{.PublishedPort}} {{end}}
Redes: {{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}' 2>/dev/null || echo "Servicio webmail no encontrado"

# 4. Verificar cotizador específicamente
echo ""
echo "4. Configuración de cotizador:"
docker service inspect cotizador --format 'Nombre: {{.Spec.Name}}
Puerto interno: {{range .Endpoint.Ports}}{{.TargetPort}} {{end}}
Puerto externo: {{range .Endpoint.Ports}}{{.PublishedPort}} {{end}}
Redes: {{range .Spec.TaskTemplate.Networks}}{{.Target}} {{end}}'

# 5. IMPORTANTE: El problema NO es el puerto 80, es la resolución de nombres
echo ""
echo "=========================================="
echo "IMPORTANTE: En Docker, NO hay conflicto"
echo "=========================================="
echo "Cada servicio puede usar puerto 80 INTERNO"
echo "El problema es que Traefik no resuelve 'cotizador'"
echo ""
echo "5. Solución: Usar el nombre completo del contenedor"
echo ""

# Obtener el nombre completo del contenedor cotizador
COTIZADOR_FULL_NAME=$(docker ps | grep cotizador | head -1 | awk '{print $NF}')
echo "Nombre completo del contenedor: $COTIZADOR_FULL_NAME"

# Obtener la IP del contenedor en la red easypanel
COTIZADOR_IP=$(docker inspect $(docker ps | grep cotizador | head -1 | awk '{print $1}') | grep -A 20 Networks | grep -A 5 '"easypanel"' | grep IPAddress | head -1 | awk '{print $2}' | tr -d '",')

echo "IP del contenedor: $COTIZADOR_IP"

# 6. Actualizar Traefik para usar el nombre completo del contenedor
echo ""
echo "6. Actualizando configuración de Traefik..."
echo "Opción A: Usar nombre completo del servicio"
echo "Opción B: Usar alias del servicio"
echo "Opción C: Usar IP directamente"
