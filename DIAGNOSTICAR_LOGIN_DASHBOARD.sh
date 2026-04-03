#!/bin/bash

echo "=========================================="
echo "🔍 DIAGNOSTICANDO LOGIN DEL DASHBOARD"
echo "=========================================="
echo ""

# 1. Verificar contenedor del dashboard
echo "1️⃣ Contenedor del Dashboard:"
echo "----------------------------------------"
DASHBOARD_CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "⚠️  No se encontró contenedor con 'checkin24hs_dashboard'"
    echo "   Buscando otros contenedores de dashboard..."
    DASHBOARD_CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
fi

if [ -z "$DASHBOARD_CONTAINER" ]; then
    echo "❌ No se encontró contenedor del dashboard"
    echo ""
    echo "Contenedores activos:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | head -10
    exit 1
fi

echo "✅ Contenedor encontrado: $DASHBOARD_CONTAINER"
docker ps --filter "id=$DASHBOARD_CONTAINER" --format "table {{.ID}}\t{{.Status}}\t{{.Names}}"
echo ""

# 2. Verificar logs recientes
echo "2️⃣ Logs recientes del dashboard:"
echo "----------------------------------------"
docker logs "$DASHBOARD_CONTAINER" --tail 30 2>&1 | tail -30
echo ""

# 3. Verificar si el servidor está respondiendo
echo "3️⃣ Verificando respuesta del servidor:"
echo "----------------------------------------"
echo "📊 Probando acceso interno (puerto 3000):"
docker exec "$DASHBOARD_CONTAINER" sh -c "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost:3000 2>&1 || echo '⚠️  curl no disponible o puerto diferente'"
echo ""

# 4. Verificar acceso externo
echo "4️⃣ Verificando acceso externo:"
echo "----------------------------------------"
echo "🌐 https://dashboard.checkin24hs.com/:"
EXTERNAL_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" https://dashboard.checkin24hs.com/ 2>&1)
echo "   HTTP Status: $EXTERNAL_STATUS"

if [ "$EXTERNAL_STATUS" = "200" ]; then
    echo "   ✅ Dashboard accesible"
    echo ""
    echo "   📄 Contenido (primeras 500 caracteres):"
    curl -s -k https://dashboard.checkin24hs.com/ | head -c 500
    echo ""
elif [ "$EXTERNAL_STATUS" = "502" ] || [ "$EXTERNAL_STATUS" = "503" ]; then
    echo "   ❌ Bad Gateway / Service Unavailable"
    echo "   💡 El servidor puede estar caído o reiniciando"
elif [ "$EXTERNAL_STATUS" = "404" ]; then
    echo "   ❌ Not Found"
    echo "   💡 Verifica la configuración de Traefik"
else
    echo "   ⚠️  Estado inesperado: $EXTERNAL_STATUS"
fi
echo ""

# 5. Verificar archivo dashboard.html en el contenedor
echo "5️⃣ Verificando archivo dashboard.html:"
echo "----------------------------------------"
DASHBOARD_PATHS=(
    "/app/dashboard.html"
    "/usr/share/nginx/html/dashboard.html"
    "/app/deploy/dashboard.html"
    "/var/www/html/dashboard.html"
)

FOUND_PATH=""
for path in "${DASHBOARD_PATHS[@]}"; do
    if docker exec "$DASHBOARD_CONTAINER" sh -c "test -f $path" 2>/dev/null; then
        echo "✅ Archivo encontrado en: $path"
        FOUND_PATH="$path"
        
        # Verificar que contiene la función handleLogin
        if docker exec "$DASHBOARD_CONTAINER" sh -c "grep -q 'function handleLogin' $path" 2>/dev/null; then
            echo "   ✅ Función handleLogin encontrada"
        else
            echo "   ⚠️  Función handleLogin NO encontrada"
        fi
        
        # Verificar que contiene la función showDashboard
        if docker exec "$DASHBOARD_CONTAINER" sh -c "grep -q 'function showDashboard' $path" 2>/dev/null; then
            echo "   ✅ Función showDashboard encontrada"
        else
            echo "   ⚠️  Función showDashboard NO encontrada"
        fi
        
        # Verificar tamaño del archivo
        FILE_SIZE=$(docker exec "$DASHBOARD_CONTAINER" sh -c "wc -l < $path" 2>/dev/null)
        echo "   📊 Líneas de código: $FILE_SIZE"
        break
    fi
done

if [ -z "$FOUND_PATH" ]; then
    echo "⚠️  No se encontró dashboard.html en las rutas comunes"
    echo "   Buscando en todo el contenedor..."
    docker exec "$DASHBOARD_CONTAINER" sh -c "find / -name 'dashboard.html' 2>/dev/null | head -5"
fi
echo ""

# 6. Verificar errores de JavaScript en el archivo
echo "6️⃣ Verificando posibles errores de sintaxis:"
echo "----------------------------------------"
if [ -n "$FOUND_PATH" ]; then
    # Buscar posibles problemas comunes
    echo "🔍 Buscando problemas comunes..."
    
    # Verificar paréntesis balanceados en handleLogin
    HANDLELOGIN_LINES=$(docker exec "$DASHBOARD_CONTAINER" sh -c "grep -n 'function handleLogin' $FOUND_PATH | head -1 | cut -d: -f1" 2>/dev/null)
    if [ -n "$HANDLELOGIN_LINES" ]; then
        echo "   ✅ handleLogin encontrado en línea $HANDLELOGIN_LINES"
        
        # Verificar que showDashboard está definida antes de handleLogin
        SHOWDASHBOARD_LINE=$(docker exec "$DASHBOARD_CONTAINER" sh -c "grep -n 'function showDashboard' $FOUND_PATH | head -1 | cut -d: -f1" 2>/dev/null)
        if [ -n "$SHOWDASHBOARD_LINE" ]; then
            if [ "$SHOWDASHBOARD_LINE" -lt "$HANDLELOGIN_LINES" ]; then
                echo "   ✅ showDashboard definida ANTES de handleLogin (correcto)"
            else
                echo "   ⚠️  showDashboard definida DESPUÉS de handleLogin (puede causar problemas)"
            fi
        fi
    fi
fi
echo ""

# 7. Verificar configuración de Traefik
echo "7️⃣ Verificando Traefik para dashboard:"
echo "----------------------------------------"
DASHBOARD_SERVICE=$(docker service ls --filter "name=checkin24hs_dashboard" --format "{{.Name}}" | head -1)

if [ -z "$DASHBOARD_SERVICE" ]; then
    DASHBOARD_SERVICE=$(docker service ls --filter "name=dashboard" --format "{{.Name}}" | head -1)
fi

if [ -n "$DASHBOARD_SERVICE" ]; then
    echo "✅ Servicio encontrado: $DASHBOARD_SERVICE"
    TRAEFIK_LABELS=$(docker service inspect "$DASHBOARD_SERVICE" --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' 2>/dev/null | grep -E "traefik")
    
    if [ -z "$TRAEFIK_LABELS" ]; then
        echo "❌ No se encontraron labels de Traefik"
    else
        echo "✅ Labels de Traefik encontradas:"
        echo "$TRAEFIK_LABELS" | head -7
    fi
else
    echo "⚠️  No se encontró servicio Docker Swarm para dashboard"
fi
echo ""

echo "=========================================="
echo "💡 DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "Si el login no funciona, verifica:"
echo "  1. Que el archivo dashboard.html esté actualizado en el contenedor"
echo "  2. Que las funciones handleLogin y showDashboard estén definidas"
echo "  3. Que no haya errores de JavaScript en la consola del navegador"
echo "  4. Que Traefik esté configurado correctamente"
echo ""
echo "Para ver errores de JavaScript:"
echo "  1. Abre https://dashboard.checkin24hs.com/"
echo "  2. Presiona F12 para abrir DevTools"
echo "  3. Ve a la pestaña 'Console'"
echo "  4. Busca errores en rojo"
echo ""
