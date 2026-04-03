# 🚀 Subir Código al Servidor y Construir Imagen Docker

## 🎯 Objetivo

Subir el código directamente al servidor, construir la imagen Docker ahí, y usar esa imagen en EasyPanel (sin depender de GitHub ni del build de EasyPanel).

---

## 📋 Paso 1: Subir Código al Servidor

### Opción A: Usar SCP (Desde Windows con PowerShell)

```powershell
# Conectarte al servidor y subir archivos
scp -r whatsapp-server root@72.61.58.240:/root/checkin24hs/
```

### Opción B: Usar Git en el Servidor (Recomendado)

1. **Conéctate al servidor por SSH**:
   ```bash
   ssh root@72.61.58.240
   ```

2. **Navega al directorio**:
   ```bash
   cd /root/checkin24hs
   ```

3. **Actualiza el repositorio** (si ya existe):
   ```bash
   git pull origin main
   ```

   O **clona el repositorio** (si no existe):
   ```bash
   cd /root
   git clone https://github.com/GermanPerez-ai/checkin24hs.git
   cd checkin24hs
   ```

---

## 📋 Paso 2: Construir la Imagen Docker en el Servidor

1. **Navega a la carpeta whatsapp-server**:
   ```bash
   cd /root/checkin24hs/whatsapp-server
   ```

2. **Verifica que los archivos estén ahí**:
   ```bash
   ls -la
   # Deberías ver: Dockerfile, package.json, whatsapp-server-baileys.js
   ```

3. **Construye la imagen Docker**:
   ```bash
   docker build -t whatsapp-server:latest .
   ```

   **Esto puede tardar 5-10 minutos** la primera vez (descarga Node.js, instala dependencias, etc.)

4. **Verifica que la imagen se construyó**:
   ```bash
   docker images | grep whatsapp-server
   ```

   Deberías ver algo como:
   ```
   whatsapp-server   latest   abc123def456   2 minutes ago   500MB
   ```

---

## 📋 Paso 3: Configurar EasyPanel para Usar la Imagen Local

1. **Ve a EasyPanel** → Servicio `whatsapp`

2. **Ve a "Fuente"** o **"Source"**

3. **Cambia el tipo de fuente**:
   - De **"GitHub"** a **"Imagen Docker"** o **"Docker Image"**
   - (Busca las pestañas: "Github", "Imagen Docker", "Git", etc.)

4. **Ingresa el nombre de la imagen**:
   ```
   whatsapp-server:latest
   ```
   
   **Nota**: Si EasyPanel requiere un formato específico, puede ser:
   - `whatsapp-server:latest`
   - `localhost/whatsapp-server:latest`
   - O el formato que EasyPanel use para imágenes locales

5. **Guarda los cambios**

---

## 📋 Paso 4: Configurar Variables de Entorno (Si No Están)

1. **Ve a "Entorno"** o **"Environment"**
2. **Verifica que estén estas variables**:
   ```bash
   PORT=3001
   INSTANCE_NUMBER=1
   SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   GEMINI_API_KEY=tu_clave_aqui
   BASE_URL=https://whatsapp.checkin24hs.com
   ```
3. **Guarda** si hiciste cambios

---

## 📋 Paso 5: Configurar Comando de Inicio

1. **Ve a "Implementar"** o **"Deploy"**
2. **Verifica que el comando sea**:
   ```
   node whatsapp-server-baileys.js
   ```
3. **Si no está**, agrégalo y guarda

---

## 📋 Paso 6: Desplegar el Servicio

1. **Haz clic en "Implementar"** o **"Deploy"**
2. **Espera 1-2 minutos** (debería ser más rápido porque la imagen ya está construida)
3. **Revisa los logs**:
   - Deberías ver: `🚀 Iniciando servidor WhatsApp con Baileys...`
   - Deberías ver: `✅ Servidor iniciado en puerto 3001`

---

## ✅ Ventajas de Este Método

- ✅ **No depende de GitHub**: El código ya está en el servidor
- ✅ **No depende del build de EasyPanel**: La imagen ya está construida
- ✅ **Más rápido**: Solo necesita iniciar el contenedor
- ✅ **Más control**: Tú controlas cuándo construir la imagen
- ✅ **Evita errores 504**: No hay timeout de build

---

## 🔄 Actualizar el Código en el Futuro

Cuando necesites actualizar el código:

### Opción A: Actualizar desde GitHub

```bash
# En el servidor
cd /root/checkin24hs
git pull origin main
cd whatsapp-server
docker build -t whatsapp-server:latest .
```

Luego en EasyPanel:
- Reinicia el servicio (o haz deploy nuevamente)

### Opción B: Subir Archivos Directamente

```powershell
# Desde tu máquina
scp -r whatsapp-server/* root@72.61.58.240:/root/checkin24hs/whatsapp-server/
```

Luego en el servidor:
```bash
cd /root/checkin24hs/whatsapp-server
docker build -t whatsapp-server:latest .
```

---

## 🔍 Verificar que Funciona

1. **En el servidor**, verifica que la imagen existe:
   ```bash
   docker images | grep whatsapp-server
   ```

2. **En EasyPanel**, verifica los logs:
   - Deberías ver mensajes de inicio del servidor
   - No deberías ver "Waiting for service..." infinito

3. **Prueba el endpoint**:
   ```
   https://whatsapp.checkin24hs.com/api/health
   ```
   Debería responder: `{"status":"ok","instance":1}`

---

## 📝 Resumen de Comandos

### En el Servidor:

```bash
# 1. Ir al directorio
cd /root/checkin24hs

# 2. Actualizar código (si usas Git)
git pull origin main

# 3. Ir a whatsapp-server
cd whatsapp-server

# 4. Construir imagen
docker build -t whatsapp-server:latest .

# 5. Verificar imagen
docker images | grep whatsapp-server
```

### En EasyPanel:

1. **Fuente** → Cambiar a **"Imagen Docker"**
2. **Imagen**: `whatsapp-server:latest`
3. **Guardar**
4. **Implementar**

---

## 🚀 Pasos Rápidos

1. **SSH al servidor**: `ssh root@72.61.58.240`
2. **Actualizar código**: `cd /root/checkin24hs && git pull origin main`
3. **Construir imagen**: `cd whatsapp-server && docker build -t whatsapp-server:latest .`
4. **En EasyPanel**: Cambiar "Fuente" a "Imagen Docker" → `whatsapp-server:latest`
5. **Desplegar**

---

## ⚠️ Nota Importante

Si EasyPanel no encuentra la imagen local, puede que necesites:
- Usar el nombre completo: `localhost/whatsapp-server:latest`
- O configurar el registry local en EasyPanel
- O subir la imagen a un registry (Docker Hub, etc.)

**Si tienes problemas**, comparte el error y te ayudo a solucionarlo.
