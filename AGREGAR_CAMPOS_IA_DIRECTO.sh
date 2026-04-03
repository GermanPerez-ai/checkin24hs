#!/bin/bash
# Script para agregar campos de IA directamente en el servidor usando sed

cd /root/checkin24hs

FILE="deploy/dashboard.html"

if [ ! -f "$FILE" ]; then
    echo "❌ No se encontró $FILE"
    exit 1
fi

# Verificar si ya tiene los campos
if grep -q "ai-temperature" "$FILE"; then
    echo "✅ El archivo ya tiene los campos"
    exit 0
fi

echo "📝 Agregando campos de Temperature y Max Tokens..."

# Backup
cp "$FILE" "${FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Buscar la línea con el cierre del div del modelo y agregar los campos antes de los botones
# Patrón: buscar </div> después de ai-model-help y antes de los botones

# Crear el código HTML de los nuevos campos
CAMPOS_IA='                                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px;">
                                    <div>
                                        <label style="display: block; font-weight: 500; margin-bottom: 8px;">Temperature</label>
                                        <input type="number" id="ai-temperature" value="0.7" min="0" max="2" step="0.1" style="width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px;">
                                        <p style="font-size: 0.8rem; color: #666; margin-top: 4px;">Balance creatividad/consistencia (0-2)</p>
                                    </div>
                                    <div>
                                        <label style="display: block; font-weight: 500; margin-bottom: 8px;">Max Tokens</label>
                                        <input type="number" id="ai-max-tokens" value="500" min="100" max="4000" step="50" style="width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px;">
                                        <p style="font-size: 0.8rem; color: #666; margin-top: 4px;">Longitud máxima de respuesta</p>
                                    </div>
                                </div>'

# Buscar la línea que tiene el cierre del div del modelo (después de ai-model-help)
# e insertar los campos antes de la línea con los botones

# Método: usar awk para insertar después de encontrar el patrón
awk -v campos="$CAMPOS_IA" '
/ai-model-help/ {
    print
    getline
    print
    # Buscar el cierre del div del modelo
    while (getline > 0) {
        if (/display: flex; gap: 12px/) {
            # Insertar los campos antes de los botones
            print campos
            print
            break
        }
        print
    }
    next
}
{ print }
' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

# Verificar
if grep -q "ai-temperature" "$FILE"; then
    echo "✅ Campos agregados correctamente"
    
    # Actualizar contenedor
    CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
    if [ -n "$CONTAINER_ID" ]; then
        echo "📤 Copiando al contenedor $CONTAINER_ID..."
        docker cp "$FILE" ${CONTAINER_ID}:/app/dashboard.html
        
        if docker exec ${CONTAINER_ID} grep -q "ai-temperature" /app/dashboard.html 2>/dev/null; then
            echo "✅ Campos copiados al contenedor"
            docker restart ${CONTAINER_ID}
            sleep 10
            echo "✅ ¡Actualización completa! Limpia la caché del navegador (Ctrl+Shift+R)"
        else
            echo "❌ Error al copiar"
        fi
    fi
else
    echo "❌ No se pudieron agregar los campos. Intentando método alternativo..."
    
    # Método alternativo: usar Python si está disponible
    if command -v python3 &> /dev/null; then
        python3 << 'PYEOF'
import re

file_path = '/root/checkin24hs/deploy/dashboard.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Buscar patrón: cierre del div del modelo antes de los botones
pattern = r'(<p id="ai-model-help"[^>]*>.*?</p>\s*</div>\s*)(<div style="display: flex; gap: 12px;">)'

replacement = r'''\1<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px;">
                                    <div>
                                        <label style="display: block; font-weight: 500; margin-bottom: 8px;">Temperature</label>
                                        <input type="number" id="ai-temperature" value="0.7" min="0" max="2" step="0.1" style="width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px;">
                                        <p style="font-size: 0.8rem; color: #666; margin-top: 4px;">Balance creatividad/consistencia (0-2)</p>
                                    </div>
                                    <div>
                                        <label style="display: block; font-weight: 500; margin-bottom: 8px;">Max Tokens</label>
                                        <input type="number" id="ai-max-tokens" value="500" min="100" max="4000" step="50" style="width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px;">
                                        <p style="font-size: 0.8rem; color: #666; margin-top: 4px;">Longitud máxima de respuesta</p>
                                    </div>
                                </div>
\2'''

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

if 'ai-temperature' in new_content:
    print("✅ Campos agregados con Python")
    exit(0)
else:
    print("❌ Error con Python también")
    exit(1)
PYEOF

        if [ $? -eq 0 ]; then
            CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
            docker cp "$FILE" ${CONTAINER_ID}:/app/dashboard.html
            docker restart ${CONTAINER_ID}
            echo "✅ Actualización completa!"
        fi
    else
        echo "❌ No se pudo agregar los campos. Necesitas subir el archivo completo."
    fi
fi








