#!/bin/bash
# Script para aplicar archivos corregidos a todos los contenedores de dashboard y CRM

cd /root/checkin24hs

echo "🔍 Buscando contenedores de Dashboard y CRM..."
echo ""

# Obtener todos los contenedores de dashboard
DASHBOARD_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -i "checkin24hs_dashboard")

# Obtener todos los contenedores de CRM
CRM_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -i "checkin24hs_crm")

# Función para copiar archivo a un contenedor
copy_to_container() {
    local container=$1
    local file=$2
    local dest_paths=("$3" "$4" "$5")
    
    echo "   📦 Intentando copiar a $container..."
    
    for dest in "${dest_paths[@]}"; do
        if docker cp "$file" "$container:$dest" 2>/dev/null; then
            echo "   ✅ Copiado exitosamente a $dest"
            return 0
        fi
    done
    
    echo "   ⚠️ No se pudo copiar a ninguna ruta"
    return 1
}

# Procesar contenedores de Dashboard
if [ ! -z "$DASHBOARD_CONTAINERS" ]; then
    echo "📊 Contenedores de Dashboard encontrados:"
    echo "$DASHBOARD_CONTAINERS" | while read container; do
        echo "  - $container"
    done
    echo ""
    
    echo "📤 Copiando dashboard.html a contenedores de Dashboard..."
    echo "$DASHBOARD_CONTAINERS" | while read container; do
        copy_to_container "$container" "/root/checkin24hs/deploy/dashboard.html" \
            "/usr/share/nginx/html/dashboard.html" \
            "/app/dashboard.html" \
            "/var/www/html/dashboard.html"
    done
    echo ""
    
    echo "🔄 Reiniciando contenedores de Dashboard..."
    echo "$DASHBOARD_CONTAINERS" | while read container; do
        echo "   Reiniciando $container..."
        docker restart "$container" 2>/dev/null && echo "   ✅ $container reiniciado" || echo "   ❌ Error reiniciando $container"
    done
    echo ""
else
    echo "⚠️ No se encontraron contenedores de Dashboard"
    echo ""
fi

# Procesar contenedores de CRM
if [ ! -z "$CRM_CONTAINERS" ]; then
    echo "📊 Contenedores de CRM encontrados:"
    echo "$CRM_CONTAINERS" | while read container; do
        echo "  - $container"
    done
    echo ""
    
    echo "📤 Copiando crm.html y crm.js a contenedores de CRM..."
    echo "$CRM_CONTAINERS" | while read container; do
        echo "   Procesando $container..."
        
        # Copiar crm.html
        copy_to_container "$container" "/root/checkin24hs/deploy/crm.html" \
            "/usr/share/nginx/html/crm.html" \
            "/app/crm.html" \
            "/var/www/html/crm.html"
        
        # Copiar crm.js
        copy_to_container "$container" "/root/checkin24hs/deploy/crm.js" \
            "/usr/share/nginx/html/crm.js" \
            "/app/crm.js" \
            "/var/www/html/crm.js"
    done
    echo ""
    
    echo "🔄 Reiniciando contenedores de CRM..."
    echo "$CRM_CONTAINERS" | while read container; do
        echo "   Reiniciando $container..."
        docker restart "$container" 2>/dev/null && echo "   ✅ $container reiniciado" || echo "   ❌ Error reiniciando $container"
    done
    echo ""
else
    echo "⚠️ No se encontraron contenedores de CRM"
    echo ""
fi

echo "✅ Proceso completado!"
echo ""
echo "🌐 Verifica los cambios en:"
echo "   - https://dashboard.checkin24hs.com/"
echo "   - https://crm.checkin24hs.com/"
echo ""
echo "💡 Limpia la caché del navegador (Ctrl + Shift + R)"




