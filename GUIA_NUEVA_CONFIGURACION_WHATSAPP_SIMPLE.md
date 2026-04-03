# 🚀 Guía: Nueva Configuración Simple de WhatsApp (1 Teléfono)

## 📋 Pasos a Seguir

### ✅ Paso 1: Crear Servicio en EasyPanel

#### 1.1. Crear Nuevo Servicio

1. **Accede a EasyPanel**: `http://TU_IP:3000`
2. **Clic en "New Service"** o **"Nuevo Servicio"**
3. **Nombre del servicio**: `whatsapp` (simple, sin números)

#### 1.2. Configurar Source (Fuente)

```
Tipo: GitHub
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta de compilación: /whatsapp-server
```

⚠️ **IMPORTANTE**: La ruta debe ser `/whatsapp-server` (con barra inicial, sin barra final)

#### 1.3. Configurar Variables de Entorno

Agrega estas variables en la sección **"Environment"** o **"Variables de Entorno"**:

```bash
PORT=3001
INSTANCE_NUMBER=1
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
GEMINI_API_KEY=tu_clave_gemini_aqui
BASE_URL=https://whatsapp.checkin24hs.com
```

**Notas:**
- `PORT=3001` - Puerto interno del servidor
- `INSTANCE_NUMBER=1` - Siempre 1 (solo 1 conexión)
- `BASE_URL` - URL pública del servicio (usando el DNS que creaste)

#### 1.4. Configurar Puertos

En la sección **"Ports"** o **"Puertos"**:

```
Protocolo: TCP
Publicado: 3001
Destino: 3001
```

#### 1.5. Configurar Build (Compilación)

En la sección **"Build"** o **"Compilación"**:

**IMPORTANTE: Usar Dockerfile**

1. **Selecciona "Dockerfile"** como método de compilación (NO Nixpacks)
2. **Ruta del Dockerfile**: `whatsapp-server/Dockerfile`
3. **Comando de inicio**: `node whatsapp-server-baileys.js`

**Si no ves la opción "Dockerfile":**
- Busca "Build method" o "Tipo de build"
- Cambia de "Nixpacks" o "Auto-detect" a **"Dockerfile"**
- Deja vacíos los campos de "Paquetes Nix" y "Paquetes APT" (el Dockerfile ya los maneja)

#### 1.6. Configurar Auto-Deploy (Opcional pero Recomendado)

```
✅ Habilitado
Rama: main
```

#### 1.7. Guardar y Deploy

1. **Clic en "Save"** o **"Guardar"**
2. **Clic en "Deploy"** o **"Desplegar"**
3. **Esperar** a que el servicio esté en estado **"Running"** (verde) ✅

---

### ✅ Paso 2: Configurar Traefik (HTTPS Automático)

EasyPanel usa Traefik para manejar HTTPS automáticamente. Necesitas agregar labels al servicio:

#### 2.1. Agregar Labels en EasyPanel

En el servicio `whatsapp`, ve a **"Labels"** o **"Etiquetas"** y agrega:

```yaml
traefik.enable: "true"
traefik.http.routers.whatsapp.rule: "Host(`whatsapp.checkin24hs.com`)"
traefik.http.routers.whatsapp.entrypoints: "websecure"
traefik.http.routers.whatsapp.tls.certresolver: "letsencrypt"
traefik.http.services.whatsapp.loadbalancer.server.port: "3001"
```

**Explicación:**
- `traefik.enable: "true"` - Habilita Traefik para este servicio
- `traefik.http.routers.whatsapp.rule` - Regla de enrutamiento (usa el DNS que creaste)
- `traefik.http.routers.whatsapp.entrypoints` - Usa HTTPS
- `traefik.http.routers.whatsapp.tls.certresolver` - Certificado SSL automático
- `traefik.http.services.whatsapp.loadbalancer.server.port` - Puerto interno del servicio

#### 2.2. Guardar y Reiniciar

1. **Guardar** los labels
2. **Reiniciar** el servicio para que Traefik aplique los cambios

---

### ✅ Paso 3: Verificar que el Servicio Funciona

#### 3.1. Verificar Logs

En EasyPanel, ve a la pestaña **"Logs"** del servicio `whatsapp` y busca:

```
✅ Servidor iniciado en puerto 3001
📱 Instancia WhatsApp: 1
🌐 Servidor escuchando en 0.0.0.0:3001
```

#### 3.2. Verificar Endpoints

Abre en tu navegador:

```
https://whatsapp.checkin24hs.com/api/health
```

**Deberías ver:**
```json
{
  "status": "ok",
  "instance": 1
}
```

#### 3.3. Verificar QR

Abre en tu navegador:

```
https://whatsapp.checkin24hs.com/api/qr
```

**Deberías ver:**
- Un código QR (si no está conectado)
- O un mensaje indicando que ya está conectado

---

### ✅ Paso 4: Crear Interfaz Simple en el Dashboard

Ahora necesitamos crear una interfaz simple en el dashboard para:
1. Ver el estado de conexión
2. Ver el QR si no está conectado
3. Conectar el teléfono

**Este paso lo haremos después de verificar que el servicio funciona.**

---

## 📝 Resumen de Configuración

### Servicio EasyPanel:
- **Nombre**: `whatsapp`
- **Puerto**: `3001`
- **Instancia**: `1` (solo 1 teléfono)
- **DNS**: `whatsapp.checkin24hs.com`
- **HTTPS**: Automático con Traefik

### Variables de Entorno:
```
PORT=3001
INSTANCE_NUMBER=1
BASE_URL=https://whatsapp.checkin24hs.com
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
GEMINI_API_KEY=...
```

### Labels Traefik:
```
traefik.enable: "true"
traefik.http.routers.whatsapp.rule: "Host(`whatsapp.checkin24hs.com`)"
traefik.http.routers.whatsapp.entrypoints: "websecure"
traefik.http.routers.whatsapp.tls.certresolver: "letsencrypt"
traefik.http.services.whatsapp.loadbalancer.server.port: "3001"
```

---

## 🎯 Próximos Pasos

1. ✅ Crear servicio en EasyPanel (Paso 1)
2. ✅ Configurar Traefik (Paso 2)
3. ✅ Verificar que funciona (Paso 3)
4. ⏳ Crear interfaz simple en dashboard (Paso 4)

---

## ⚠️ Notas Importantes

- **Solo 1 instancia**: No necesitas múltiples servicios, solo 1
- **Puerto fijo**: Siempre usa puerto 3001
- **DNS simple**: Solo necesitas `whatsapp.checkin24hs.com`
- **HTTPS automático**: Traefik maneja el certificado SSL
- **Usar Dockerfile**: Asegúrate de seleccionar "Dockerfile" en lugar de "Nixpacks" en la configuración de Build

---

## 🔧 Solución de Problemas

### El servicio no inicia:
- Verifica los logs en EasyPanel
- Verifica que las variables de entorno estén correctas
- Verifica que el puerto 3001 no esté en uso
- **Verifica que esté usando Dockerfile**: En los logs de build debe decir "Building Docker image" o "Using Dockerfile", NO "Using Nixpacks"

### No se puede acceder por HTTPS:
- Verifica que los labels de Traefik estén correctos
- Verifica que el DNS apunte correctamente
- Espera unos minutos para que el certificado SSL se genere

### El QR no aparece:
- Verifica que el servicio esté corriendo
- Verifica los logs para ver si hay errores
- Intenta reiniciar el servicio
