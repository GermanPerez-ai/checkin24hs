#!/bin/bash

echo "🧹 LIMPIEZA COMPLETA DE EVOLUTION API"
echo "======================================"
echo ""

echo "1️⃣  Eliminando volúmenes restantes..."
echo ""

# Eliminar volúmenes restantes
for volume in evolution-api_postgres_data evolution-api_redis_data; do
    if docker volume ls | grep -q "$volume"; then
        echo "   🗑️  Eliminando volumen $volume..."
        docker volume rm "$volume" 2>/dev/null && echo "   ✅ Volumen eliminado" || echo "   ⚠️  No se pudo eliminar (puede estar en uso)"
    else
        echo "   ℹ️  Volumen $volume no existe"
    fi
done

echo ""
echo "2️⃣  Buscando contenedores de Evolution API..."
echo ""

# Buscar contenedores relacionados con Evolution API
EVOLUTION_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -i evolution)

if [ -z "$EVOLUTION_CONTAINERS" ]; then
    echo "   ✅ No hay contenedores de Evolution API"
else
    echo "   ⚠️  Contenedores encontrados:"
    echo "$EVOLUTION_CONTAINERS" | while read container; do
        echo "      - $container"
    done
    echo ""
    read -p "   ¿Deseas eliminar estos contenedores? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo "$EVOLUTION_CONTAINERS" | while read container; do
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
            echo "   ✅ $container eliminado"
        done
    fi
fi

echo ""
echo "3️⃣  Buscando volúmenes de Evolution API..."
echo ""

# Buscar volúmenes relacionados con Evolution API
EVOLUTION_VOLUMES=$(docker volume ls --format "{{.Name}}" | grep -i evolution)

if [ -z "$EVOLUTION_VOLUMES" ]; then
    echo "   ✅ No hay volúmenes de Evolution API"
else
    echo "   ⚠️  Volúmenes encontrados:"
    echo "$EVOLUTION_VOLUMES" | while read volume; do
        echo "      - $volume"
    done
    echo ""
    read -p "   ¿Deseas eliminar estos volúmenes? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo "$EVOLUTION_VOLUMES" | while read volume; do
            docker volume rm "$volume" 2>/dev/null && echo "   ✅ $volume eliminado" || echo "   ⚠️  No se pudo eliminar $volume (puede estar en uso)"
        done
    fi
fi

echo ""
echo "4️⃣  Buscando redes de Evolution API..."
echo ""

# Buscar redes relacionadas con Evolution API
EVOLUTION_NETWORKS=$(docker network ls --format "{{.Name}}" | grep -i evolution)

if [ -z "$EVOLUTION_NETWORKS" ]; then
    echo "   ✅ No hay redes de Evolution API"
else
    echo "   ⚠️  Redes encontradas:"
    echo "$EVOLUTION_NETWORKS" | while read network; do
        echo "      - $network"
    done
    echo ""
    read -p "   ¿Deseas eliminar estas redes? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo "$EVOLUTION_NETWORKS" | while read network; do
            docker network rm "$network" 2>/dev/null && echo "   ✅ $network eliminada" || echo "   ⚠️  No se pudo eliminar $network (puede estar en uso)"
        done
    fi
fi

echo ""
echo "5️⃣  Buscando imágenes de Evolution API..."
echo ""

# Buscar imágenes relacionadas con Evolution API
EVOLUTION_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i evolution)

if [ -z "$EVOLUTION_IMAGES" ]; then
    echo "   ✅ No hay imágenes de Evolution API"
else
    echo "   ⚠️  Imágenes encontradas:"
    echo "$EVOLUTION_IMAGES" | while read image; do
        echo "      - $image"
    done
    echo ""
    read -p "   ¿Deseas eliminar estas imágenes? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo "$EVOLUTION_IMAGES" | while read image; do
            docker rmi "$image" 2>/dev/null && echo "   ✅ $image eliminada" || echo "   ⚠️  No se pudo eliminar $image"
        done
    fi
fi

echo ""
echo "6️⃣  Buscando servicios Docker Swarm de Evolution API..."
echo ""

# Buscar servicios Docker Swarm
EVOLUTION_SERVICES=$(docker service ls --format "{{.Name}}" 2>/dev/null | grep -i evolution)

if [ -z "$EVOLUTION_SERVICES" ]; then
    echo "   ✅ No hay servicios Docker Swarm de Evolution API"
else
    echo "   ⚠️  Servicios encontrados:"
    echo "$EVOLUTION_SERVICES" | while read service; do
        echo "      - $service"
    done
    echo ""
    read -p "   ¿Deseas eliminar estos servicios? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo "$EVOLUTION_SERVICES" | while read service; do
            docker service rm "$service" 2>/dev/null && echo "   ✅ $service eliminado" || echo "   ⚠️  No se pudo eliminar $service"
        done
    fi
fi

echo ""
echo "7️⃣  Buscando procesos relacionados con Evolution API..."
echo ""

# Buscar procesos que contengan "evolution" en el nombre
EVOLUTION_PROCESSES=$(ps aux | grep -i evolution | grep -v grep)

if [ -z "$EVOLUTION_PROCESSES" ]; then
    echo "   ✅ No hay procesos de Evolution API corriendo"
else
    echo "   ⚠️  Procesos encontrados:"
    echo "$EVOLUTION_PROCESSES"
    echo ""
    echo "   ℹ️  Estos procesos pueden ser parte de otros servicios"
    echo "   Revisa manualmente si son de Evolution API"
fi

echo ""
echo "8️⃣  Verificando puertos utilizados por Evolution API..."
echo ""

# Puertos comunes de Evolution API
EVOLUTION_PORTS="8080 8081"

for port in $EVOLUTION_PORTS; do
    PORT_IN_USE=$(netstat -tuln 2>/dev/null | grep ":$port " || ss -tuln 2>/dev/null | grep ":$port ")
    if [ -n "$PORT_IN_USE" ]; then
        echo "   ⚠️  Puerto $port está en uso:"
        echo "$PORT_IN_USE" | head -3
    else
        echo "   ✅ Puerto $port no está en uso"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RESUMEN FINAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificación final
REMAINING_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -i evolution | wc -l)
REMAINING_VOLUMES=$(docker volume ls --format "{{.Name}}" | grep -i evolution | wc -l)
REMAINING_NETWORKS=$(docker network ls --format "{{.Name}}" | grep -i evolution | wc -l)
REMAINING_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -i evolution | wc -l)

echo "📊 Estado final:"
echo ""
echo "   Contenedores: $REMAINING_CONTAINERS"
echo "   Volúmenes: $REMAINING_VOLUMES"
echo "   Redes: $REMAINING_NETWORKS"
echo "   Imágenes: $REMAINING_IMAGES"
echo ""

if [ "$REMAINING_CONTAINERS" -eq 0 ] && [ "$REMAINING_VOLUMES" -eq 0 ] && [ "$REMAINING_NETWORKS" -eq 0 ]; then
    echo "✅ Evolution API completamente desinstalado"
else
    echo "⚠️  Aún quedan elementos de Evolution API"
    echo ""
    echo "Elementos restantes:"
    
    if [ "$REMAINING_CONTAINERS" -gt 0 ]; then
        echo "   Contenedores:"
        docker ps -a --format "{{.Names}}" | grep -i evolution | sed 's/^/      - /'
    fi
    
    if [ "$REMAINING_VOLUMES" -gt 0 ]; then
        echo "   Volúmenes:"
        docker volume ls --format "{{.Name}}" | grep -i evolution | sed 's/^/      - /'
    fi
    
    if [ "$REMAINING_NETWORKS" -gt 0 ]; then
        echo "   Redes:"
        docker network ls --format "{{.Name}}" | grep -i evolution | sed 's/^/      - /'
    fi
fi

echo ""
echo "✅ Limpieza completada"
echo ""
