#!/bin/bash
# Script para agregar los campos de Temperature y Max Tokens directamente en el servidor

cd /root/checkin24hs

echo "🔄 Actualizando campos de IA en dashboard.html..."

DASHBOARD_FILE="deploy/dashboard.html"

if [ ! -f "$DASHBOARD_FILE" ]; then
    echo "❌ No se encontró $DASHBOARD_FILE"
    exit 1
fi

# Verificar si ya tiene los campos
if grep -q "ai-temperature" "$DASHBOARD_FILE" 2>/dev/null; then
    echo "✅ El archivo ya tiene los campos de IA"
    exit 0
fi

echo "📝 Agregando campos de Temperature y Max Tokens..."

# Buscar la línea donde está el campo "Modelo" y agregar los nuevos campos después
# Buscar: </div> después del campo modelo (antes de los botones)

# Crear backup
cp "$DASHBOARD_FILE" "${DASHBOARD_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Usar sed para insertar los campos después de la línea del modelo
# Buscar la línea que tiene el cierre </div> después del campo modelo y antes de los botones

# Método más seguro: usar Python o crear un script temporal
python3 << 'PYTHON_SCRIPT'
import re
import sys

file_path = '/root/checkin24hs/deploy/dashboard.html'

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Buscar el patrón: cierre del div del modelo, seguido de los botones
    # Patrón: </div> (cierre del modelo) seguido de <div style="display: flex; gap: 12px;"> (botones)
    
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
    
    if re.search(pattern, content):
        new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print("✅ Campos agregados correctamente")
        sys.exit(0)
    else:
        print("❌ No se encontró el patrón para insertar los campos")
        print("Buscando ubicación alternativa...")
        
        # Intentar otro patrón: buscar donde está el input del modelo
        pattern2 = r'(<input type="text" id="ai-model"[^>]*>.*?</p>\s*</div>\s*)(<div style="display: flex;)'
        
        if re.search(pattern2, content):
            new_content = re.sub(pattern2, replacement, content, flags=re.DOTALL)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print("✅ Campos agregados correctamente (método alternativo)")
            sys.exit(0)
        else:
            print("❌ No se pudo encontrar la ubicación para insertar los campos")
            sys.exit(1)
            
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo "✅ Archivo actualizado"
    
    # Verificar que se agregaron
    if grep -q "ai-temperature" "$DASHBOARD_FILE"; then
        echo "✅ Campos verificados en el archivo"
        
        # Actualizar contenedor
        CONTAINER_ID=$(docker ps | grep dashboard | grep -v nginx | awk '{print $1}' | head -1)
        if [ -n "$CONTAINER_ID" ]; then
            echo "📤 Copiando al contenedor..."
            docker cp "$DASHBOARD_FILE" ${CONTAINER_ID}:/app/dashboard.html
            
            if docker exec ${CONTAINER_ID} grep -q "ai-temperature" /app/dashboard.html 2>/dev/null; then
                echo "✅ Campos copiados al contenedor"
                echo "🔄 Reiniciando contenedor..."
                docker restart ${CONTAINER_ID}
                sleep 10
                echo "✅ Actualización completa!"
            else
                echo "❌ Error al copiar al contenedor"
            fi
        fi
    else
        echo "❌ Los campos no se agregaron correctamente"
    fi
else
    echo "❌ Error al actualizar el archivo"
    exit 1
fi








