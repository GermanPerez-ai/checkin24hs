#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 CORRECCIÓN DEFINITIVA DEL CÓDIGO"
echo "=========================================="
echo ""

WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "🔧 Corrigiendo: $CONTAINER"
    
    # Hacer backup
    docker exec "$CONTAINER" cp /app/whatsapp-server.js /app/whatsapp-server.js.backup.$(date +%s)
    
    # Crear un script temporal dentro del contenedor para hacer la corrección
    docker exec "$CONTAINER" bash -c 'cat > /tmp/fix_insert.js << "FIXEOF"
const fs = require("fs");
const filePath = "/app/whatsapp-server.js";
let content = fs.readFileSync(filePath, "utf8");

// Buscar y reemplazar el bloque completo de insert
const oldPattern = /\.insert\(\[\{\s*chat_id: chat\?\.id \|\| null,\s*phone: cleanPhone,\s*message: message,\s*message_type: messageType,\s*is_from_me: isFromMe,\s*is_read: isFromMe,\s*whatsapp_instance: CONFIG\.INSTANCE_NUMBER\s*\}\]\)/gs;

const newCode = `.insert([{
                chat_id: chat?.id || null,
                body: message || "",
                is_from_me: isFromMe,
                is_read: isFromMe,
                created_at: new Date().toISOString()
            }])`;

if (oldPattern.test(content)) {
    content = content.replace(oldPattern, newCode);
    fs.writeFileSync(filePath, content, "utf8");
    console.log("✅ Código corregido exitosamente");
} else {
    // Intentar con variaciones del patrón
    const patterns = [
        /\.insert\(\[\{\s*chat_id:.*?whatsapp_instance:.*?\}\]\)/gs,
        /\.insert\(\[\{[^}]+\}\]\)/gs
    ];
    
    let replaced = false;
    for (const pattern of patterns) {
        if (pattern.test(content)) {
            // Buscar el bloque completo manualmente
            const lines = content.split("\n");
            let inInsert = false;
            let startLine = -1;
            let endLine = -1;
            
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].includes(".insert([{") && lines[i].includes("whatsapp_messages")) {
                    inInsert = true;
                    startLine = i;
                }
                if (inInsert && lines[i].includes("}]")) {
                    endLine = i;
                    break;
                }
            }
            
            if (startLine >= 0 && endLine >= 0) {
                const before = lines.slice(0, startLine).join("\n");
                const after = lines.slice(endLine + 1).join("\n");
                content = before + "\n" + newCode + "\n" + after;
                fs.writeFileSync(filePath, content, "utf8");
                console.log("✅ Código corregido exitosamente (método alternativo)");
                replaced = true;
                break;
            }
        }
    }
    
    if (!replaced) {
        console.log("⚠️ No se encontró el patrón exacto, intentando reemplazo manual...");
        // Último recurso: buscar la función completa y reemplazarla
        content = content.replace(
            /(async function saveMessageToSupabase\([^)]+\)\s*\{[^}]*\.from\('whatsapp_messages'\)[^}]*\.insert\(\[)\{[^}]+\}(\]\)[^}]*)/gs,
            (match, before, after) => {
                return before + "{\n                chat_id: chat?.id || null,\n                body: message || \"\",\n                is_from_me: isFromMe,\n                is_read: isFromMe,\n                created_at: new Date().toISOString()\n            }" + after;
            }
        );
        fs.writeFileSync(filePath, content, "utf8");
        console.log("✅ Código corregido (método de último recurso)");
    }
}
FIXEOF
'
    
    # Ejecutar el script de corrección
    docker exec "$CONTAINER" node /tmp/fix_insert.js
    
    # Verificar el resultado
    echo "   📋 Verificando corrección:"
    docker exec "$CONTAINER" grep -A 8 "\.from('whatsapp_messages')" /app/whatsapp-server.js | grep -A 6 "\.insert"
    echo ""
done

echo "=========================================="
echo "🔄 REINICIANDO CONTENEDORES"
echo "=========================================="

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "🔄 Reiniciando: $CONTAINER"
    docker restart "$CONTAINER"
    sleep 3
done

echo ""
echo "✅ Proceso completado"






