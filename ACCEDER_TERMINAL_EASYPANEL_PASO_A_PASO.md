# 🖥️ Acceder a Terminal en EasyPanel - Paso a Paso

## 🎯 Opción 1: Terminal desde la Aplicación WhatsApp (Recomendado)

### Paso 1: Abrir la Aplicación WhatsApp

1. **En la pantalla que estás viendo**, busca el proyecto **`checkin24hs`**
2. **Haz clic en la aplicación `whatsapp`** (la que tiene el punto gris - está detenida)
3. Se abrirá la página de detalles de esa aplicación

### Paso 2: Buscar la Terminal

Una vez dentro de la aplicación `whatsapp`, busca en la parte superior estas pestañas:

- **"Terminal"** o **"Shell"** o **"Console"**
- **"Execute"** o **"Exec"**
- **"Command"**

**Haz clic en "Terminal"** → Se abrirá una consola web donde puedes ejecutar comandos.

---

## 🎯 Opción 2: Terminal desde Cualquier Aplicación Activa

Si la aplicación `whatsapp` no tiene terminal, prueba con otra que esté funcionando:

1. **Haz clic en `dashboard`** (tiene punto verde - está funcionando)
2. **Busca la pestaña "Terminal"** o **"Shell"**
3. **Abre la terminal** → Desde ahí puedes navegar a `/root/checkin24hs`

---

## 🎯 Opción 3: Hacer Clic en la IP del Servidor

1. **En la barra lateral izquierda**, busca **`72.61.58.240`** (con el icono de ubicación 📍)
2. **Haz clic en esa IP**
3. Esto debería llevarte a la configuración del servidor
4. **Busca pestañas como**:
   - **"Terminal"**
   - **"SSH"**
   - **"Configuración"** → Dentro puede haber opciones de contraseña

---

## 🎯 Opción 4: Usar "Ajustes" (Settings)

1. **En la barra lateral izquierda**, haz clic en **"Ajustes"** (icono de engranaje ⚙️)
2. **Busca secciones como**:
   - **"Servidores"**
   - **"SSH"**
   - **"Seguridad"**
3. **Busca opciones de contraseña o terminal**

---

## ✅ Solución Rápida: Usar Git (Sin Terminal)

**Si no encuentras la terminal**, puedes hacer todo desde tu máquina:

### Paso 1: Desde tu PowerShell

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Verificar cambios
git status

# Agregar cambios
git add whatsapp-server/

# Commit
git commit -m "Actualizar whatsapp-server para nueva configuración simple"

# Push
git push origin main
```

### Paso 2: Configurar EasyPanel para Usar GitHub

1. **Haz clic en la aplicación `whatsapp`** en EasyPanel
2. **Ve a "Fuente"** o **"Source"**
3. **Configura para usar GitHub**:
   - Repositorio: `GermanPerez-ai/checkin24hs`
   - Rama: `main`
   - Build path: `/whatsapp-server`
4. **Haz clic en "Implementar"** o **"Deploy"**

EasyPanel construirá la imagen automáticamente desde GitHub.

---

## 🔍 ¿Qué Pestañas Ves en la Aplicación WhatsApp?

Cuando hagas clic en `whatsapp`, dime qué pestañas ves en la parte superior:

- ¿Ves **"Logs"**?
- ¿Ves **"Settings"** o **"Configuración"**?
- ¿Ves **"Files"** o **"Archivos"**?
- ¿Ves **"Terminal"** o **"Shell"**?
- ¿Ves **"Overview"** o **"Resumen"**?

---

## 📝 Comandos para la Terminal (Cuando la Encuentres)

Una vez que tengas la terminal abierta:

```bash
# Ir al directorio del proyecto
cd /root/checkin24hs

# Hacer pull desde GitHub
git pull origin main

# Ir a la carpeta de whatsapp-server
cd whatsapp-server

# Verificar archivos
ls -la

# Construir imagen Docker
docker build -t whatsapp-server:latest .

# Verificar que se construyó
docker images | grep whatsapp-server
```

---

## 🚀 Próximo Paso

**Haz clic en la aplicación `whatsapp`** y dime qué pestañas/opciones ves en la parte superior. Con eso te guío exactamente dónde está la terminal.
