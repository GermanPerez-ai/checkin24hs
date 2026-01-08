# 📍 ¿Dónde Configurar WhatsApp?

## 🎯 Respuesta Rápida

Hay **DOS lugares** donde necesitas configurar:

1. **EasyPanel** → Configurar los **servicios** (variables, puertos, comandos)
2. **Dashboard** → Conectar los **WhatsApp** desde la interfaz (abrir modal, escanear QR)

---

## 🔧 1. EASYPANEL (Configuración de Servicios)

### ✅ ¿Qué se hace aquí?

Aquí configuras los **servicios backend** que corren en el servidor:

- ✅ Variables de entorno (`INSTANCE_NUMBER`, `PORT`, `SUPABASE_URL`, etc.)
- ✅ Puertos (3001, 3002, 3003, 3004)
- ✅ Comando de inicio (`node whatsapp-server.js`)
- ✅ Verificar que los servicios estén corriendo (verde)

### 📋 Pasos en EasyPanel:

1. **Editar cada servicio** (`whatsapp`, `whatsapp2`, `whatsapp3`, `whatsapp4`)
2. **Agregar variables de entorno**:
   - `INSTANCE_NUMBER=1` (o 2, 3, 4 según el servicio)
   - `PORT=3001` (o 3002, 3003, 3004)
   - `SUPABASE_URL=...`
   - `SUPABASE_ANON_KEY=...`
3. **Configurar puerto interno**: 3001, 3002, 3003, 3004
4. **Configurar comando de inicio**: `node whatsapp-server.js`
5. **Guardar y reiniciar** el servicio
6. **Verificar** que esté en verde (Running)

### 🎯 Objetivo:

Que los **4 servicios backend** estén corriendo correctamente en el servidor.

---

## 🖥️ 2. DASHBOARD (Conexión de WhatsApp)

### ✅ ¿Qué se hace aquí?

Aquí conectas los **números de WhatsApp** desde la interfaz web:

- ✅ Configurar la URL del servidor
- ✅ Abrir el modal de conexión múltiple
- ✅ Conectar cada instancia (generar QR)
- ✅ Escanear los códigos QR con WhatsApp

### 📋 Pasos en el Dashboard:

1. **Abrir el Dashboard**: Ve a tu dashboard de Checkin24hs
2. **Ir a Flor IA**: Menú lateral → **"Flor IA"**
3. **Abrir pestaña WhatsApp**: Haz clic en **"📱 WhatsApp"**
4. **Configurar URL del servidor**: 
   - En el campo "URL del Servidor WhatsApp"
   - Ingresa: `http://72.61.58.240`
5. **Abrir modal**: Haz clic en **"Conectar Múltiples WhatsApp (hasta 4)"**
6. **Conectar cada instancia**:
   - Verás 4 tarjetas (WhatsApp 1, 2, 3, 4)
   - Haz clic en **"🔗 Conectar"** en cada tarjeta
   - Se generará un código QR para cada una
7. **Escanear QR**: 
   - Abre WhatsApp en tu teléfono
   - Ve a Configuración → Dispositivos vinculados → Vincular un dispositivo
   - Escanea cada QR (uno por cada instancia)

### 🎯 Objetivo:

Conectar los **números de WhatsApp** escaneando los códigos QR.

---

## 📊 Resumen Visual

```
┌─────────────────────────────────────────────────────────┐
│                    EASYPANEL                           │
│  (Configuración de Servicios Backend)                   │
│                                                         │
│  ✅ Variables de entorno                               │
│  ✅ Puertos (3001, 3002, 3003, 3004)                  │
│  ✅ Comandos de inicio                                 │
│  ✅ Verificar que servicios estén corriendo           │
│                                                         │
│  Resultado: 4 servicios backend corriendo             │
└─────────────────────────────────────────────────────────┘
                        ↓
                  (Servicios listos)
                        ↓
┌─────────────────────────────────────────────────────────┐
│                    DASHBOARD                           │
│  (Conexión de Números de WhatsApp)                     │
│                                                         │
│  ✅ Configurar URL del servidor                        │
│  ✅ Abrir modal de conexión                            │
│  ✅ Conectar cada instancia                            │
│  ✅ Escanear códigos QR                                │
│                                                         │
│  Resultado: 4 números de WhatsApp conectados           │
└─────────────────────────────────────────────────────────┘
```

---

## ⚠️ Orden de Configuración

### Paso 1: EasyPanel (PRIMERO)
1. Configura los 4 servicios en EasyPanel
2. Verifica que todos estén corriendo (verde)
3. Verifica que no haya errores en los logs

### Paso 2: Dashboard (DESPUÉS)
1. Una vez que los servicios estén corriendo
2. Ve al dashboard y conecta los WhatsApp
3. Escanea los códigos QR

---

## 🔍 ¿Cómo Saber si Está Bien Configurado?

### ✅ EasyPanel está bien si:
- Los 4 servicios están en **verde (Running)**
- No hay errores en los logs
- Los puertos están configurados correctamente (3001, 3002, 3003, 3004)
- Las variables de entorno están configuradas

### ✅ Dashboard está bien si:
- Puedes abrir el modal de WhatsApp
- Al hacer clic en "Conectar" aparece un QR
- Puedes escanear el QR con WhatsApp
- El estado cambia a "Conectado" después de escanear

---

## 🆘 Si Algo No Funciona

### ❌ Los servicios no inician en EasyPanel:
- Revisa las variables de entorno
- Verifica que los puertos no estén en uso
- Revisa los logs del servicio

### ❌ No puedo conectar desde el Dashboard:
- Verifica que los servicios estén corriendo en EasyPanel
- Verifica la URL del servidor en el dashboard
- Revisa la consola del navegador (F12) para ver errores

### ❌ El QR no aparece:
- Verifica que el servicio esté corriendo
- Elimina la carpeta `.wwebjs_auth` y reinicia el servicio
- Revisa los logs del servicio en EasyPanel

---

## 📝 Checklist Completo

### EasyPanel:
- [ ] Servicio `whatsapp` configurado con INSTANCE_NUMBER=1, PORT=3001
- [ ] Servicio `whatsapp2` configurado con INSTANCE_NUMBER=2, PORT=3002
- [ ] Servicio `whatsapp3` configurado con INSTANCE_NUMBER=3, PORT=3003
- [ ] Servicio `whatsapp4` configurado con INSTANCE_NUMBER=4, PORT=3004
- [ ] Todos los servicios tienen SUPABASE_URL y SUPABASE_ANON_KEY
- [ ] Todos los servicios están en verde (Running)
- [ ] No hay errores en los logs

### Dashboard:
- [ ] Puedo acceder a Flor IA → WhatsApp
- [ ] Configuré la URL del servidor: `http://72.61.58.240`
- [ ] Puedo abrir el modal de conexión múltiple
- [ ] Puedo hacer clic en "Conectar" en cada tarjeta
- [ ] Aparece un QR para cada instancia
- [ ] Puedo escanear los QR con WhatsApp
- [ ] El estado cambia a "Conectado" después de escanear

---

## 🎯 Respuesta Directa

**SÍ, tienes que configurar en EasyPanel** (variables, puertos, comandos).

**Y TAMBIÉN** en el Dashboard (conectar los WhatsApp escaneando QR).

**Primero** configura en EasyPanel, **después** conecta desde el Dashboard.

