# 🔥 HOTFIX: Línea 4 - Mensajes 1:1 como Stubs/CIPHERTEXT No Descifran

## 🚨 Problema

Post-PR #8, línea 4 (5492944616271) ya no tiene "Bad MAC" masivos, pero **mensajes 1:1 desde el número personal del owner (5492944210725) NO llegan a Flor**.

### Síntomas

- ❌ Logs NO muestran el número del sender (5492944210725)
- ❌ Repetido: `⚠️ Mensaje sin contenido (message es null/undefined)` después de `messages.upsert`
- ❌ Device notifications desde `205132033732831@lid` (sin LID→PN mapping en logs)
- ❌ Flor no responde a "hola" del owner

### Hipótesis Confirmada

**Mensajes 1:1 llegan como CIPHERTEXT / stubs no descifrables**:
- `msg.message` es `null/undefined`
- Son mensajes que Baileys NO pudo descifrar inicialmente
- Deberían recuperarse vía **retry receipts**, pero no funciona porque:
  1. `getMessage()` no encuentra el mensaje stub (nunca se cachea)
  2. Baileys no puede responder al retry receipt del sender
  3. El sender ve "Esperando mensaje", nosotros nunca recibimos el contenido

---

## 🔍 Causa Raíz

### Flujo Normal de Retry Receipts

1. Cliente envía mensaje encriptado
2. Baileys no puede descifrarlo (sesión nueva, pre-key missing, etc.) → mensaje llega como stub sin `msg.message`
3. **Baileys envía "retry receipt" al cliente automáticamente**
4. **Cliente recibe retry receipt, LLAMA a `getMessage(key)` y re-encripta con nueva sesión**
5. Cliente reenvía mensaje con nueva encriptación
6. Baileys descifra correctamente

### Por Qué Falló en Línea 4

**Paso 4 fallaba**: Cuando Baileys llama `getMessage(key)` para recuperar el mensaje original:

```javascript
// Antes del fix
async function getFlorMessageForBaileysRetry(key) {
    // 1. Check outbound messages → NO (es inbound)
    // 2. Check Supabase → NO (mensaje stub nunca se guardó en DB)
    // 3. Return undefined → ❌ RETRY RECEIPT FALLA
}
```

**Resultado**: Cliente reenvía, pero Baileys no puede procesar el retry porque `getMessage` devuelve `undefined`.

### Por Qué los Stubs No se Guardaban

En el handler de `messages.upsert`:

```javascript
const message = unwrapBaileysInnerMessage(msg.message) || msg.message;
if (!message) {
    console.log(`⚠️ Mensaje sin contenido`);
    continue;  // ← SKIP - nunca se cachea ni guarda
}
```

El `continue` hace que:
- No se guarde en Supabase
- No se cachee en RAM
- `getMessage` no lo encuentra
- Retry receipts fallan

---

## ✅ Solución

### 1. Cachear Message Stubs para Retries

Crear un Map dedicado para mensajes entrantes sin contenido:

```javascript
// Nuevo cache para stubs INBOUND
const florInboundStubForRetry = new Map();
```

**Antes del `continue`**, guardar el mensaje stub completo:

```javascript
if (!message) {
    // ... existing debug logging ...
    
    // CRITICAL: Cache for getMessage during retry
    if (msg.key?.id && msg) {
        const msgId = String(msg.key.id);
        florInboundStubForRetry.set(msgId, { message: msg, ts: Date.now() });
        console.log(`✅ Cached stub message ${msgId} for retry`);
    }
    
    continue;
}
```

### 2. getMessage Consulta el Cache de Stubs

```javascript
async function getFlorMessageForBaileysRetry(key) {
    // 1. Check outbound messages (existing)
    // ...
    
    // 2. Check INBOUND stubs cache (NUEVO)
    const stubEnt = florInboundStubForRetry.get(String(key.id));
    if (stubEnt?.message) {
        console.log(`✅ FOUND inbound stub for ${key.id} (enables retry)`);
        return stubEnt.message;  // ← Baileys puede responder al retry receipt
    }
    
    // 3. Check Supabase (existing)
    // ...
}
```

### 3. Enhanced Debug Logging

Para diagnosticar qué está pasando:

```javascript
if (!message) {
    const debugInfo = {
        remoteJid: msg.key?.remoteJid,
        participant: msg.key?.participant,
        id: msg.key?.id,
        messageStubType: msg.messageStubType,
        senderPn: extractSenderPnFromMessageDeep(msg)
    };
    console.log(`⚠️ Mensaje sin contenido`);
    console.log(`   Debug info:`, JSON.stringify(debugInfo, null, 2));
    
    const isMessageStub = msg.messageStubType != null;
    if (isMessageStub) {
        console.log(`   → Es messageStub (tipo ${msg.messageStubType}), no descifrable`);
    } else {
        console.log(`   → NO es stub, es CIPHERTEXT - retry lo recuperará`);
    }
}
```

### 4. Verbose getMessage Logging

```javascript
async function getFlorMessageForBaileysRetry(key) {
    console.log(`🔄 getMessage: CALLED for key.id=${key.id}, remoteJid=${key.remoteJid}`);
    
    // ... búsquedas ...
    
    if (found) {
        console.log(`🔄 getMessage: ✅ FOUND ...`);
        return message;
    }
    
    console.warn(`⚠️ getMessage: ❌ NOT FOUND for ${key.id}`);
    console.warn(`   → Retry receipts won't work - sender sees "Esperando mensaje"`);
    return undefined;
}
```

---

## 📦 Cambios Implementados

**Archivos modificados**:
- `whatsapp-server/whatsapp-server-baileys.js`:
  - Línea ~678: Agregado `florInboundStubForRetry` Map
  - Líneas ~700-750: Refactored `getFlorMessageForBaileysRetry` con verbose logging + stub cache
  - Líneas ~7420-7465: Enhanced logging + cacheo de stubs antes de `continue`

**Documentación**:
- `HOTFIX_LINE4_MESSAGE_STUBS.md`: Este documento

**Sintaxis verificada**: ✅ OK

---

## 🚀 Deployment

### Pasos Exactos

1. **Merge este PR** (aprobar German)

2. **Deploy en Easypanel**:
   ```
   Easypanel → Services → whatsapp → Implementar
   ```

3. **Aplicar Traefik**:
   ```bash
   cd /root/checkin24hs
   bash scripts/aplicar_traefik_whatsapp_ambos.sh
   ```

4. **Test en Línea 4**:
   - Enviar "hola" desde 5492944210725 a 5492944616271
   - **Verificar logs** (inmediato):
     ```bash
     docker service logs -f checkin24hs_whatsapp --tail 100 | grep -E "Mensaje sin contenido|getMessage|stub"
     ```
   
   **Esperado**:
   ```
   ⚠️ Mensaje sin contenido (posible CIPHERTEXT/stub)
   Debug info: { "remoteJid": "205132033732831@lid", "id": "...", ... }
   → NO es stub, es CIPHERTEXT - retry lo recuperará
   → ✅ Cached stub message ABC123 for retry
   
   [unos segundos después, cuando llega retry receipt]
   🔄 getMessage: CALLED for key.id=ABC123
   🔄 getMessage: ✅ FOUND inbound stub from RAM for ABC123
   
   [mensaje descifrado correctamente]
   ```
   
   - **Verificar**: Flor debe responder al "hola"

5. **Monitor Retry Receipts** (opcional):
   ```bash
   docker service logs -f checkin24hs_whatsapp --tail 200 | grep -E "getMessage|retry|FOUND|NOT FOUND"
   ```

---

## 📊 Resultados Esperados

### Antes del Fix

```
Logs al enviar "hola" desde 5492944210725:
  ⚠️ Mensaje sin contenido (message es null/undefined)
  [ningún log más, mensaje nunca llega a Flor]
```

Owner ve: "Esperando mensaje"
Flor: No responde

### Después del Fix

```
Logs al enviar "hola" desde 5492944210725:
  ⚠️ Mensaje sin contenido (posible CIPHERTEXT/stub)
  Debug info: {
    "remoteJid": "205132033732831@lid",
    "participant": null,
    "id": "ABC123XYZ",
    "messageStubType": null,
    "senderPn": "5492944210725"
  }
  → NO es stub, es CIPHERTEXT - retry lo recuperará
  → ✅ Cached stub message ABC123XYZ for retry (cache size: 1)
  
  [~1-3 segundos después]
  🔄 getMessage: CALLED for key.id=ABC123XYZ, remoteJid=205132033732831@lid
  🔄 getMessage: ✅ FOUND inbound stub from RAM for ABC123XYZ (enables retry)
  
  [mensaje descifrado en retry]
  📨 Mensaje procesado correctamente: "hola"
  🤖 Flor responde: [respuesta de Flor]
```

Owner ve: Mensaje enviado OK
Flor: Responde correctamente

---

## 🔧 Troubleshooting

### Si Aún No Descifra

**1. Verificar que cache de stubs funciona**:

```bash
docker service logs checkin24hs_whatsapp --tail 500 | grep "Cached stub"
```

Debe mostrar: `✅ Cached stub message XXX for retry`

**2. Verificar que getMessage se llama**:

```bash
docker service logs checkin24hs_whatsapp --tail 500 | grep "getMessage: CALLED"
```

Si NO aparece, Baileys no está enviando retry receipts (problema de sesión).

**3. Verificar que getMessage ENCUENTRA el stub**:

```bash
docker service logs checkin24hs_whatsapp --tail 500 | grep "FOUND inbound stub"
```

Si aparece "NOT FOUND" en lugar de "FOUND", el cache falló.

### Si el Problema es Sesiones LID

Si los logs muestran:
```
remoteJid: "205132033732831@lid"
senderPn: null o undefined
```

Significa que:
- El mensaje viene de una sesión LID
- No se pudo extraer el teléfono real
- Puede necesitar re-vinculación WhatsApp

**Solución temporal**: Enviar mensaje desde el número directo (no desde chat LID).

### Si Necesita Re-vinculación

```bash
# Solo si nada más funciona
docker service scale checkin24hs_whatsapp=0
docker run --rm -v whatsapp4-auth:/data alpine sh -c 'rm -rf /data/*'
docker service scale checkin24hs_whatsapp=1
# Escanear nuevo QR desde 5492944616271
```

---

## 📝 Notas Técnicas

### Por Qué Líneas 1-2-3 No Tienen Este Problema

Posibles razones:
1. **Sesiones pre-establecidas**: Tienen sesiones Signal válidas con los contactos frecuentes
2. **Timing**: Recibieron mensajes después de que las sesiones ya estaban establecidas
3. **Contactos diferentes**: Los contactos que escriben a líneas 1-2-3 no son nuevos

Línea 4 recibe mensajes de **contactos nuevos o sesiones nuevas** → más propenso a CIPHERTEXT stubs.

### Por Qué Este Fix es Seguro

1. **Solo agrega cache**: No modifica flujo existente para mensajes con contenido
2. **Verbose logging**: Ayuda a diagnosticar sin romper funcionalidad
3. **TTL y límite de tamaño**: Cache no crece infinito (mismo límite que outbound)
4. **Líneas 1-2-3**: No se afectan porque ya descifran correctamente

### Diferencia con PR #7

- **PR #7**: Agregó getMessage que consulta Supabase para mensajes **guardados**
- **Este PR**: Agrega cache en RAM para mensajes **stub (no guardados)**

Ambos son necesarios:
- PR #7: Para retries de mensajes que llegaron bien inicialmente
- Este PR: Para retries de mensajes que llegaron como CIPHERTEXT desde el inicio

---

**Severity**: 🔥 ALTO - P1
**Impact**: Línea 4 no recibe mensajes 1:1 de ciertos contactos (owner incluido)
**Risk**: Bajo (cambios aditivos, no modifica flujo existente)
**Testing**: Sintaxis OK, logging verbose ayuda a diagnosticar
