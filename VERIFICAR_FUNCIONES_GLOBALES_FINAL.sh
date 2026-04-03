#!/bin/bash
echo "Verificando funciones globales..."
echo ""

for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do 
    echo "=== $container ==="
    
    SHOW_SECTION_LINE=$(docker exec $container grep -n "window.showSection = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
    SEARCH_USERS_LINE=$(docker exec $container grep -n "window.searchUsers = function" /app/dashboard.html 2>/dev/null | head -1 | cut -d: -f1)
    
    if [ ! -z "$SHOW_SECTION_LINE" ] && [ "$SHOW_SECTION_LINE" -lt 2000 ]; then
        echo "✅ showSection línea $SHOW_SECTION_LINE"
    else
        echo "⚠️ showSection línea $SHOW_SECTION_LINE"
    fi
    
    if [ ! -z "$SEARCH_USERS_LINE" ] && [ "$SEARCH_USERS_LINE" -lt 2000 ]; then
        echo "✅ searchUsers línea $SEARCH_USERS_LINE"
    else
        echo "⚠️ searchUsers línea $SEARCH_USERS_LINE"
    fi
    
    LINE_5150=$(docker exec $container sed -n '5150p' /app/dashboard.html 2>/dev/null)
    if echo "$LINE_5150" | grep -q "if (!dateValue)"; then
        echo "✅ Línea 5150 correcta"
    else
        echo "⚠️ Línea 5150: $LINE_5150"
    fi
    echo ""
done
