#!/bin/bash

cd /root/checkin24hs

echo "=========================================="
echo "🔧 CORRECCIÓN CON NODE.JS"
echo "=========================================="
echo ""

WHATSAPP_CONTAINERS=($(docker ps --filter "name=whatsapp" --format "{{.Names}}"))

for CONTAINER in "${WHATSAPP_CONTAINERS[@]}"; do
    echo "🔧 Corrigiendo: $CONTAINER"
    
    # Crear script Node.js para hacer el reemplazo
    docker exec "$CONTAINER" bash -c 'cat > /tmp/fix_code.js << "NODEEOF"
const fs = require("fs");
const path = "/app/whatsapp-server.js";

let code = fs.readFileSync(path, "utf8");

// Buscar el bloque problemático y reemplazarlo
const oldBlock = /\.insert\(\[\{\s*chat_id:\s*chat\?\.id\s*\|\|\s*null,\s*phone:\s*cleanPhone,\s*message:\s*message,\s*message_type:\s*messageType,\s*is_from_me:\s*isFromMe,\s*is_read:\s*isFromMe,\s*whatsapp_instance:\s*CONFIG\.INSTANCE_NUMBER\s*\}\]\)/s;

const newBlock = `.insert([{
                chat_id: chat?.id || null,
                body: message || "",
                is_from_me: isFromMe,
                is_read: isFromMe,
                created_at: new Date().toISOString()
            }])`;

if (oldBlock.test(code)) {
    code = code.replace(oldBlock, newBlock);
    fs.writeFileSync(path, code, "utf8");
    console.log("✅ Reemplazo exitoso");
} else {
    // Buscar variaciones
    const variations = [
        /phone:\s*cleanPhone,\s*message:\s*message,\s*message_type:\s*messageType,\s*is_from_me:\s*isFromMe,\s*is_read:\s*isFromMe,\s*whatsapp_instance:\s*CONFIG\.INSTANCE_NUMBER/s,
        /phone:\s*cleanPhone[^}]+whatsapp_instance:\s*CONFIG\.INSTANCE_NUMBER[^}]*\}/s
    ];
    
    let replaced = false;
    for (const pattern of variations) {
        if (pattern.test(code)) {
            code = code.replace(pattern, `body: message || "",
                is_from_me: isFromMe,
                is_read: isFromMe,
                created_at: new Date().toISOString()`);
            fs.writeFileSync(path, code, "utf8");
            console.log("✅ Reemplazo exitoso (variación)");
            replaced = true;
            break;
        }
    }
    
    if (!replaced) {
        // Método más agresivo: buscar la función completa
        const funcPattern = /(async function saveMessageToSupabase\([^)]+\)\s*\{[^}]*\.from\('whatsapp_messages'\)[^}]*\.insert\(\[)\{[^}]*phone:[^}]*whatsapp_instance:[^}]*\}([^}]*\])/s;
        
        if (funcPattern.test(code)) {
            code = code.replace(funcPattern, (match, before, after) => {
                return before + `{
                chat_id: chat?.id || null,
                body: message || "",
                is_from_me: isFromMe,
                is_read: isFromMe,
                created_at: new Date().toISOString()
            }` + after;
            });
            fs.writeFileSync(path, code, "utf8");
            console.log("✅ Reemplazo exitoso (método agresivo)");
        } else {
            console.log("❌ No se pudo encontrar el patrón");
            process.exit(1);
        }
    }
}
NODEEOF
'
    
    # Ejecutar el script
    if docker exec "$CONTAINER" node /tmp/fix_code.js; then
        echo "   ✅ Código corregido"
        
        # Verificar
        echo "   📋 Verificando:"
        docker exec "$CONTAINER" grep -A 8 "\.from('whatsapp_messages')" /app/whatsapp-server.js | grep -A 6 "\.insert" | head -8
    else
        echo "   ❌ Error al corregir"
    fi
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
