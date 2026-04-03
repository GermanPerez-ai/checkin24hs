# 📋 Paso 5: Configurar Rutas de Proxy en NGINX

## 🎯 Objetivo
Configurar 4 rutas de proxy reverso en NGINX para redirigir el tráfico a los puertos de WhatsApp:
- `/api1/` → Puerto 3001
- `/api2/` → Puerto 3002
- `/api3/` → Puerto 3003
- `/api4/` → Puerto 3004

---

## 📝 Instrucciones Detalladas

### 5.1. Buscar la Sección NGINX

Después de cerrar el modal del dominio, busca en la configuración del servicio:

**Opciones donde puede estar:**
- **Sección "NGINX"** en el menú lateral izquierdo
- **Pestaña "NGINX"** en la parte superior
- **"Rutas"** o **"Routes"** o **"Proxy Routes"**
- **"Configuración NGINX"** o **"NGINX Config"**
- Puede estar dentro de **"Configuración"** o **"Settings"**

---

### 5.2. Configurar Rutas de Proxy

Una vez que encuentres la sección NGINX, deberías ver opciones para agregar rutas. Busca:

**Campos comunes:**
- **"Path"** o **"Ruta"** → Para la ruta (ej: `/api1/`)
- **"Target"** o **"Destino"** → Para el destino (ej: `127.0.0.1:3001`)
- **"Backend"** o **"Upstream"** → Para el servidor backend
- Botón **"Agregar Ruta"** o **"Add Route"** o **"+"**

---

### 5.3. Agregar las 4 Rutas

Agrega cada ruta una por una:

#### Ruta 1: WhatsApp Instancia 1
- **Path/Ruta**: `/api1/`
- **Target/Destino**: `127.0.0.1:3001`
- **Protocolo**: `HTTP` (si te lo pide)
- Haz clic en **"Agregar"** o **"Guardar"**

#### Ruta 2: WhatsApp Instancia 2
- **Path/Ruta**: `/api2/`
- **Target/Destino**: `127.0.0.1:3002`
- **Protocolo**: `HTTP`
- Haz clic en **"Agregar"** o **"Guardar"**

#### Ruta 3: WhatsApp Instancia 3
- **Path/Ruta**: `/api3/`
- **Target/Destino**: `127.0.0.1:3003`
- **Protocolo**: `HTTP`
- Haz clic en **"Agregar"** o **"Guardar"**

#### Ruta 4: WhatsApp Instancia 4
- **Path/Ruta**: `/api4/`
- **Target/Destino**: `127.0.0.1:3004`
- **Protocolo**: `HTTP`
- Haz clic en **"Agregar"** o **"Guardar"**

---

### 5.4. Opciones Importantes

**Si ves estas opciones, configúralas así:**

- **"Preserve Path"** o **"Preservar Ruta"**: ✅ **Activar** (marca esta opción si existe)
- **"Strip Path"** o **"Eliminar Ruta"**: ❌ **Desactivar** (no marcar)
- **"Rewrite"**: Dejar vacío o usar `/` si es necesario

---

## ✅ Verificación

Después de agregar las 4 rutas, deberías ver una lista con:
- ✅ `/api1/` → `127.0.0.1:3001`
- ✅ `/api2/` → `127.0.0.1:3002`
- ✅ `/api3/` → `127.0.0.1:3003`
- ✅ `/api4/` → `127.0.0.1:3004`

---

## 🆘 Si Tienes Problemas

### Problema: No encuentro la sección NGINX
**Solución:**
- Verifica que el módulo NGINX esté activado (deberías haberlo activado antes)
- Busca en el menú lateral izquierdo
- Puede estar en "Configuración avanzada" o "Advanced"

### Problema: No veo opción para agregar rutas
**Solución:**
- Puede que necesites editar el archivo de configuración NGINX directamente
- O puede estar en una sección diferente como "Proxy" o "Routes"

### Problema: Las rutas no funcionan
**Solución:**
- Verifica que los puertos 3001-3004 estén corriendo
- Asegúrate de usar `127.0.0.1` (no `localhost`)
- Verifica que las rutas terminen con `/` (ej: `/api1/` no `/api1`)

---

## ➡️ Siguiente Paso

Una vez que hayas configurado las 4 rutas, avísame y pasamos al **Paso 6: Verificar que todo funcione**.

---

## 📸 Ayuda Visual

Si puedes, toma una captura de pantalla de:
1. La sección NGINX o Rutas
2. El formulario para agregar rutas
3. La lista de rutas configuradas

Esto me ayudará a guiarte mejor.


