# 📱 Cómo Conectar 4 Números Diferentes a Evolution API

## ✅ CONFIGURACIÓN (Ya está lista)

Las instancias ya están creadas:
- `whatsapp-1` → Para teléfono número 1
- `whatsapp-2` → Para teléfono número 2
- `whatsapp-3` → Para teléfono número 3
- `whatsapp-4` → Para teléfono número 4

**No necesitas hacer cambios técnicos**, solo conectar cada número a su instancia correspondiente.

---

## 📋 PASOS PARA CONECTAR CADA NÚMERO

### 🔹 **PASO 1: Conectar Teléfono Número 1 a whatsapp-1**

1. **En el teléfono número 1:**
   - Abre WhatsApp
   - Ve a: **Configuración → Dispositivos vinculados**
   - **Desvincula TODOS los dispositivos** (si hay alguno)
   - Cierra WhatsApp completamente
   - Vuelve a abrir WhatsApp

2. **En el panel web (`http://72.61.58.240:8081/manager`):**
   - Haz clic en **whatsapp-1**
   - Haz clic en **"Get QR Code"**
   - **INMEDIATAMENTE** escanea el QR con el **teléfono número 1**
   - Espera 2-3 minutos sin hacer nada

3. **✅ Verifica que whatsapp-1 quede "CONECTADO"**

---

### 🔹 **PASO 2: Conectar Teléfono Número 2 a whatsapp-2**

1. **En el teléfono número 2:**
   - Abre WhatsApp
   - Ve a: **Configuración → Dispositivos vinculados**
   - **Desvincula TODOS los dispositivos** (si hay alguno)
   - Cierra WhatsApp completamente
   - Vuelve a abrir WhatsApp

2. **En el panel web (`http://72.61.58.240:8081/manager`):**
   - Haz clic en **whatsapp-2**
   - Haz clic en **"Get QR Code"**
   - **INMEDIATAMENTE** escanea el QR con el **teléfono número 2**
   - Espera 2-3 minutos sin hacer nada

3. **✅ Verifica que whatsapp-2 quede "CONECTADO"**

---

### 🔹 **PASO 3: Conectar Teléfono Número 3 a whatsapp-3**

1. **En el teléfono número 3:**
   - Abre WhatsApp
   - Ve a: **Configuración → Dispositivos vinculados**
   - **Desvincula TODOS los dispositivos** (si hay alguno)
   - Cierra WhatsApp completamente
   - Vuelve a abrir WhatsApp

2. **En el panel web (`http://72.61.58.240:8081/manager`):**
   - Haz clic en **whatsapp-3**
   - Haz clic en **"Get QR Code"**
   - **INMEDIATAMENTE** escanea el QR con el **teléfono número 3**
   - Espera 2-3 minutos sin hacer nada

3. **✅ Verifica que whatsapp-3 quede "CONECTADO"**

---

### 🔹 **PASO 4: Conectar Teléfono Número 4 a whatsapp-4**

1. **En el teléfono número 4:**
   - Abre WhatsApp
   - Ve a: **Configuración → Dispositivos vinculados**
   - **Desvincula TODOS los dispositivos** (si hay alguno)
   - Cierra WhatsApp completamente
   - Vuelve a abrir WhatsApp

2. **En el panel web (`http://72.61.58.240:8081/manager`):**
   - Haz clic en **whatsapp-4**
   - Haz clic en **"Get QR Code"**
   - **INMEDIATAMENTE** escanea el QR con el **teléfono número 4**
   - Espera 2-3 minutos sin hacer nada

3. **✅ Verifica que whatsapp-4 quede "CONECTADO"**

---

## ⚠️ REGLAS IMPORTANTES

1. **✅ Cada instancia usa su propio número**
   - whatsapp-1 → Solo teléfono número 1
   - whatsapp-2 → Solo teléfono número 2
   - whatsapp-3 → Solo teléfono número 3
   - whatsapp-4 → Solo teléfono número 4

2. **❌ NO mezcles números**
   - NO escanees el QR de whatsapp-1 con el teléfono número 2
   - Cada instancia debe usar su número correspondiente

3. **✅ Desvincula antes de conectar**
   - Siempre desvincula todos los dispositivos antes de escanear un nuevo QR
   - Esto evita conflictos de sesión

4. **✅ Conecta uno a la vez**
   - Conecta whatsapp-1 primero
   - Espera a que quede "CONECTADO"
   - Luego conecta whatsapp-2
   - Y así sucesivamente

---

## 🔍 VERIFICAR QUE TODO FUNCIONE

Después de conectar los 4 números, verifica:

```bash
cd /root/checkin24hs/evolution-api

API_KEY="checkin24hs-secret-key-2024"
BASE_URL="http://localhost:8081"

# Ver estado de todas las instancias
curl -s -X GET ${BASE_URL}/instance/fetchInstances \
  -H "apikey: ${API_KEY}" | \
  grep -o '"instanceName":"[^"]*"' | \
  sed 's/"instanceName":"//g' | \
  sed 's/"//g'
```

En el panel web (`http://72.61.58.240:8081/manager`), todas las instancias deberían mostrar:
- ✅ Estado: **"CONECTADO"** (verde)
- ✅ No debería haber errores `device_removed`

---

## 💡 VENTAJAS DE USAR 4 NÚMEROS DIFERENTES

1. ✅ **Evita errores `device_removed`** - Cada número es independiente
2. ✅ **No hay conflictos de sesión** - WhatsApp acepta cada número normalmente
3. ✅ **Más confiable** - Funciona igual que WhatsApp Web normal
4. ✅ **Sin cambios técnicos** - Evolution API funciona igual, solo usas números diferentes

---

## ❓ ¿Problemas?

Si alguna instancia no conecta:

1. **Verifica que usaste el número correcto** (ej: whatsapp-1 con teléfono 1)
2. **Desvincula todos los dispositivos** en el teléfono
3. **Espera 30 segundos** antes de escanear el QR
4. **Escanea el QR dentro de los primeros 10 segundos** después de generarlo
5. **Espera 2-3 minutos** sin hacer nada después de escanear

Si el problema persiste, comparte qué instancia falla y qué error aparece.

---

## 🎯 RESULTADO FINAL

Al final, deberías tener:
- ✅ whatsapp-1 CONECTADO (con teléfono número 1)
- ✅ whatsapp-2 CONECTADO (con teléfono número 2)
- ✅ whatsapp-3 CONECTADO (con teléfono número 3)
- ✅ whatsapp-4 CONECTADO (con teléfono número 4)

**¡Cada instancia funcionando con su propio número!**
