#!/bin/bash
# Script para verificar sesiones activas de WhatsApp y posibles conflictos

echo "=========================================="
echo "VERIFICAR SESIONES ACTIVAS DE WHATSAPP"
echo "=========================================="
echo ""

# 1. Verificar contenedores de WhatsApp
echo "=== CONTENEDORES DE WHATSAPP ==="
echo ""
echo "Contenedores corriendo:"
docker ps | grep whatsapp
echo ""

echo "Todos los contenedores (incluyendo detenidos):"
docker ps -a | grep whatsapp
echo ""

# 2. Verificar procesos de Node.js relacionados con WhatsApp
echo "=== PROCESOS DE NODE.JS ==="
echo ""
echo "Procesos node relacionados con whatsapp:"
ps aux | grep -i "whatsapp\|baileys" | grep -v grep
echo ""

# 3. Verificar archivos de autenticación
echo "=== ARCHIVOS DE AUTENTICACIÓN ==="
echo ""
CONTAINER_ID=$(docker ps | grep whatsapp | grep -v nginx | awk '{print $1}' | head -1)
if [ -n "$CONTAINER_ID" ]; then
    echo "Contenedor: $CONTAINER_ID"
    echo ""
    echo "Archivos de autenticación en el contenedor:"
    docker exec $CONTAINER_ID ls -la /app/auth_info_baileys_* 2>/dev/null || echo "No se encontraron archivos de autenticación"
    echo ""
    
    # Verificar si hay múltiples instancias
    echo "Número de instancias configuradas:"
    docker exec $CONTAINER_ID ls -d /app/auth_info_baileys_* 2>/dev/null | wc -l
    echo ""
else
    echo "⚠️ No se encontró contenedor de WhatsApp corriendo"
fi
echo ""

# 4. Verificar logs recientes de conflictos
echo "=== LOGS DE CONFLICTOS RECIENTES ==="
echo ""
if [ -n "$CONTAINER_ID" ]; then
    echo "Últimos errores de conflicto (últimas 10 ocurrencias):"
    docker logs $CONTAINER_ID --tail 500 | grep -i "conflict\|Stream Errored" | tail -10
    echo ""
    
    echo "Última conexión exitosa:"
    docker logs $CONTAINER_ID --tail 100 | grep -i "WhatsApp conectado exitosamente" | tail -1
    echo ""
    
    echo "Estado actual de la conexión:"
    docker logs $CONTAINER_ID --tail 20 | grep -iE "conectado|connecting|close|open" | tail -5
    echo ""
else
    echo "⚠️ No se puede verificar logs (contenedor no encontrado)"
fi
echo ""

# 5. Verificar si hay múltiples servicios Docker
echo "=== SERVICIOS DOCKER SWARM ==="
echo ""
echo "Servicios de WhatsApp:"
docker service ls | grep whatsapp 2>/dev/null || echo "No se encontraron servicios Docker Swarm"
echo ""

# 6. Verificar puertos en uso
echo "=== PUERTOS EN USO ==="
echo ""
echo "Puerto 3001 (WhatsApp):"
netstat -tuln | grep 3001 || ss -tuln | grep 3001 || echo "No se puede verificar (comando no disponible)"
echo ""

echo "=========================================="
echo "RECOMENDACIONES"
echo "=========================================="
echo ""
echo "Si el error de conflicto persiste:"
echo "1. Verifica en tu teléfono: WhatsApp → Configuración → Dispositivos vinculados"
echo "2. Cierra TODAS las sesiones de WhatsApp Web/Desktop"
echo "3. Espera 2-3 minutos"
echo "4. Verifica los logs nuevamente: docker logs $CONTAINER_ID -f"
echo ""
echo "Si hay múltiples contenedores o instancias:"
echo "- Detén las instancias duplicadas"
echo "- Asegúrate de que solo haya UNA instancia de WhatsApp corriendo"
echo ""
