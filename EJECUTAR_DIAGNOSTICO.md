# 🔍 Ejecutar Diagnóstico en el Servidor

## 📋 Pasos

### 1. Subir el script de diagnóstico al servidor

**Desde PowerShell:**
```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp DIAGNOSTICO_SERVIDOR.sh root@72.61.58.240:/root/checkin24hs/
```

### 2. Conectarse al servidor y ejecutar el diagnóstico

**En el servidor (SSH):**
```bash
ssh root@72.61.58.240
cd /root/checkin24hs
chmod +x DIAGNOSTICO_SERVIDOR.sh
./DIAGNOSTICO_SERVIDOR.sh
```

### 3. Revisar los resultados

El script verificará:
- ✅ Si el archivo existe en el servidor y en el contenedor
- ✅ El encoding del archivo
- ✅ La estructura del header (si tiene `header-left`)
- ✅ Si los hashes coinciden (si se corrompe al copiar)
- ✅ Si hay proxy/nginx/traefik delante
- ✅ Si `serve-dashboard.js` tiene UTF-8 configurado

### 4. Enviar los resultados

Copia y pega la salida completa del script para que pueda analizarla y determinar:
- Si hay corrupción del archivo
- Si hay un proxy modificando el contenido
- Si falta configurar UTF-8

---

**Después de revisar los resultados, subiremos los archivos corregidos.**
