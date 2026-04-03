#!/bin/bash

cd /root/checkin24hs

echo "🔍 Buscando el final correcto de la primera copia en el backup corrupto..."

# El archivo local tiene 23,289 líneas y termina con:
#     </div>
#     <!-- Fin del contenido del Dashboard -->
# </body>
# </html>

# Buscar todas las ocurrencias de </body> y </html> para encontrar el patrón
echo "Buscando todas las líneas con </body>:"
grep -n "</body>" deploy/dashboard.html.backup_20260108_001449

echo ""
echo "Buscando todas las líneas con </html>:"
grep -n "</html>" deploy/dashboard.html.backup_20260108_001449

echo ""
echo "🔍 El archivo local tiene 23,289 líneas"
echo "🔍 Verificando líneas 23,285-23,290 del backup corrupto:"
sed -n '23285,23290p' deploy/dashboard.html.backup_20260108_001449

echo ""
echo "🔍 Buscando el patrón correcto alrededor de línea 23,289..."

# Buscar si hay algo que indique el final de la primera copia
# El archivo local termina con:
# </script>
# </div>
# <!-- Fin del contenido del Dashboard -->
# </body>
# </html>

# Buscar la combinación de estas líneas
for line in $(seq 23285 23292); do
    line1=$(sed -n "${line}p" deploy/dashboard.html.backup_20260108_001449)
    line2=$(sed -n "$((line+1))p" deploy/dashboard.html.backup_20260108_001449)
    line3=$(sed -n "$((line+2))p" deploy/dashboard.html.backup_20260108_001449)
    line4=$(sed -n "$((line+3))p" deploy/dashboard.html.backup_20260108_001449)
    
    if echo "$line1" | grep -q "Fin del contenido del Dashboard" && \
       echo "$line2" | grep -q "</body>" && \
       echo "$line3" | grep -q "</html>"; then
        echo "✅ Encontrado patrón correcto en línea $line"
        echo "✂️ Extrayendo hasta línea $((line + 2))..."
        head -n $((line + 2)) deploy/dashboard.html.backup_20260108_001449 > deploy/dashboard.html
        
        echo "✅ Verificando archivo extraído:"
        HTML_COUNT=$(grep -c "<html" deploy/dashboard.html)
        HTML_CLOSE_COUNT=$(grep -c "</html>" deploy/dashboard.html)
        WHATSAPP_COUNT=$(grep -c "whatsapp-cards-container" deploy/dashboard.html)
        SHOWFLORTAB_COUNT=$(grep -c "window.showFlorTab" deploy/dashboard.html)
        LINES_COUNT=$(wc -l < deploy/dashboard.html)
        
        echo "  <html>: $HTML_COUNT"
        echo "  </html>: $HTML_CLOSE_COUNT"
        echo "  whatsapp-cards-container: $WHATSAPP_COUNT"
        echo "  window.showFlorTab: $SHOWFLORTAB_COUNT"
        echo "  Líneas: $LINES_COUNT"
        
        if [ "$HTML_COUNT" = "1" ] && [ "$HTML_CLOSE_COUNT" = "1" ] && [ "$WHATSAPP_COUNT" -gt 0 ] && [ "$SHOWFLORTAB_COUNT" -gt 0 ]; then
            echo ""
            echo "✅ Archivo completo y correcto"
            echo "📤 Copiando al contenedor..."
            CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
            DASHBOARD_PATH="/app/dashboard.html"
            docker exec $CONTAINER_ID test -f "$DASHBOARD_PATH" || DASHBOARD_PATH="/usr/share/nginx/html/dashboard.html"
            docker cp deploy/dashboard.html "${CONTAINER_ID}:${DASHBOARD_PATH}"
            
            echo "✅ Verificando en contenedor:"
            docker exec $CONTAINER_ID grep -c "<html" "$DASHBOARD_PATH"
            docker exec $CONTAINER_ID grep -c "</html>" "$DASHBOARD_PATH"
            docker exec $CONTAINER_ID grep -c "whatsapp-cards-container" "$DASHBOARD_PATH"
            
            echo "🔄 Reiniciando contenedor..."
            docker restart $CONTAINER_ID
            sleep 5
            echo "✅ Proceso completado"
            exit 0
        fi
    fi
done

echo "❌ No se encontró el patrón correcto. El backup corrupto no tiene la primera copia completa."
echo "   Necesitas copiar el archivo local correcto (23,289 líneas) directamente al servidor."


