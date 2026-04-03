# 🚀 Proceso Completo de Deploy - Dashboard WhatsApp

## 📋 Checklist Pre-Deploy

- [x] ✅ Código actualizado y probado localmente
- [x] ✅ Build number incrementado (37 → 38)
- [x] ✅ Script de actualización corregido
- [ ] ⏳ Subir cambios a GitHub
- [ ] ⏳ Hacer deploy en EasyPanel
- [ ] ⏳ Ejecutar script de actualización
- [ ] ⏳ Verificar funcionamiento

---

## 🔄 Paso 1: Subir Cambios a GitHub

### 1.1 Verificar Cambios Locales
```bash
cd ~/checkin24hs
git status
```

### 1.2 Agregar y Commitear
```bash
# Agregar archivos modificados
git add dashboard.html
git add ACTUALIZAR_ARCHIVO_SERVIDOR.sh

# Commitear con mensaje descriptivo
git commit -m "feat: Actualizar configuración WhatsApp con subdominios y optimizar script de actualización

- Actualizar build number a #38
- Mejorar script ACTUALIZAR_ARCHIVO_SERVIDOR.sh para bind mount
- Optimizar detección de subdominios en URLs de WhatsApp
- Agregar herramientas de verificación de servidores"

# Subir a GitHub
git push origin main
```

### 1.3 Verificar en GitHub
- Abre: https://github.com/GermanPerez-ai/checkin24hs
- Verifica que `dashboard.html` tenga Build #38
- Verifica que `ACTUALIZAR_ARCHIVO_SERVIDOR.sh` esté actualizado

---

## 🔧 Paso 2: Deploy en EasyPanel

### 2.1 Acceder a EasyPanel
1. Abre EasyPanel en tu navegador
2. Busca el servicio: `checkin24hs_dashboard`

### 2.2 Verificar Configuración
Asegúrate de que esté configurado:
- **Source**: GitHub
- **Owner**: GermanPerez-ai
- **Repository**: checkin24hs
- **Branch**: main
- **Build Path**: `/` (o la ruta correcta)

### 2.3 Hacer Deploy
1. Haz clic en **"Deploy"** o **"Redeploy"**
2. Espera 3-5 minutos mientras se construye
3. Verifica que el servicio esté en estado "Running" (verde)

### 2.4 Verificar Bind Mount
Si usas bind mount, verifica que esté configurado:
```json
{
  "Type": "bind",
  "Source": "/root/checkin24hs/dashboard.html",
  "Target": "/app/dashboard.html"
}
```

---

## 📥 Paso 3: Ejecutar Script de Actualización

### 3.1 Conectarse al Servidor
```bash
ssh root@72.61.58.240
```

### 3.2 Descargar y Ejecutar Script
```bash
cd ~/checkin24hs

# Descargar script actualizado desde GitHub
curl -s -L -o ACTUALIZAR_ARCHIVO_SERVIDOR.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/ACTUALIZAR_ARCHIVO_SERVIDOR.sh

# Dar permisos de ejecución
chmod +x ACTUALIZAR_ARCHIVO_SERVIDOR.sh

# Ejecutar script
bash ACTUALIZAR_ARCHIVO_SERVIDOR.sh
```

### 3.3 Lo que hace el Script
El script ahora:
1. ✅ Encuentra automáticamente el contenedor del servicio
2. ✅ Crea backup del archivo actual
3. ✅ Descarga `dashboard.html` desde GitHub
4. ✅ Verifica el build number
5. ✅ Copia al bind mount (`/root/checkin24hs/dashboard.html`)
6. ✅ Copia directamente al contenedor (por si acaso)
7. ✅ Verifica que el build number sea correcto
8. ✅ Opcionalmente reinicia el contenedor

---

## ✅ Paso 4: Verificación Post-Deploy

### 4.1 Verificar Build Number
```bash
# Desde el servidor
curl -s https://dashboard.checkin24hs.com | grep 'DASHBOARD_BUILD_NUMBER'

# Deberías ver: window.DASHBOARD_BUILD_NUMBER = 38
```

### 4.2 Verificar en Navegador
1. Abre: https://dashboard.checkin24hs.com
2. Presiona **Ctrl + Shift + R** (limpiar caché)
3. Ve a: **Flor IA** → **WhatsApp**
4. Verifica que aparezca:
   - Campo de URL con placeholder recomendado
   - Mensajes de ayuda
   - 4 tarjetas de WhatsApp

### 4.3 Verificar Funcionalidad
1. Configura la URL: `https://checkin24hs.com`
2. Haz clic en "Guardar"
3. Verifica que las tarjetas se carguen
4. Prueba hacer clic en "Conectar" (puede haber CORS si estás local, pero funciona en servidor)

### 4.4 Verificar Servidores WhatsApp
```bash
# Ejecutar verificador de servidores
curl -s https://api1.checkin24hs.com/api/status
curl -s https://api2.checkin24hs.com/api/status
curl -s https://api3.checkin24hs.com/api/status
curl -s https://api4.checkin24hs.com/api/status
```

---

## 🔄 Paso 5: Reaplicar Labels de Traefik (Si es Necesario)

Si hay problemas con Traefik después del deploy:

```bash
cd ~/checkin24hs

# Descargar script de Traefik
curl -s -L -o REAPLICAR_TRAEFIK_LABELS.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/REAPLICAR_TRAEFIK_LABELS.sh

chmod +x REAPLICAR_TRAEFIK_LABELS.sh
bash REAPLICAR_TRAEFIK_LABELS.sh
```

---

## 🐛 Solución de Problemas

### Problema: El build number no cambia
**Solución**: 
1. Verifica que el commit esté en GitHub
2. Verifica que el script descargue correctamente
3. Verifica los permisos del bind mount

### Problema: No encuentra el contenedor
**Solución**:
```bash
# Verificar nombre exacto del servicio
docker service ls | grep dashboard

# Actualizar el nombre en el script si es diferente
```

### Problema: Bind mount no funciona
**Solución**:
- El script ahora también copia directamente al contenedor como respaldo
- Verifica que la ruta del bind mount sea correcta en EasyPanel

### Problema: Traefik no actualiza
**Solución**:
- Ejecuta `REAPLICAR_TRAEFIK_LABELS.sh`
- Reinicia Traefik si es necesario

---

## 📝 Notas Importantes

1. **Build Number**: Siempre incrementa el build number antes de hacer commit
2. **Bind Mount**: Si usas bind mount, el archivo se actualiza automáticamente
3. **Caché**: Limpia caché del navegador (Ctrl+Shift+R) después del deploy
4. **Backup**: El script siempre crea un backup antes de actualizar
5. **Verificación**: Siempre verifica el build number después del deploy

---

## 🎯 Resumen Rápido

```bash
# 1. Subir a GitHub
git add dashboard.html ACTUALIZAR_ARCHIVO_SERVIDOR.sh
git commit -m "feat: Actualizar a Build #38"
git push origin main

# 2. En el servidor
ssh root@72.61.58.240
cd ~/checkin24hs
curl -s -L -o ACTUALIZAR_ARCHIVO_SERVIDOR.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/ACTUALIZAR_ARCHIVO_SERVIDOR.sh
chmod +x ACTUALIZAR_ARCHIVO_SERVIDOR.sh
bash ACTUALIZAR_ARCHIVO_SERVIDOR.sh

# 3. Verificar
curl -s https://dashboard.checkin24hs.com | grep 'DASHBOARD_BUILD_NUMBER'
```

---

**✅ Listo para deploy!** 🚀
