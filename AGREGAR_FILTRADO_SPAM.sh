#!/bin/bash

cd /root/checkin24hs

CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor: $CONTAINER"

# Crear backup
echo "Creando backup..."
docker exec "$CONTAINER" cp /app/dashboard.html /app/dashboard.html.backup

# Buscar la línea donde está el código de carga de chats
echo "Buscando ubicación para insertar código..."

# Primero, verificar si ya existe el código
if docker exec "$CONTAINER" grep -q "spamPatterns" /app/dashboard.html; then
    echo "✅ El código de filtrado ya existe en el archivo"
    exit 0
fi

# Buscar la línea después de "chats cargados desde Supabase"
LINE_NUM=$(docker exec "$CONTAINER" grep -n "chats cargados desde Supabase" /app/dashboard.html | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "❌ No se encontró la línea de referencia"
    exit 1
fi

echo "Línea encontrada: $LINE_NUM"

# Crear un script temporal dentro del contenedor para hacer la modificación
docker exec "$CONTAINER" bash -c 'cat > /tmp/add_filtering.sh << '\''EOFSCRIPT'\''
#!/bin/bash
FILE="/app/dashboard.html"
LINE_NUM='$LINE_NUM'

# Leer el archivo y agregar el código después de la línea encontrada
python3 << '\''PYEOF'\''
import sys

with open("/app/dashboard.html", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Buscar la línea después de "chats cargados desde Supabase"
insert_line = None
for i, line in enumerate(lines):
    if "chats cargados desde Supabase" in line:
        insert_line = i + 1
        break

if insert_line is None:
    print("No se encontró la línea de inserción")
    sys.exit(1)

# Código a insertar
filtering_code = """                
                // Debug: mostrar algunos chats antes del filtrado
                if (chats.length > 0) {
                    console.log('\''🔍 Primeros 3 chats antes del filtrado:'\'', chats.slice(0, 3).map(c => ({
                        id: c.id,
                        name: c.users?.name || c.name,
                        phone: c.phone,
                        from: c.from
                    })));
                }
                
                // Filtrar chats por números de WhatsApp configurados Y excluir spam
                const originalCount = chats.length;
                chats = chats.filter(chat => {
                    // EXCLUIR chats de spam (status@broadcast, broadcast, etc.)
                    // Verificar en múltiples campos posibles
                    const userName = String(chat.users?.name || chat.name || chat.phone || chat.contact_name || '\''\'\'').toLowerCase();
                    const chatPhone = String(chat.phone || chat.from || chat.contact_phone || '\''\'\'').toLowerCase();
                    const chatId = String(chat.id || '\''\'\'').toLowerCase();
                    const chatFrom = String(chat.from || chat.from_number || '\''\'\'').toLowerCase();
                    
                    // Patrones de spam a excluir
                    const spamPatterns = ['\''status@broadcast'\'', '\''broadcast'\'', '\''status.broadcast'\''];
                    const isSpam = spamPatterns.some(pattern => 
                        userName.includes(pattern) || 
                        chatPhone.includes(pattern) ||
                        chatFrom.includes(pattern) ||
                        chatId.includes(pattern)
                    );
                    
                    if (isSpam) {
                        console.log('\''🚫 Chat spam excluido:'\'', { userName, chatPhone, chatFrom, chatId });
                        return false;
                    }
                    
                    // Si hay números configurados, filtrar por ellos
                    if (configuredNumbers.length > 0) {
                        const normalizedPhone = chat.phone ? chat.phone.replace(/\\D/g, '\''\'\'') : '\''\'\'';
                        const normalizedFrom = chat.from ? chat.from.replace(/\\D/g, '\''\'\'') : '\''\'\'';
                        const normalizedTo = chat.to ? chat.to.replace(/\\D/g, '\''\'\'') : '\''\'\'';
                        
                        // Verificar si el número del chat coincide con alguno configurado
                        const matches = configuredNumbers.some(configured => {
                            return normalizedPhone.includes(configured) || 
                                   normalizedFrom.includes(configured) || 
                                   normalizedTo.includes(configured) ||
                                   configured.includes(normalizedPhone) ||
                                   configured.includes(normalizedFrom) ||
                                   configured.includes(normalizedTo);
                        });
                        
                        return matches;
                    }
                    
                    // Si no hay números configurados, mostrar todos excepto spam
                    return true;
                });
                console.log(`🔍 Chats filtrados: ${originalCount} -> ${chats.length} (excluyendo spam y filtrando por números configurados)`);
                
                // Debug: mostrar algunos chats después del filtrado
                if (chats.length > 0) {
                    console.log('\''✅ Primeros 3 chats después del filtrado:'\'', chats.slice(0, 3).map(c => ({
                        id: c.id,
                        name: c.users?.name || c.name,
                        phone: c.phone,
                        from: c.from
                    })));
                }
"""

# Insertar el código después de la línea encontrada
lines.insert(insert_line, filtering_code)

# Escribir el archivo modificado
with open("/app/dashboard.html", "w", encoding="utf-8") as f:
    f.writelines(lines)

print(f"Código insertado después de la línea {insert_line}")
PYEOF
EOFSCRIPT
chmod +x /tmp/add_filtering.sh
'

# Ejecutar el script dentro del contenedor
docker exec "$CONTAINER" bash /tmp/add_filtering.sh

# Verificar que se agregó
if docker exec "$CONTAINER" grep -q "spamPatterns" /app/dashboard.html; then
    echo "✅ Código agregado correctamente"
    
    # Reiniciar Node.js
    echo "Reiniciando Node.js..."
    docker exec "$CONTAINER" pkill -9 -f "node.*server.js" 2>/dev/null || true
    sleep 3
    
    echo "✅ Proceso completado"
else
    echo "❌ Error: El código no se agregó correctamente"
    echo "Restaurando backup..."
    docker exec "$CONTAINER" cp /app/dashboard.html.backup /app/dashboard.html
    exit 1
fi




