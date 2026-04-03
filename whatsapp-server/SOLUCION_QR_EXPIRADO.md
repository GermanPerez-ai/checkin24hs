# 🚨 Solución: QR Expirado o No Funciona

## 🔍 Problema

Si el QR muestra "Conectando..." durante más de 2-5 minutos y el teléfono dice "No pudo iniciar sesión", el QR probablemente **expiró**.

## ⚡ Solución Rápida (Automática)

### Windows (PowerShell):
```powershell
cd whatsapp-server
.\solucionar-qr-problema.ps1 -Instance 1
```

### O desde el script de configuración:
```powershell
.\configurar-qr.ps1 -Action clean -Instance 1
# Luego reinicia el servidor
```

## 🔧 Solución Manual

### Paso 1: Verificar el problema

Abre en tu navegador:
```
http://TU_SERVIDOR:3001/api/diagnose
```

Si ves `"isExpired": true` o `"ageMinutes" > 2`, el QR está expirado.

### Paso 2: Regenerar el QR

**Opción A: Desde el navegador**
1. Abre: `http://TU_SERVIDOR:3001/api/qr/regenerate`
2. Espera 5-10 segundos
3. Recarga la página principal (`http://TU_SERVIDOR:3001`)
4. Escanea el NUEVO QR **inmediatamente** (expira en 2 minutos)

**Opción B: Desde la línea de comandos**
```bash
# PowerShell
curl -X POST http://TU_SERVIDOR:3001/api/qr/regenerate

# O Node.js
node configurar-qr.js
# Opción 5: Limpiar sesión
```

**Opción C: Limpiar sesión completa**
1. Detén el servidor
2. Elimina la carpeta: `auth_info_baileys_1` (o el número de instancia)
3. Reinicia el servidor
4. Escanea el nuevo QR **inmediatamente**

### Paso 3: Escanear el QR

⚠️ **IMPORTANTE:**
- Escanea el QR **dentro de 2 minutos** de generarse
- Si pasan más de 2 minutos, el QR expira y debes regenerarlo
- El teléfono debe tener conexión a internet
- No debe haber otras sesiones de WhatsApp Web activas en el teléfono

## 🔄 Prevención

### El servidor ahora incluye:

1. ✅ **Detección automática de QR expirado** - El servidor detecta cuando un QR tiene más de 2 minutos
2. ✅ **Regeneración automática** - Si el QR expira, se regenera automáticamente
3. ✅ **Advertencias en tiempo real** - El panel web muestra cuando el QR está por expirar
4. ✅ **Botón de regeneración** - Botón para forzar regeneración desde el panel web
5. ✅ **Diagnóstico mejorado** - Endpoint `/api/diagnose` para verificar el estado

### Recomendaciones:

- ⏰ Escanea el QR **inmediatamente** después de que aparezca
- 🔄 Si pasan más de 2 minutos, regenera el QR
- 📱 Asegúrate de tener buena conexión a internet
- ❌ No tengas múltiples sesiones de WhatsApp Web activas

## 📊 Verificar Estado

### Endpoint de Diagnóstico:
```
GET http://TU_SERVIDOR:3001/api/diagnose
```

Muestra:
- Estado de conexión
- Si el QR está expirado
- Edad del QR
- Tiempo hasta expiración

### Endpoint de Estado:
```
GET http://TU_SERVIDOR:3001/api/status
```

## 🆘 Si Nada Funciona

1. **Limpia completamente la sesión:**
   ```powershell
   Remove-Item -Recurse -Force .\auth_info_baileys_1
   ```

2. **Reinicia el servidor**

3. **Escanea el nuevo QR INMEDIATAMENTE** (en menos de 2 minutos)

4. **Verifica logs del servidor** para ver errores específicos

5. **Revisa conexión a internet** del servidor y del teléfono

## 💡 Notas Importantes

- ⏱️ **Los QR expiran en 2 minutos** - Esto es normal de WhatsApp
- 🔄 **El servidor regenera automáticamente** - Espera unos segundos si expira
- 📱 **Un QR expirado no funcionará** - Siempre regenera si tiene más de 2 minutos
- ✅ **Una vez conectado, no necesitas QR** - La sesión persiste

---

**Última actualización:** Enero 2025
