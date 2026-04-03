# 📱 Guía de Configuración de QR para WhatsApp

## 📋 Índice

1. [Introducción](#introducción)
2. [Cómo Funciona el QR](#cómo-funciona-el-qr)
3. [Configuración Básica](#configuración-básica)
4. [Herramientas de Gestión](#herramientas-de-gestión)
5. [Solución de Problemas](#solución-de-problemas)
6. [Preguntas Frecuentes](#preguntas-frecuentes)

---

## 🎯 Introducción

Esta guía te ayudará a configurar y gestionar el código QR para conectar WhatsApp a tu servidor Checkin24hs.

El sistema usa **Baileys** para conectarse a WhatsApp mediante un código QR que debes escanear con tu teléfono.

---

## 🔄 Cómo Funciona el QR

### Flujo de Conexión

1. **Servidor inicia** → Genera un código QR único
2. **QR se muestra** → En logs, panel web o dashboard
3. **Escaneas el QR** → Con WhatsApp desde tu teléfono
4. **WhatsApp se conecta** → El servidor puede enviar/recibir mensajes

### Dónde Ver el QR

- **Panel Web**: `http://TU_IP:3001` (para instancia 1)
- **Logs del servidor**: En la terminal o panel de control
- **Dashboard**: En la sección de WhatsApp
- **API**: `GET http://TU_IP:3001/api/qr`

---

## ⚙️ Configuración Básica

### 1. Configurar Variables de Entorno

```bash
# Puerto del servidor
PORT=3001

# Número de instancia (1-4)
INSTANCE_NUMBER=1

# URL base del servidor (opcional)
BASE_URL=http://tu-servidor.com

# Claves de API
GEMINI_API_KEY=tu_clave_aqui
SUPABASE_URL=tu_url_supabase
SUPABASE_ANON_KEY=tu_clave_anon
```

### 2. Iniciar el Servidor

```bash
cd whatsapp-server
npm install
npm start
```

### 3. Ver el QR

El QR aparecerá automáticamente en:
- Los logs de la consola
- El panel web en `http://localhost:3001`
- A través de la API `/api/qr`

---

## 🛠️ Herramientas de Gestión

### Script de Configuración Interactivo

Usa el script `configurar-qr.js` para gestionar el QR fácilmente:

```bash
cd whatsapp-server
node configurar-qr.js
```

**Opciones disponibles:**

1. **Ver estado de conexión** - Verifica si WhatsApp está conectado
2. **Obtener código QR** - Descarga el QR actual
3. **Guardar QR como imagen** - Guarda el QR en un archivo PNG
4. **Verificar todas las instancias** - Revisa el estado de las 4 instancias
5. **Limpiar sesión** - Elimina la sesión para generar nuevo QR
6. **Configurar URL del servidor** - Define la URL base del servidor

### Ejemplos de Uso

#### Verificar Estado de una Instancia

```bash
node configurar-qr.js
# Selecciona opción 1
# Ingresa el número de instancia (1-4)
```

#### Guardar QR como Imagen

```bash
node configurar-qr.js
# Selecciona opción 3
# Ingresa el número de instancia
# Ingresa el nombre del archivo (o Enter para usar el predeterminado)
```

#### Limpiar Sesión y Generar Nuevo QR

```bash
node configurar-qr.js
# Selecciona opción 5
# Ingresa el número de instancia
# Confirma la operación
# Reinicia el servidor después
```

---

## 🔧 Endpoints de API

### Obtener Estado

```bash
GET /api/status
```

**Respuesta:**
```json
{
  "connected": true,
  "whatsapp": "connected",
  "flor": "active",
  "autoReply": true,
  "qrCode": "data:image/png;base64,...",
  "phone": "5491234567890",
  "name": "Tu Nombre",
  "instance": 1
}
```

### Obtener QR Code

```bash
GET /api/qr
```

**Respuesta (cuando hay QR):**
```json
{
  "status": "waiting_scan",
  "qr": "qr_string_aqui",
  "qrImage": "data:image/png;base64,...",
  "phone": null,
  "name": null
}
```

**Respuesta (cuando está conectado):**
```json
{
  "status": "connected",
  "qr": null,
  "phone": "5491234567890",
  "name": "Tu Nombre"
}
```

---

## 🐛 Solución de Problemas

### Problema: El QR no aparece

**Solución:**
1. Verifica que el servidor esté corriendo
2. Revisa los logs para errores
3. Limpia la sesión y reinicia:
   ```bash
   node configurar-qr.js
   # Opción 5: Limpiar sesión
   ```
4. Reinicia el servidor

### Problema: El QR expira muy rápido

**Solución:**
El QR expira después de ~2 minutos. Si expira:
- Espera unos segundos para que se genere uno nuevo
- O limpia la sesión y reinicia el servidor

### Problema: "device_removed" error

**Solución:**
Este error ocurre cuando hay conflicto de sesión:
1. El servidor automáticamente limpia la sesión
2. Espera unos segundos
3. Se generará un nuevo QR automáticamente

### Problema: No se puede conectar

**Verifica:**
- ✅ El puerto está abierto en el firewall
- ✅ La URL del servidor es correcta
- ✅ No hay otras sesiones activas en el teléfono
- ✅ La conexión a internet está funcionando

---

## ❓ Preguntas Frecuentes

### ¿Necesito escanear el QR cada vez?

**No.** Una vez que escaneas el QR, la sesión se guarda. Solo necesitas escanear nuevamente si:
- Limpias la sesión manualmente
- Eliminas los archivos de autenticación
- WhatsApp te desconecta por inactividad

### ¿Puedo usar el mismo teléfono para múltiples instancias?

**Sí, con WhatsApp Business:**
- WhatsApp Business permite hasta 4 cuentas en un teléfono
- Cada cuenta puede escanear su propio QR

### ¿Cuánto tiempo tarda en conectar?

**Típicamente:**
- Generación de QR: 1-5 segundos
- Después de escanear: 10-60 segundos para autenticación completa

### ¿Puedo usar el QR sin internet?

**No.** El servidor necesita conexión a internet para conectarse a WhatsApp.

### ¿Cómo cambio el tamaño del QR?

El QR se genera automáticamente con tamaño optimizado. Si necesitas cambiarlo:
- Edita `whatsapp-server-baileys.js`
- Busca `qrcode.toDataURL` y modifica el parámetro `width`

---

## 📚 Recursos Adicionales

- [Documentación de Baileys](https://github.com/WhiskeySockets/Baileys)
- [README Principal](./README.md)
- [Instrucciones Docker](./INSTRUCCIONES_DOCKER.md)
- [Instrucciones EasyPanel](./INSTRUCCIONES_EASYPANEL.md)

---

## 🆘 Soporte

Si tienes problemas:

1. Revisa los logs del servidor
2. Usa `configurar-qr.js` para diagnosticar
3. Verifica la documentación de Baileys
4. Limpia la sesión y reinicia

---

**Última actualización:** Enero 2025
