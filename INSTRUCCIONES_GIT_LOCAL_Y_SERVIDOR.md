# 📤 Instrucciones: Subir Cambios a GitHub (Local → GitHub → Servidor)

## ⚠️ IMPORTANTE: Orden Correcto

1. **LOCAL (tu Windows):** Hacer `git add`, `git commit`, `git push`
2. **SERVIDOR:** Después del push, hacer `git pull` para actualizar

---

## 🖥️ PASO 1: En tu Máquina LOCAL (Windows)

### 1.1 Abre PowerShell o CMD en tu Windows

Navega al directorio del proyecto:
```bash
cd C:\Users\German\Downloads\Checkin24hs
```

### 1.2 Verifica qué archivos cambiaron
```bash
git status
```

**Debes ver:**
- ✅ `dashboard.html` (modificado)
- ✅ `server.js` (modificado)
- ✅ `package.json` (modificado)
- ❌ `.env` (NO debe aparecer - está ignorado)

### 1.3 Agrega los archivos al staging
```bash
git add dashboard.html server.js package.json
```

### 1.4 Haz commit
```bash
git commit -m "Mover API Keys al backend - Seguridad mejorada"
```

### 1.5 Sube a GitHub
```bash
git push origin main
```

(O `git push origin master` si tu rama se llama `master`)

---

## 🖥️ PASO 2: En el SERVIDOR (después del push)

### 2.1 Conéctate al servidor vía SSH
```bash
ssh root@srv1152402
```

### 2.2 Navega al directorio del proyecto

**IMPORTANTE:** Necesitas ir al directorio donde está tu proyecto en el servidor.

Ejemplo:
```bash
cd /ruta/al/proyecto
# O donde esté tu proyecto, por ejemplo:
# cd /var/www/checkin24hs
# cd /home/checkin24hs
# cd /opt/checkin24hs
```

**¿No sabes dónde está?** Busca el directorio:
```bash
find / -name "server.js" -type f 2>/dev/null | grep -v node_modules
```

### 2.3 Actualiza el código desde GitHub
```bash
git pull origin main
```

(O `git pull origin master` si tu rama se llama `master`)

### 2.4 Instala dotenv (si no está instalado)
```bash
npm install dotenv
```

### 2.5 Crea el archivo `.env` en el servidor

**⚠️ CRÍTICO:** El archivo `.env` NO se sube automáticamente. Debes crearlo manualmente en el servidor.

```bash
nano .env
```

Pega este contenido (con tu API Key):
```env
GEMINI_API_KEY=AIzaSyDvza5tlt0fjEgTamUKG1ZjTuqU8qjCaxI
GEMINI_MODEL=gemini-2.5-flash
```

Guarda y salir:
- `Ctrl + X`
- `Y` (confirmar)
- `Enter` (salir)

### 2.6 Reinicia el servidor

**Si usas PM2:**
```bash
pm2 restart server.js
# O
pm2 restart all
```

**Si usas Docker:**
```bash
docker-compose restart
# O reinicia el contenedor según tu configuración
```

**Si ejecutas node directamente:**
- Detén el proceso (Ctrl+C) y reinicia:
```bash
node server.js
```

---

## ✅ Verificación Final

### En el servidor, verifica que todo funciona:

1. **Verifica que el archivo `.env` existe:**
   ```bash
   cat .env
   ```

2. **Verifica que el servidor carga la API Key:**
   - Revisa los logs del servidor
   - Debe mostrar: `🔑 GEMINI_API_KEY: ✅ Configurada`

3. **Prueba el dashboard en producción:**
   - Ve a tu dashboard en producción
   - Prueba "Probar Conexión" en Flor IA
   - Debe funcionar ✅

---

## 🔍 Problemas Comunes

### Error: "not a git repository"
**Causa:** No estás en el directorio correcto del proyecto.

**Solución:**
```bash
# En LOCAL (Windows):
cd C:\Users\German\Downloads\Checkin24hs

# En SERVIDOR:
cd /ruta/al/proyecto  # Reemplaza con la ruta real
```

### Error: "fatal: no upstream branch"
**Causa:** La rama no está configurada.

**Solución:**
```bash
git push -u origin main
```

### El archivo `.env` no se crea en el servidor
**Solución:** Debes crearlo manualmente. El `.env` NO se sube a GitHub por seguridad.

---

## 📋 Checklist

### LOCAL (Windows):
- [ ] Navegué al directorio del proyecto
- [ ] Verifiqué `git status`
- [ ] Hice `git add dashboard.html server.js package.json`
- [ ] Hice `git commit`
- [ ] Hice `git push origin main`

### SERVIDOR:
- [ ] Conecté vía SSH
- [ ] Navegué al directorio del proyecto
- [ ] Hice `git pull origin main`
- [ ] Instalé `dotenv` (si era necesario)
- [ ] Creé el archivo `.env` con la API Key
- [ ] Reinicié el servidor
- [ ] Verifiqué que funciona

---

**¡Ahora sí, sigue estos pasos en orden!** 🚀
