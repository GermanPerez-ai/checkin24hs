#!/bin/bash
# Diagnosticar por qué el contenedor CRM no se puede eliminar

echo "🔍 DIAGNOSTICAR CONTENEDOR CRM"
echo "=============================="
echo ""

CONTAINER_ID="631aff08d526"

# 1. Verificar información del contenedor
echo "1️⃣ Información del contenedor..."
echo ""
docker inspect $CONTAINER_ID 2>/dev/null | grep -E "State|Status|RestartCount" | head -10

echo ""

# 2. Verificar si está en algún stack o servicio
echo "2️⃣ Verificando servicios y stacks..."
echo ""
docker service ls --format "{{.Name}}" | while read service; do
    docker service ps $service --no-trunc 2>/dev/null | grep -q "$CONTAINER_ID" && echo "   Encontrado en servicio: $service"
done

echo ""

# 3. Verificar volúmenes asociados
echo "3️⃣ Verificando volúmenes..."
echo ""
docker inspect $CONTAINER_ID --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Type}}){{println}}{{end}}' 2>/dev/null

echo ""

# 4. Verificar redes asociadas
echo "4️⃣ Verificando redes..."
echo ""
docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{println}}{{end}}' 2>/dev/null

echo ""

# 5. Intentar eliminar con diferentes métodos
echo "5️⃣ Intentando eliminar..."
echo ""

# Método 1: Eliminar normalmente
echo "   Método 1: docker rm -f"
docker rm -f $CONTAINER_ID 2>&1

# Si falla, intentar otros métodos
if docker ps -a | grep -q "$CONTAINER_ID"; then
    echo ""
    echo "   Método 2: Eliminar desde el daemon directamente"
    docker container prune -f --filter "id=$CONTAINER_ID" 2>&1
fi

echo ""

# 6. Verificar estado final
echo "6️⃣ Estado final..."
echo ""
if docker ps -a | grep -q "$CONTAINER_ID"; then
    echo "   ⚠️  Contenedor aún existe"
    echo ""
    echo "   Información detallada:"
    docker inspect $CONTAINER_ID --format 'Estado: {{.State.Status}}' 2>/dev/null
    docker inspect $CONTAINER_ID --format 'RestartCount: {{.RestartCount}}' 2>/dev/null
    docker inspect $CONTAINER_ID --format 'Dead: {{.State.Dead}}' 2>/dev/null
else
    echo "   ✅ Contenedor eliminado"
fi

echo ""
echo "============================="
