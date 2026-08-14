#!/bin/bash
# Parche en servidor: chats/mensajes Línea 2 con whatsapp_instance=2 (no mezclar con Línea 1).
# Uso: cd /root/checkin24hs && bash scripts/patch_whatsapp_instancia_linea2_servidor.sh

set -euo pipefail
cd "$(dirname "$0")/.."
FILE="whatsapp-server/whatsapp-server-baileys.js"

if [ ! -f "$FILE" ]; then
  echo "ERROR: no existe $FILE"
  exit 1
fi

python3 << 'PY'
from pathlib import Path
p = Path("whatsapp-server/whatsapp-server-baileys.js")
t = p.read_text(encoding="utf-8")
changed = []

if "buildConversationExternalId" not in t:
    anchor = "    return [...variants].filter(Boolean);\n}\n\n/**"
    insert = '''    return [...variants].filter(Boolean);
}

/** external_id en whatsapp_conversations: incluye instancia para no mezclar Línea 1 y Línea 2 del mismo contacto */
function buildConversationExternalId(numero) {
    const inst = CONFIG.INSTANCE_NUMBER || 1;
    const d = digitsOnlyPhoneKey(numero);
    const base = d || String(numero || '').trim().replace(/@s\\.whatsapp\\.net$/i, '').replace(/@lid$/i, '');
    return `i${inst}:${base}`;
}

/**'''
    if anchor not in t:
        raise SystemExit("ERROR: no encontré punto de inserción para buildConversationExternalId")
    t = t.replace(anchor, insert, 1)
    changed.append("buildConversationExternalId")

old_conv = '''        // Si no está en whatsapp_chats, buscar en whatsapp_conversations por external_id (evita duplicado y error unique)
        const { data: convExistente } = await supabase
            .from('whatsapp_conversations')
            .select('id')
            .eq('external_id', String(numero))
            .maybeSingle();
        if (convExistente?.id) {
            console.log(`✅ Conversation existente en whatsapp_conversations para ${numero}, usando id: ${convExistente.id}`);
            return convExistente.id;
        }'''

new_conv = '''        // whatsapp_conversations por external_id con instancia (no reutilizar chat de otra línea)
        const extId = buildConversationExternalId(numero);
        const { data: convExistente } = await supabase
            .from('whatsapp_conversations')
            .select('id')
            .eq('external_id', extId)
            .maybeSingle();
        if (convExistente?.id) {
            const { data: chatRow } = await supabase
                .from('whatsapp_chats')
                .select('id, whatsapp_instance')
                .eq('id', convExistente.id)
                .maybeSingle();
            if (chatRow && parseInt(chatRow.whatsapp_instance, 10) === (CONFIG.INSTANCE_NUMBER || 1)) {
                console.log(`✅ Conversation existente (${extId}) para instancia ${CONFIG.INSTANCE_NUMBER}`);
                return convExistente.id;
            }
        }'''

if old_conv in t:
    t = t.replace(old_conv, new_conv, 1)
    changed.append("obtenerOcrearChatId lookup")

if "external_id: numero," in t and "onConflict: 'external_id'" in t:
    t = t.replace(
        "                        external_id: numero,\n                        status: 'open',\n                        metadata: {\n                            phone: numero,\n                            name: nombre || numero,\n                            whatsapp_instance: CONFIG.INSTANCE_NUMBER\n                        }\n                    }, { onConflict: 'external_id' });",
        "                        external_id: buildConversationExternalId(numero),\n                        status: 'open',\n                        metadata: {\n                            phone: numero,\n                            name: nombre || numero,\n                            whatsapp_instance: CONFIG.INSTANCE_NUMBER\n                        }\n                    }, { onConflict: 'id' });",
        1,
    )
    changed.append("upsert whatsapp_conversations on create")

if "external_id: String(numero)," in t:
    t = t.replace(
        "                external_id: String(numero),",
        "                external_id: buildConversationExternalId(numero),",
        1,
    )
    changed.append("asegurarConversationExiste external_id")

# Supabase + ws (Node 20)
if "realtime: { transport: ws }" not in t:
    old_sb = "    supabase = createClient(CONFIG.SUPABASE.url, CONFIG.SUPABASE.anonKey);"
    new_sb = """    const ws = require('ws');
    supabase = createClient(CONFIG.SUPABASE.url, CONFIG.SUPABASE.anonKey, {
        realtime: { transport: ws }
    });"""
    if old_sb in t:
        t = t.replace(old_sb, new_sb, 1)
        changed.append("supabase ws transport")

if "tryClaimFlorInbound" not in t:
    print("INFO: parche dedupe mensajes (tryClaimFlorInbound) no incluido — opcional si ya respondió 1 sola vez")

p.write_text(t, encoding="utf-8")
print("OK parche aplicado:", ", ".join(changed) if changed else "nada (¿ya estaba?)")
PY

echo ""
echo "=== Rebuild imagen y actualizar servicios ==="
docker build --no-cache -t easypanel/checkin24hs/whatsapp:latest whatsapp-server/
docker service update --force checkin24hs_whatsapp2
docker service update --force checkin24hs_whatsapp

echo ""
echo "=== Verificar ==="
sleep 15
CID=$(docker ps -q -f name=checkin24hs_whatsapp2 | head -1)
docker exec "$CID" grep -c 'buildConversationExternalId' /app/whatsapp-server-baileys.js || true
echo "Listo. Mandá mensaje de prueba al 0748 y revisá Chats → Línea 2."
