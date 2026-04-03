# 🚨 Solución: Servidor No Responde (ERR_CONNECTION_TIMED_OUT)

## 🔍 Problema

Cuando intentas acceder a `http://api1.checkin24hs.com:3001` obtienes:
- **Error**: `ERR_CONNECTION_TIMED_OUT`
- **Mensaje**: "El sitio web tardó demasiado en responder"

## ⚡ Diagnóstico Rápido

Ejecuta el script de diagnóstico:

```powershell
cd whatsapp-server
.\diagnostico-servidor.ps1 -ServerUrl "http://api1.checkin24hs.com" -Instance 1
```

## 🔧 Soluciones Comunes

### 1. Verificar que el Servicio Esté Corriendo en EasyPanel

**Pasos:**
1. Accede a EasyPanel: `http://TU_IP:3000`
2. Busca el servicio `whatsapp1` o `checkin24hs_whatsapp1`
3. Verifica que el estado sea **"Running"** (verde) ✅
4. Si está detenido, haz clic en **"Start"** o **"Iniciar"**

### 2. Verificar Configuración del Puerto

**En EasyPanel:**
1. Ve al servicio WhatsApp
2. Haz clic en **"Resources"** o **"Recursos"**
3. Verifica que el puerto esté configurado como **3001** (para instancia 1)
4. Si no, cámbialo y **reinicia** el servicio

**Para otras instancias:**
- Instancia 1: Puerto **3001**
- Instancia 2: Puerto **3002**
- Instancia 3: Puerto **3003**
- Instancia 4: Puerto **3004**

### 3. Verificar Variables de Entorno

**En EasyPanel:**
1. Ve al servicio WhatsApp
2. Haz clic en **"Environment"** o **"Variables de Entorno"**
3. Verifica que existan estas variables:
   ```
   PORT=3001
   INSTANCE_NUMBER=1
   ```
4. Si faltan, agréguelas y **reinicia** el servicio

### 4. Verificar Logs del Servicio

**En EasyPanel:**
1. Ve al servicio WhatsApp
2. Haz clic en la pestaña **"Logs"**
3. Busca mensajes como:
   - ✅ `Servidor iniciado en puerto 3001` (correcto)
   - ❌ `Error iniciando servidor` (error)
   - ❌ `Puerto ya en uso` (conflicto)
   - ❌ `Servidor corriendo en puerto 80` (incorrecto - debe ser 3001)

### 5. Verificar Firewall y Red

Si el servicio está corriendo pero no es accesible:

**A. Verificar que el puerto esté abierto:**
```bash
# En el servidor (SSH)
sudo ufw status
sudo netstat -tulpn | grep 3001
```

**B. Si usas Docker directamente:**
```bash
# Verificar contenedores
docker ps | grep whatsapp

# Verificar mapeo de puertos
docker port CONTAINER_ID

# Ver logs
docker logs CONTAINER_ID
```

### 6. Verificar Mapeo de Puertos en EasyPanel

Si usas EasyPanel con Traefik:

1. **Verifica el dominio configurado:**
   - Ve a **"Domains"** o **"Dominios"** en EasyPanel
   - Busca `api1.checkin24hs.com`
   - Verifica que apunte al servicio correcto

2. **Verifica el puerto interno:**
   - El puerto interno debe ser **3001** (no 80, no 3000)
   - El puerto externo puede ser diferente según tu configuración

### 7. Reiniciar el Servicio

**En EasyPanel:**
1. Ve al servicio WhatsApp
2. Haz clic en **"Restart"** o **"Reiniciar"**
3. Espera 30-60 segundos
4. Verifica los logs para confirmar que inició correctamente

## 🔍 Verificación Paso a Paso

### Paso 1: Verificar Estado del Servicio
```powershell
# Ejecutar diagnóstico
.\diagnostico-servidor.ps1 -ServerUrl "http://api1.checkin24hs.com" -Instance 1
```

### Paso 2: Verificar desde el Navegador
1. Intenta acceder a: `http://api1.checkin24hs.com:3001/api/health`
2. Deberías ver un JSON con el estado

### Paso 3: Verificar desde PowerShell
```powershell
# Probar conexión
Invoke-WebRequest -Uri "http://api1.checkin24hs.com:3001/api/status" -UseBasicParsing
```

## 📋 Checklist de Verificación

- [ ] El servicio está en estado "Running" en EasyPanel
- [ ] El puerto está configurado correctamente (3001 para instancia 1)
- [ ] Las variables de entorno PORT e INSTANCE_NUMBER están configuradas
- [ ] Los logs muestran "Servidor iniciado en puerto 3001"
- [ ] No hay errores en los logs
- [ ] El firewall permite conexiones al puerto 3001
- [ ] El dominio está configurado correctamente en EasyPanel (si aplica)

## 🆘 Si Nada Funciona

1. **Recrear el servicio:**
   - En EasyPanel, elimina el servicio actual
   - Crea uno nuevo con la configuración correcta
   - Verifica que todas las variables de entorno estén correctas

2. **Verificar conectividad de red:**
   - Desde otro dispositivo, prueba acceder al servidor
   - Verifica que el DNS resuelva correctamente `api1.checkin24hs.com`
   - Prueba acceder por IP directamente si el DNS falla

3. **Contactar soporte:**
   - Si usas un servicio de hosting, contacta su soporte
   - Proporciona los logs del servicio
   - Menciona el error específico que estás viendo

## 💡 Notas Importantes

- ⚠️ **El puerto debe ser 3001, NO 80** - Si ves "Servidor corriendo en puerto 80" en los logs, está mal configurado
- ✅ **El servicio debe estar en estado "Running"** - Si está detenido, no será accesible
- 🔄 **Reinicia el servicio después de cambiar configuración** - Los cambios no se aplican hasta reiniciar
- 📱 **Verifica los logs siempre** - Te darán información sobre qué está fallando

---

**Última actualización:** Enero 2025
