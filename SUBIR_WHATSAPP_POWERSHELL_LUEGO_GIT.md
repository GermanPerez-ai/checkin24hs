# 🚀 Subir WhatsApp: PowerShell → Servidor → Git → Docker

## 🎯 Flujo de Trabajo (Como Dashboard y Cotizador)

1. **Subir archivos por PowerShell** (desde tu máquina al servidor)
2. **En el servidor**: Hacer git commit/push (si es necesario)
3. **En el servidor**: Construir imagen Docker
4. **En EasyPanel**: Usar la imagen local

---

## 📋 Paso 1: Subir Archivos por PowerShell

### Desde tu máquina Windows:

```powershell
# Navegar a la carpeta del proyecto
cd C:\Users\German\Downloads\Checkin24hs

# Subir la carpeta whatsapp-server al servidor
scp -r whatsapp-server root@72.61.58.240:/root/checkin24hs/
```

**Esto sube todos los archivos** de `whatsapp-server` al servidor.

---

## 📋 Paso 2: En el Servidor - Verificar y Git (Opcional)

### Conéctate al servidor:

```bash
ssh root@72.61.58.240
```

### Verificar que los archivos se subieron:

```bash
cd /root/checkin24hs/whatsapp-server
ls -la

# Deberías ver:
# - Dockerfile
# - package.json
# - whatsapp-server-baileys.js
# - etc.
```

### Si quieres hacer commit/push (como con dashboard y cotizador):

```bash
# Ir al directorio raíz del proyecto
cd /root/checkin24hs

# Ver qué archivos cambiaron
git status

# Agregar cambios (si hay)
git add whatsapp-server/

# Commit (si es necesario)
git commit -m "Actualizar whatsapp-server"

# Push a GitHub (si quieres)
git push origin main
```

**Nota**: Esto es opcional, pero mantiene el repositorio sincronizado.

---

## 📋 Paso 3: Construir Imagen Docker en el Servidor

```bash
# Asegúrate de estar en la carpeta correcta
cd /root/checkin24hs/whatsapp-server

# Construir la imagen Docker
docker build -t whatsapp-server:latest .

# Esto puede tardar 5-10 minutos la primera vez
```

### Verificar que se construyó:

```bash
docker images | grep whatsapp-server
```

Deberías ver:
```
whatsapp-server   latest   abc123def456   2 minutes ago   500MB
```

---

## 📋 Paso 4: Configurar EasyPanel para Usar la Imagen Local

1. **Ve a EasyPanel** → Servicio `whatsapp`
2. **Ve a "Fuente"** o **"Source"**
3. **Cambia el tipo de fuente**:
   - De **"GitHub"** a **"Imagen Docker"** o **"Docker Image"**
4. **Ingresa la imagen**:
   ```
   whatsapp-server:latest
   ```
5. **Guarda los cambios**

---

## 📋 Paso 5: Verificar Configuración en EasyPanel

### Variables de Entorno:
- `PORT=3001`
- `INSTANCE_NUMBER=1`
- `SUPABASE_URL=...`
- `SUPABASE_ANON_KEY=...`
- `GEMINI_API_KEY=...`
- `BASE_URL=https://whatsapp.checkin24hs.com`

### Comando de Inicio:
- `node whatsapp-server-baileys.js`

---

## 📋 Paso 6: Desplegar

1. **Haz clic en "Implementar"** o **"Deploy"**
2. **Espera 1-2 minutos** (más rápido porque la imagen ya está construida)
3. **Revisa los logs**

---

## 🔄 Flujo Completo (Resumen)

### En tu máquina (PowerShell):

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp -r whatsapp-server root@72.61.58.240:/root/checkin24hs/
```

### En el servidor (SSH):

```bash
# 1. Verificar archivos
cd /root/checkin24hs/whatsapp-server
ls -la

# 2. Git (opcional, como dashboard y cotizador)
cd /root/checkin24hs
git add whatsapp-server/
git commit -m "Actualizar whatsapp-server"
git push origin main

# 3. Construir imagen
cd whatsapp-server
docker build -t whatsapp-server:latest .

# 4. Verificar
docker images | grep whatsapp-server
```

### En EasyPanel:

1. **Fuente** → **"Imagen Docker"**
2. **Imagen**: `whatsapp-server:latest`
3. **Guardar**
4. **Implementar**

---

## ✅ Ventajas de Este Método

- ✅ **Sigue tu flujo habitual**: PowerShell → Servidor → Git
- ✅ **No depende del build de EasyPanel**: La imagen ya está construida
- ✅ **Más rápido**: Solo inicia el contenedor
- ✅ **Control total**: Tú decides cuándo construir
- ✅ **Evita errores 504**: No hay timeout de build

---

## 🔄 Actualizar en el Futuro

Cuando necesites actualizar:

1. **PowerShell**: `scp -r whatsapp-server root@72.61.58.240:/root/checkin24hs/`
2. **Servidor**: `cd /root/checkin24hs/whatsapp-server && docker build -t whatsapp-server:latest .`
3. **EasyPanel**: Reiniciar el servicio (o hacer deploy)

---

## 📝 Comandos Rápidos

### PowerShell (desde tu máquina):
```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp -r whatsapp-server root@72.61.58.240:/root/checkin24hs/
```

### Servidor (SSH):
```bash
cd /root/checkin24hs/whatsapp-server
docker build -t whatsapp-server:latest .
docker images | grep whatsapp-server
```

### EasyPanel:
- Fuente → Imagen Docker → `whatsapp-server:latest` → Guardar → Implementar

---

## 🚀 ¿Listo para Empezar?

1. **Sube los archivos por PowerShell** (como siempre)
2. **Construye la imagen en el servidor**
3. **Configura EasyPanel para usar la imagen local**
4. **Despliega**

¿Quieres que te guíe paso a paso mientras lo haces?
