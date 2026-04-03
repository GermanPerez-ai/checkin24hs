#!/bin/bash
# Verificar servicios de WhatsApp después de crearlos

echo "=== Verificación de Servicios WhatsApp ==="
echo ""

# Configuración esperada
declare -A EXPECTED=(
    ["whatsapp1"]="3001"
    ["whatsapp2"]="3002"
    ["whatsapp3"]="3003"
    ["whatsapp4"]="3004"
)

# Contadores
TOTAL=0
CORRECTOS=0
INCORRECTOS=0

echo "1️⃣ Verificando servicios..."
echo ""

for service_name in "${!EXPECTED[@]}"; do
    EXPECTED_PORT=${EXPECTED[$service_name]}
    TOTAL=$((TOTAL + 1))
    
    # Buscar servicio
    FOUND_SERVICE=$(docker service ls --format "{{.Name}}" | grep -iE "^checkin24hs_${service_name}$|${service_name}$" | head -1)
    
    if [ ! -z "$FOUND_SERVICE" ]; then
        # Obtener puerto
        ACTUAL_PORT=$(docker service inspect $FOUND_SERVICE --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}' 2>/dev/null)
        
        # Obtener estado
        STATUS=$(docker service ps $FOUND_SERVICE --format "{{.CurrentState}}" | head -1)
        
        # Verificar puerto
        if [ "$ACTUAL_PORT" = "$EXPECTED_PORT" ]; then
            echo "✅ $service_name:"
            echo "   Servicio: $FOUND_SERVICE"
            echo "   Puerto: $ACTUAL_PORT (correcto)"
            echo "   Estado: $STATUS"
            CORRECTOS=$((CORRECTOS + 1))
        else
            echo "⚠️  $service_name:"
            echo "   Servicio: $FOUND_SERVICE"
            echo "   Puerto: $ACTUAL_PORT (esperado: $EXPECTED_PORT)"
            echo "   Estado: $STATUS"
            INCORRECTOS=$((INCORRECTOS + 1))
        fi
        
        # Verificar red
        NETWORKS=$(docker service inspect $FOUND_SERVICE --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}' 2>/dev/null)
        if echo "$NETWORKS" | grep -q "easypanel"; then
            echo "   Red: ✅ easypanel"
        else
            echo "   Red: ⚠️  NO en easypanel"
        fi
        
        # Verificar variables de entorno
        INSTANCE_VAR=$(docker service inspect $FOUND_SERVICE --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "INSTANCE_NUMBER")
        if [ ! -z "$INSTANCE_VAR" ]; then
            echo "   Variables: ✅ INSTANCE_NUMBER configurado"
        else
            echo "   Variables: ⚠️  INSTANCE_NUMBER NO encontrado"
        fi
        
    else
        echo "❌ $service_name:"
        echo "   Servicio NO encontrado"
        echo "   Puerto esperado: $EXPECTED_PORT"
        INCORRECTOS=$((INCORRECTOS + 1))
    fi
    
    echo ""
done

echo "2️⃣ Resumen:"
echo "   Total esperado: $TOTAL"
echo "   Correctos: $CORRECTOS"
echo "   Incorrectos/Faltantes: $INCORRECTOS"
echo ""

if [ $CORRECTOS -eq $TOTAL ]; then
    echo "✅ ¡Todos los servicios están correctamente configurados!"
    echo ""
    echo "Próximos pasos:"
    echo "   1. Ejecutar: bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh"
    echo "   2. Configurar DNS para los 4 dominios"
else
    echo "⚠️  Hay servicios faltantes o mal configurados"
    echo ""
    echo "Revisa la configuración en EasyPanel:"
    echo "   - Verifica que los nombres de servicio sean correctos"
    echo "   - Verifica que los puertos coincidan"
    echo "   - Verifica que las variables de entorno estén configuradas"
fi

echo ""
echo "3️⃣ Ver todos los servicios de WhatsApp:"
docker service ls | grep -i whatsapp || echo "   No se encontraron servicios"






