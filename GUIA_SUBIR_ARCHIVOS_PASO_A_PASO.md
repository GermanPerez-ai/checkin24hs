# 📤 Guía Paso a Paso: Subir Archivos de Flor IA

## 🎯 Archivos a Subir

1. `flor-ai-service.js` → `/root/checkin24hs/flor-ai-service.js`
2. `deploy/flor-ai-service.js` → `/root/checkin24hs/deploy/flor-ai-service.js`

---

## 📋 MÉTODO 1: Usando PowerShell (Recomendado)

### Paso 1: Abre PowerShell

1. Presiona `Windows + X`
2. Selecciona **"Windows PowerShell"** o **"Terminal"**

### Paso 2: Navega al directorio

```powershell
cd C:\Users\German\Downloads\Checkin24hs
```

### Paso 3: Sube el primer archivo

```powershell
scp flor-ai-service.js root@72.61.58.240:/root/checkin24hs/flor-ai-service.js
```

**Cuando te pida la contraseña:**
- Ingresa la contraseña SSH del servidor
- No verás los caracteres mientras escribes (es normal)
- Presiona Enter

### Paso 4: Sube el segundo archivo

```powershell
scp deploy\flor-ai-service.js root@72.61.58.240:/root/checkin24hs/deploy/flor-ai-service.js
```

**Nuevamente ingresa la contraseña cuando te la pida**

### Paso 5: Verifica que se subieron

```powershell
ssh root@72.61.58.240 "grep -n 'TU MISIÓN PRINCIPAL' /root/checkin24hs/flor-ai-service.js"
```

Si aparece una línea con números, el archivo está correcto ✅

---

## 📋 MÉTODO 2: Usando WinSCP (Interfaz Gráfica)

### Paso 1: Descarga WinSCP

1. Ve a: https://winscp.net/eng/download.php
2. Descarga e instala WinSCP

### Paso 2: Conecta al servidor

1. Abre WinSCP
2. Configuración:
   - **Protocolo:** SFTP
   - **Host:** `72.61.58.240`
   - **Usuario:** `root`
   - **Contraseña:** [Tu contraseña SSH]
3. Haz clic en **"Login"**

### Paso 3: Navega a la carpeta destino

En el panel derecho (servidor):
- Ve a: `/root/checkin24hs/`

### Paso 4: Arrastra y suelta

1. En el panel izquierdo (tu PC), navega a:
   - `C:\Users\German\Downloads\Checkin24hs`
2. Arrastra `flor-ai-service.js` al panel derecho
3. Arrastra `deploy\flor-ai-service.js` al panel derecho (dentro de la carpeta `deploy`)

---

## 📋 MÉTODO 3: Usando el Script Automático

### Paso 1: Ejecuta el script

```powershell
cd C:\Users\German\Downloads\Checkin24hs
powershell -ExecutionPolicy Bypass -File SUBIR_FLOR_MEJORADA.ps1
```

### Paso 2: Ingresa la contraseña

Cuando te la pida, ingrésala (no verás los caracteres)

---

## ✅ Verificación Después de Subir

### Verificar que los archivos están en el servidor:

**Opción A - Desde PowerShell:**
```powershell
ssh root@72.61.58.240 "ls -lh /root/checkin24hs/flor-ai-service.js /root/checkin24hs/deploy/flor-ai-service.js"
```

**Opción B - Verificar contenido:**
```powershell
ssh root@72.61.58.240 "grep -c 'TU MISIÓN PRINCIPAL' /root/checkin24hs/flor-ai-service.js"
```

Si devuelve `1` o más, el archivo tiene las mejoras ✅

---

## 🔄 Reiniciar el Servicio

Después de subir los archivos, reinicia el servicio de WhatsApp:

**Desde PowerShell:**
```powershell
ssh root@72.61.58.240 "CONTAINER=`$(docker ps --filter 'name=whatsapp.1' --format '{{.Names}}' | head -1); docker restart `$CONTAINER"
```

O manualmente:
```powershell
ssh root@72.61.58.240
```

Luego en el servidor:
```bash
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)
docker restart $CONTAINER
docker logs $CONTAINER --tail 20
```

---

## 🆘 Solución de Problemas

### Error: "Permission denied"
- Verifica que tengas acceso SSH al servidor
- Verifica la contraseña

### Error: "No such file or directory"
- Verifica que estés en el directorio correcto
- Verifica que los archivos existan: `dir flor-ai-service.js`

### Error: "Connection refused"
- Verifica que el servidor esté accesible
- Verifica la IP: `72.61.58.240`

---

## 📝 Checklist

- [ ] Archivo 1 subido: `flor-ai-service.js`
- [ ] Archivo 2 subido: `deploy/flor-ai-service.js`
- [ ] Archivos verificados en el servidor
- [ ] Servicio de WhatsApp reiniciado
- [ ] Logs verificados (sin errores)

---

**¿Listo para empezar? Elige el método que prefieras y te guío paso a paso!** 🚀


