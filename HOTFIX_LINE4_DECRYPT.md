# 🔥 HOTFIX: Línea 4 No Descifra Mensajes (Post-PR #7)

## 🚨 Problema

**Línea 4** (checkin24hs_whatsapp4, 5492944616271, puerto 3004) no descifra **NINGÚN** mensaje entrante 1:1 después de PR #7. Flor no responde a clientes.

**Síntomas**:
- ❌ Cada mensaje entrante: `Session error: Bad MAC` en SessionCipher.doDecryptWhisperMessage
- ❌ `SessionError: No matching sessions found for message`
- ❌ `failed to decrypt message`
- ❌ Incluso con QR nuevo y vinculación fresca, falla en el primer mensaje
- ❌ 82 fallos en 10 minutos, nunca se recupera
- ❌ 34,633 archivos de pre-keys acumulados (normal: ~100-200)

**Estado**:
- Línea 4: Completamente rota (florSessionCryptoIssuesLastWindow: 135, level hard)
- Línea 3: Problemas (51 issues)
- Líneas 1 y 2: Funcionando (0 issues)

## 🔍 Causa Raíz

### **`makeCacheableSignalKeyStore` Rompe el Key Store**

En PR #7 agregamos:

```javascript
const cacheableState = {
    creds: state.creds,
    keys: makeCacheableSignalKeyStore(state.keys, createFlorBaileysLogger())
};

sock = makeWASocket({
    auth: cacheableState,  // ← Key store roto
    // ...
});
```

**Problemas**:

1. **`makeCacheableSignalKeyStore` puede no existir en Baileys 6.7.24**
   - Si es `undefined`, `makeCacheableSignalKeyStore(state.keys, ...)` falla
   - Resultado: `keys` se vuelve `undefined` o corrupto
   - El socket queda sin key store funcional

2. **Key Store Corrupto desde el Inicio**
   - Incluso con QR nuevo, el key store está roto
   - No puede guardar/cargar sesiones correctamente
   - Cada mensaje entrante → "No matching sessions"

3. **Acumulación de Pre-Keys**
   - Key store roto no puede subir pre-keys al servidor
   - Se regeneran constantemente (34,633 archivos)
   - Consume espacio en disco, degrada performance

4. **Por qué Línea 1 y 2 Funcionan**
   - Posiblemente diferentes timings de inicialización
   - O tuvieron sesiones establecidas antes del deploy de PR #7
   - Líneas 3 y 4 fallaron en establecer sesiones nuevas

## ✅ Solución

### Hacer `makeCacheableSignalKeyStore` Opcional con Fallback

```javascript
// Verificar si existe antes de usar
let authStateForSocket = state;
if (typeof makeCacheableSignalKeyStore === 'function') {
    try {
        const cachedKeys = makeCacheableSignalKeyStore(state.keys, createFlorBaileysLogger());
        authStateForSocket = {
            creds: state.creds,
            keys: cachedKeys
        };
        console.log('✅ Using makeCacheableSignalKeyStore for instance', CONFIG.INSTANCE_NUMBER);
    } catch (err) {
        console.warn('⚠️ makeCacheableSignalKeyStore failed, using direct keys:', err.message);
        authStateForSocket = state;
    }
} else {
    console.log('ℹ️ makeCacheableSignalKeyStore not available, using direct state');
    authStateForSocket = state;
}

sock = makeWASocket({
    auth: authStateForSocket,  // ← Safe: usa state directo si makeCacheable falla
    // ...
});
```

### Import Seguro

```javascript
// Antes (rompía si no existía):
const { makeCacheableSignalKeyStore } = baileysLib;

// Después (seguro):
const makeCacheableSignalKeyStore = baileysLib.makeCacheableSignalKeyStore;
```

## 📦 Archivos Modificados

- `whatsapp-server/whatsapp-server-baileys.js`:
  - Líneas 21-27: Import seguro de makeCacheableSignalKeyStore
  - Líneas 6902-6927: Uso condicional con fallback a state directo

## 🚀 Deployment

### Pasos Exactos

1. **Merge este PR** (no fusionar, esperar aprobación de German)

2. **Deploy en Easypanel**:
   ```
   Easypanel → Services → whatsapp → Implementar
   ```
   
   ⚠️ **Es un único servicio 'whatsapp' que despliega las 4 líneas**

3. **Aplicar Traefik**:
   ```bash
   cd /root/checkin24hs
   bash scripts/aplicar_traefik_whatsapp_ambos.sh
   ```

4. **Verificar Health de las 4 líneas**:
   ```bash
   for LINE in 1 2 3 4; do
     HOST="whatsapp.checkin24hs.com"
     [[ $LINE -gt 1 ]] && HOST="whatsapp${LINE}.checkin24hs.com"
     echo "=== Línea $LINE ==="
     curl -s "https://${HOST}/api/health" | jq '.florSessionCryptoIssuesLastWindow, .florCryptoProtection.level'
   done
   ```
   
   **Meta**: Todas las líneas con `florSessionCryptoIssuesLastWindow: 0-10`

5. **Test en Línea 4**:
   - Enviar mensaje de prueba desde un contacto a 5492944616271
   - Verificar que Flor responde
   - Verificar logs: NO debe haber "Bad MAC" / "No matching sessions"

6. **Monitor Pre-Keys** (opcional):
   ```bash
   # Contar archivos pre-key en línea 4
   docker exec $(docker ps -q -f name=whatsapp) sh -c 'ls -1 /app/auth_info_baileys_4/pre-key-*.json 2>/dev/null | wc -l'
   ```
   
   Después de unas horas, debería estabilizarse en ~100-200 (no miles)

## 📊 Resultados Esperados

### Antes del Hotfix
```
Línea 4:
- florSessionCryptoIssuesLastWindow: 135
- florCryptoProtection.level: "hard"
- Logs: "Session error: Bad MAC" constante
- Flor: NO responde
- Pre-keys: 34,633 archivos
```

### Después del Hotfix
```
Línea 4:
- florSessionCryptoIssuesLastWindow: 0-10
- florCryptoProtection.level: "none" o "soft"
- Logs: Sin "Bad MAC", sesiones funcionan
- Flor: Responde normalmente
- Pre-keys: ~100-200 archivos (normal)
```

### Línea 3
También debería mejorar si tenía problemas similares (51 issues → <10).

### Líneas 1 y 2
No deberían afectarse (ya funcionan).

## 🔧 Troubleshooting

### Si Línea 4 Sigue Fallando

**1. Limpiar Auth y Re-vincular**:
```bash
# Detener servicio
docker service scale checkin24hs_whatsapp=0

# Limpiar volumen de línea 4
docker run --rm -v whatsapp4-auth:/data alpine sh -c 'rm -rf /data/*'

# Reiniciar servicio
docker service scale checkin24hs_whatsapp=1

# Esperar ~30 segundos, luego obtener QR
curl -s https://whatsapp4.checkin24hs.com/api/qr | jq -r .qr
# Escanear con WhatsApp del 5492944616271
```

**2. Verificar Logs Durante Primera Conexión**:
```bash
docker service logs -f checkin24hs_whatsapp --tail 100 | grep -E "instance.*4|INSTANCE.*4|3004"
```

Buscar:
- ✅ `ℹ️ makeCacheableSignalKeyStore not available, using direct state for instance 4`
- ✅ `📦 Baileys WA Web version=...`
- ✅ `connection.update.*open` (conectado)
- ❌ NO debe haber: `makeCacheableSignalKeyStore failed`

**3. Test Inmediato**:
Enviar mensaje desde contacto → debe descifrar correctamente en el primer intento.

## 📝 Notas Adicionales

### Por qué PR #7 Causó Esto

PR #7 agregó optimizaciones incluyendo `makeCacheableSignalKeyStore`. Si bien la intención era mejorar performance, en Baileys 6.7.24:
- La función puede no existir
- O puede tener un bug que corrompe el key store
- Sin verificación de existencia, falló silenciosamente

### Por qué Líneas 1-2 No Fallaron

Posibles razones:
1. Timing: Sesiones ya establecidas antes del deploy
2. Orden de inicialización diferente
3. Estado de auth previo "compatible"

Líneas 3-4 intentaron establecer sesiones nuevas o tuvieron re-sync, y ahí falló el key store corrupto.

### Lecciones Aprendidas

1. **Siempre verificar que funciones opcionales existan**:
   ```javascript
   if (typeof fn === 'function') { ... }
   ```

2. **Fallback seguro para optimizaciones**:
   Si una optimización falla, debe caer a comportamiento base funcional

3. **Test en staging con QR nuevo**:
   Hubiera detectado el problema antes de producción

4. **Monitor por instancia**:
   Tener métricas separadas por línea ayuda a identificar problemas específicos

### Por qué No Revertir PR #7 Completo

Los otros cambios de PR #7 son valiosos:
- ✅ getMessage consulta Supabase (mejora retries)
- ✅ msgRetryCounterCache (mejora tracking)
- ✅ Limpieza de sesión por contacto (recuperación proactiva)
- ✅ florCryptoProtection ajustado (menos agresivo)

Solo `makeCacheableSignalKeyStore` causó el problema. Este hotfix lo hace opcional/seguro, preservando las demás mejoras.

---

**PR**: (pendiente)
**Branch**: `cursor/fix-line4-decrypt-makecacheable-3cc5`
**Severity**: CRÍTICO - Línea 4 sin servicio
**Priority**: P0 - Deploy inmediato después de aprobación
