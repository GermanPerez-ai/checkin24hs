# Fix Plan: "Esperando mensaje" Decrypt Issues

## Root Causes Identified

1. **getMessage incomplete**: Only returns outbound messages from RAM Map, doesn't query Supabase whatsapp_messages for inbound messages when customer sends retry receipt
2. **No msgRetryCounterCache**: NodeCache not configured, so Baileys can't track retry attempts properly
3. **No makeCacheableSignalKeyStore**: Missing performance optimization for signal key operations
4. **No per-contact session clearing**: When decrypt fails, no logic to clear just that contact's session
5. **Potential concurrent auth access**: If Docker Swarm replicas>1 or overlapping deploys, multiple containers share same auth_info_baileys_N directory

## Changes Required

### 1. Add NodeCache for msgRetryCounterCache
```javascript
const NodeCache = require('node-cache');
const msgRetryCounterCache = new NodeCache({ 
    stdTTL: 3600, // 1 hour
    checkperiod: 600 // check every 10 min
});
```

### 2. Fix getMessage to Query Supabase
```javascript
async function getFlorMessageForBaileysRetry(key) {
    if (!key?.id) return undefined;
    
    // 1. Check outbound messages in RAM first (fast path)
    const ent = florOutboundProtoForRetry.get(String(key.id));
    if (ent?.message && Date.now() - ent.ts <= FLOR_OUTBOUND_PROTO_TTL_MS) {
        return ent.message;
    }
    
    // 2. Query Supabase for inbound messages (stored by messages.upsert)
    if (supabase && key.remoteJid) {
        try {
            const { data, error } = await supabase
                .from('whatsapp_messages')
                .select('baileys_message_proto')
                .eq('baileys_message_id', String(key.id))
                .eq('baileys_from_me', key.fromMe ? true : false)
                .maybeSingle();
            
            if (!error && data?.baileys_message_proto) {
                console.log(`🔄 getMessage retry: found in Supabase for ${key.id}`);
                return JSON.parse(data.baileys_message_proto);
            }
        } catch (err) {
            console.warn('⚠️ getMessage Supabase query failed:', err.message);
        }
    }
    
    console.warn(`⚠️ getMessage: not found for ${key.id} (customer will see "Esperando mensaje")`);
    return undefined;
}
```

### 3. Store Inbound Message Proto in whatsapp_messages
In the upsert logic, ensure we save `baileys_message_proto` field:
```javascript
baileys_message_proto: JSON.stringify(message.message)
```

### 4. Add makeCacheableSignalKeyStore
```javascript
const { makeCacheableSignalKeyStore } = baileysLib;

const { state, saveCreds } = await useMultiFileAuthState(authDir);
const cacheableState = {
    ...state,
    keys: makeCacheableSignalKeyStore(state.keys, createFlorBaileysLogger())
};

sock = makeWASocket({
    auth: cacheableState,
    // ...
});
```

### 5. Per-Contact Session Clearing
Add function to clear specific contact session:
```javascript
async function clearContactSessionOnDecryptFail(remoteJid) {
    if (!sock || !remoteJid) return;
    
    try {
        console.log(`🔐 Clearing session for ${remoteJid} due to decrypt failure`);
        
        // Clear from Baileys in-memory session store
        if (sock.authState?.keys?.clear) {
            await sock.authState.keys.clear(remoteJid);
        }
        
        // Request the contact to re-establish session
        // by sending a "unavailable" receipt or similar signal
        // (Baileys will handle this internally on next message)
        
        console.log(`✅ Session cleared for ${remoteJid}, will retry on next message`);
    } catch (err) {
        console.error(`❌ Failed to clear session for ${remoteJid}:`, err.message);
    }
}
```

### 6. Notify Team on Persistent Decrypt Failures
Track failed decrypt attempts per contact and notify:
```javascript
const persistentDecryptFailures = new Map(); // remoteJid -> { count, lastAttempt }

function trackDecryptFailure(remoteJid) {
    if (!remoteJid) return;
    
    const now = Date.now();
    const entry = persistentDecryptFailures.get(remoteJid) || { count: 0, lastAttempt: 0 };
    
    // Reset if last attempt was >1 hour ago
    if (now - entry.lastAttempt > 3600000) {
        entry.count = 0;
    }
    
    entry.count++;
    entry.lastAttempt = now;
    persistentDecryptFailures.set(remoteJid, entry);
    
    // After 3 failures in an hour, notify team
    if (entry.count === 3) {
        notifyTeamAboutDecryptFailure(remoteJid);
    }
}

async function notifyTeamAboutDecryptFailure(remoteJid) {
    const phone = remoteJid.split('@')[0];
    const message = `⚠️ ALERTA: No se pueden descifrar mensajes del cliente ${phone}\n\nEl cliente ve "Esperando mensaje" y no recibe respuesta.\n\nAcción requerida: Contactar al cliente por otro medio.`;
    
    console.error(`🚨 ${message}`);
    
    // Optional: send to monitoring WhatsApp group
    if (CONFIG.whatsapp?.monitoring_group_id) {
        try {
            await axios.post(`${CONFIG.BASE_URL}/api/send`, {
                number: CONFIG.whatsapp.monitoring_group_id,
                text: message
            });
        } catch (err) {
            console.error('Failed to notify team:', err.message);
        }
    }
}
```

### 7. Tune florCryptoProtection
Make it less aggressive - don't reconnect on every issue:
```javascript
function maybeTriggerFlorCryptoProtection(detail) {
    const level = getFlorCryptoProtectionLevel();
    if (level !== 'hard') return; // Only act on 'hard'
    
    const n = florSessionCryptoIssueTimes.length;
    const lastReconnect = Date.now() - lastFlorCryptoReconnectAt;
    
    // Only reconnect if:
    // 1. Many errors (>50 in window)
    // 2. Haven't reconnected recently (cooldown)
    if (n >= 50 && lastReconnect > FLOR_CRYPTO_RECONNECT_COOLDOWN_MS) {
        console.warn(`🔐 Crypto protection: ${n} errors, scheduling reconnect (last was ${Math.round(lastReconnect/60000)}min ago)`);
        scheduleWaReconnect(8000, 'crypto hard protection n=' + n);
        lastFlorCryptoReconnectAt = Date.now();
    }
}
```

## Deployment Configuration

### Docker Swarm / Easypanel
Ensure in docker-compose.yml or Easypanel service config:
```yaml
services:
  whatsapp-1:
    deploy:
      replicas: 1  # MUST be 1, never >1
      update_config:
        order: stop-first  # Stop old before starting new
        parallelism: 1
```

This prevents two containers from accessing same auth_info_baileys_N simultaneously.

## Testing Plan

1. Deploy with changes
2. Monitor /health endpoint for florSessionCryptoIssuesLastWindow
3. Test with a new customer contact (no prior session)
4. Verify messages decrypt correctly
5. Monitor logs for "getMessage retry: found in Supabase"
6. Check no "Esperando mensaje" appears on customer's phone

## Files to Modify

- whatsapp-server/whatsapp-server-baileys.js (main changes)
- package.json (add node-cache if not present)
- Document Swarm configuration in README
