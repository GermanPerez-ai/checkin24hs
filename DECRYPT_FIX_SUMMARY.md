# 🔐 Fix: "Esperando mensaje" - Decrypt Failures

## 🎯 Root Cause Analysis

### Problem
Customers see "Esperando mensaje. Esto puede tomar tiempo" because WhatsApp can't decrypt their messages. After 546 crypto errors, a redeploy temporarily fixes it (resets sessions), but it recurs.

### Root Causes Found

1. **getMessage Incomplete** 
   - Current: Only returns outbound messages from RAM (`florOutboundProtoForRetry` Map)
   - Missing: Doesn't query `whatsapp_messages` table for INBOUND messages
   - Impact: When customer sends message → decrypt fails → Baileys requests retry → getMessage returns undefined → customer sees "Esperando mensaje"

2. **No msgRetryCounterCache**
   - Missing: NodeCache for tracking retry attempts
   - Impact: Baileys can't properly manage retry logic

3. **No makeCacheableSignalKeyStore**
   - Missing: Performance optimization for signal key operations
   - Impact: Slower key operations, potential session corruption

4. **No Per-Contact Session Clearing**
   - Current: On decrypt failure, session stays broken
   - Missing: Clear specific contact's session to trigger re-establishment
   - Impact: Once broken, stays broken until full redeploy

5. **Potential Concurrent Auth Access**
   - Risk: If Docker Swarm replicas > 1 or overlapping deploys
   - Impact: Two containers access same `auth_info_baileys_N` → session corruption → Bad MAC

## ✅ Solution Implemented

### 1. Add node-cache Dependency
File: `whatsapp-server/package.json`
```json
{
  "dependencies": {
    "node-cache": "^5.1.2"
  }
}
```

### 2. Complete getMessage Implementation
Location: After line 674 in whatsapp-server-baileys.js

**Current (broken)**:
```javascript
async function getFlorMessageForBaileysRetry(key) {
    if (!key?.id) return undefined;
    const ent = florOutboundProtoForRetry.get(String(key.id));
    if (!ent?.message) return undefined;
    if (Date.now() - ent.ts > FLOR_OUTBOUND_PROTO_TTL_MS) return undefined;
    return ent.message;
}
```

**Fixed (queries Supabase)**:
```javascript
async function getFlorMessageForBaileysRetry(key) {
    if (!key?.id) return undefined;
    
    // 1. Fast path: check outbound messages in RAM
    const ent = florOutboundProtoForRetry.get(String(key.id));
    if (ent?.message && Date.now() - ent.ts <= FLOR_OUTBOUND_PROTO_TTL_MS) {
        console.log(`🔄 getMessage: outbound from RAM for ${key.id}`);
        return ent.message;
    }
    
    // 2. CRITICAL: Query Supabase for INBOUND messages
    if (supabase && key.id) {
        try {
            const { data, error } = await supabase
                .from('whatsapp_messages')
                .select('baileys_message_proto')
                .eq('baileys_message_id', String(key.id))
                .maybeSingle();
            
            if (!error && data?.baileys_message_proto) {
                try {
                    const proto = JSON.parse(data.baileys_message_proto);
                    console.log(`🔄 getMessage: INBOUND from Supabase for ${key.id} (fixes "Esperando mensaje")`);
                    return proto;
                } catch (parseErr) {
                    console.warn(`⚠️ getMessage: failed to parse proto for ${key.id}:`, parseErr.message);
                }
            }
        } catch (err) {
            console.warn(`⚠️ getMessage: Supabase query failed for ${key.id}:`, err.message);
        }
    }
    
    // 3. Not found - customer will see "Esperando mensaje"
    console.warn(`⚠️ getMessage: NOT FOUND for ${key.id} → customer sees "Esperando mensaje"`);
    trackPersistentDecryptFailure(key.remoteJid, key.id);
    return undefined;
}
```

### 3. Add msgRetryCounterCache
Location: Top of file, after requires

```javascript
const NodeCache = require('node-cache');
const msgRetryCounterCache = new NodeCache({ 
    stdTTL: 3600,    // 1 hour TTL
    checkperiod: 600, // cleanup every 10 min
    useClones: false  // performance
});
console.log('✅ msgRetryCounterCache initialized');
```

Then in makeWASocket config (line 6806):
```javascript
sock = makeWASocket({
    // ... other config
    getMessage: getFlorMessageForBaileysRetry,
    msgRetryCounterCache,  // ADD THIS LINE
    // ...
});
```

### 4. Add makeCacheableSignalKeyStore
Location: In connectToWhatsApp, after useMultiFileAuthState (line 6780)

```javascript
const { state, saveCreds } = await useMultiFileAuthState(path.join(__dirname, `auth_info_baileys_${CONFIG.INSTANCE_NUMBER}`));

// ADD: Wrap with cacheable signal key store for performance
const makeCacheableSignalKeyStore = baileysLib.makeCacheableSignalKeyStore || ((keys) => keys);
const cacheableState = {
    creds: state.creds,
    keys: makeCacheableSignalKeyStore(state.keys, createFlorBaileysLogger())
};

sock = makeWASocket({
    auth: cacheableState,  // USE cacheableState instead of state
    // ...
});
```

### 5. Per-Contact Session Clearing
Location: Add function after getFlorMessageForBaileysRetry

```javascript
const persistentDecryptFailures = new Map(); // remoteJid -> { count, lastAttempt, messageId }

function trackPersistentDecryptFailure(remoteJid, messageId) {
    if (!remoteJid) return;
    
    const now = Date.now();
    const entry = persistentDecryptFailures.get(remoteJid) || { count: 0, lastAttempt: 0 };
    
    // Reset if last attempt was >1 hour ago
    if (now - entry.lastAttempt > 3600000) {
        entry.count = 0;
    }
    
    entry.count++;
    entry.lastAttempt = now;
    entry.messageId = messageId;
    persistentDecryptFailures.set(remoteJid, entry);
    
    console.warn(`🔐 Decrypt failure ${entry.count} for ${remoteJid} (msg ${messageId})`);
    
    // After 2 failures, clear contact session
    if (entry.count === 2) {
        clearContactSessionOnDecryptFail(remoteJid);
    }
    
    // After 3 failures, notify team
    if (entry.count === 3) {
        notifyTeamAboutDecryptFailure(remoteJid);
    }
}

async function clearContactSessionOnDecryptFail(remoteJid) {
    if (!sock || !remoteJid) return;
    
    try {
        console.warn(`🔐 Clearing session for ${remoteJid} due to persistent decrypt failures`);
        
        // Clear from Baileys session store
        if (sock.authState?.keys?.clear) {
            await sock.authState.keys.clear(remoteJid);
            console.log(`✅ Session cleared for ${remoteJid}, will re-establish on next message`);
        } else {
            console.warn(`⚠️ Cannot clear session for ${remoteJid}: keys.clear not available`);
        }
    } catch (err) {
        console.error(`❌ Failed to clear session for ${remoteJid}:`, err.message);
    }
}

async function notifyTeamAboutDecryptFailure(remoteJid) {
    const phone = remoteJid.split('@')[0];
    const message = `🚨 *ALERTA: Fallo de Descifrado Persistente*\n\nCliente: ${phone}\nEstado: No se pueden descifrar mensajes\nImpacto: Cliente ve "Esperando mensaje"\n\n⚠️ Acción requerida: Contactar al cliente por otro medio o reiniciar línea WhatsApp.`;
    
    console.error(`🚨 DECRYPT ALERT: ${phone} - persistent failures`);
    
    // Log to console for monitoring
    console.error(message);
    
    // TODO: Optional - send to monitoring group
    // if (CONFIG.MONITORING_GROUP_ID) {
    //     await sendToMonitoringGroup(message);
    // }
}
```

### 6. Tune florCryptoProtection
Location: Replace maybeTriggerFlorCryptoProtection function (around line 539)

**Current**: Reconnects on every "hard" level
**Fixed**: Only reconnects after threshold + cooldown

```javascript
let lastFlorCryptoReconnectAt = 0;

function maybeTriggerFlorCryptoProtection(detail) {
    const level = getFlorCryptoProtectionLevel();
    if (level !== 'hard') return; // Only act on 'hard'
    
    const n = florSessionCryptoIssueTimes.length;
    const lastReconnect = Date.now() - lastFlorCryptoReconnectAt;
    
    // Only reconnect if:
    // 1. Many errors (>50 in window) - raised from default
    // 2. Haven't reconnected recently (respect cooldown)
    if (n >= 50 && lastReconnect > FLOR_CRYPTO_RECONNECT_COOLDOWN_MS) {
        console.warn(
            `🔐 Flor crypto protection TRIGGERED: ${n} errors in window, ` +
            `last reconnect ${Math.round(lastReconnect / 60000)} min ago. ` +
            `Scheduling reconnect...`
        );
        lastFlorCryptoReconnectAt = Date.now();
        scheduleWaReconnect(8000, 'crypto hard protection n=' + n);
    } else if (n >= 50) {
        console.warn(
            `🔐 Flor crypto protection: ${n} errors but cooldown active ` +
            `(${Math.round(lastReconnect / 60000)}/${Math.round(FLOR_CRYPTO_RECONNECT_COOLDOWN_MS / 60000)} min)`
        );
    }
}
```

### 7. Ensure baileys_message_proto is Saved
Location: In upsert logic (search for "INSERT INTO whatsapp_messages")

Ensure the INSERT includes:
```javascript
baileys_message_proto: message.message ? JSON.stringify(message.message) : null
```

This is CRITICAL for getMessage to work on retries.

## 🚀 Deployment Steps

### 1. Update Code
```bash
git fetch origin
git checkout cursor/fix-message-decrypt-robust-8d1f
git pull origin cursor/fix-message-decrypt-robust-8d1f
```

### 2. Install Dependencies
```bash
cd whatsapp-server
npm install node-cache
```

### 3. Verify Swarm Configuration
In Easypanel or docker-compose.yml, ensure:
```yaml
services:
  whatsapp-1:
    deploy:
      replicas: 1  # CRITICAL: MUST be 1
      update_config:
        order: stop-first  # Stop old before starting new
        parallelism: 1
```

**Why**: Two containers accessing same `auth_info_baileys_N` = session corruption

### 4. Deploy via Easypanel
1. Merge PR to main
2. Easypanel → Services → whatsapp → **Implementar** (Deploy)
3. Wait for deployment to complete
4. Run: `bash scripts/aplicar_traefik_whatsapp_ambos.sh`

### 5. Monitor
```bash
# Check health
curl https://whatsapp.checkin24hs.com/api/health | jq .florSessionCryptoIssuesLastWindow

# Watch logs
pm2 logs whatsapp-1 --lines 100 | grep -E "getMessage|decrypt|Esperando"
```

## 📊 Expected Results

### Before Fix
- florSessionCryptoIssuesLastWindow: 546
- Logs: "recv retry request, but message not available"
- Customer phone: "Esperando mensaje. Esto puede tomar tiempo"

### After Fix
- florSessionCryptoIssuesLastWindow: <10 (normal background noise)
- Logs: "getMessage: INBOUND from Supabase" (successful retries)
- Customer phone: Messages decrypt correctly
- Logs: "Session cleared for ..." (proactive recovery)

## 🔍 Verification Checklist

- [ ] node-cache installed in package.json
- [ ] getMessage queries whatsapp_messages table
- [ ] msgRetryCounterCache configured in makeWASocket
- [ ] makeCacheableSignalKeyStore wraps auth state
- [ ] baileys_message_proto saved in upsert
- [ ] Per-contact session clearing on failures
- [ ] Team notification on persistent failures
- [ ] florCryptoProtection tuned (threshold 50, respects cooldown)
- [ ] Swarm replicas = 1, update_config = stop-first
- [ ] Tests with new customer contact succeed

## 📝 Notes

1. **Why it recurs**: Broken sessions accumulate over time as new customers contact us. Redeploy clears all sessions (fresh auth), which is why it temporarily fixes.

2. **Why getMessage is critical**: When Baileys can't decrypt, it sends a "retry receipt" to the sender. Sender's WhatsApp then re-encrypts with a new session and resends. But this ONLY works if getMessage returns the original message so Baileys can reply "got it, here's the decrypted version".

3. **Why Supabase query**: Inbound messages are stored in whatsapp_messages by the upsert logic. We MUST query this to handle customer-sent message retries.

4. **Why session clearing helps**: If a contact's session is corrupted, clearing it forces both sides to re-establish. This is better than leaving it broken forever.

5. **Swarm replicas MUST be 1**: Two containers with same auth = "this session is being used elsewhere" = instant Bad MAC on every message.
