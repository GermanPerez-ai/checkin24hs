# 🔍 Comparar Versión Local vs Servidor

## 📋 Método 1: Usar el Script de Verificación (Recomendado)

Ya tienes el script `verificar_version_simple_final.sh` en el servidor. Ejecútalo para comparar:

### En el Servidor (SSH):

```bash
cd /root/checkin24hs
./verificar_version_simple_final.sh
```

Este script te mostrará:
- Versión del archivo local en el servidor
- Versión del archivo en el contenedor
- Si son iguales o diferentes

---

## 📋 Método 2: Comparar desde tu Computadora

### Paso 1: Verificar versión del archivo LOCAL (tu computadora)

Abre PowerShell y ejecuta:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
Select-String -Path dashboard.html -Pattern "window\.DASHBOARD_VERSION = " | Select-Object -First 1
Select-String -Path dashboard.html -Pattern "window\.BUILD_TIMESTAMP = " | Select-Object -First 1
```

O más simple, abre el archivo `dashboard.html` en un editor de texto y busca (Ctrl+F):
- `window.DASHBOARD_VERSION`
- `window.BUILD_TIMESTAMP`

### Paso 2: Verificar versión en Chrome

1. Abre Chrome y ve a: https://dashboard.checkin24hs.com
2. Presiona F12 (herramientas de desarrollador)
3. Ve a la pestaña "Console"
4. Escribe:
   ```javascript
   window.DASHBOARD_VERSION
   window.BUILD_TIMESTAMP
   ```

### Paso 3: Comparar

Si los valores son diferentes, significa que el archivo local NO es el mismo que está en el servidor.

---

## ⚠️ ¿Por qué se ve diferente cuando abres el archivo local?

Cuando abres `dashboard.html` directamente desde tu computadora (file://), puede verse diferente porque:

1. **Falta el servidor**: El archivo necesita un servidor web para funcionar correctamente
2. **Rutas relativas**: Algunos recursos (imágenes, CSS, JS) pueden no cargarse
3. **CORS**: Algunas peticiones a APIs pueden fallar
4. **Autenticación**: El sistema de login puede no funcionar sin el servidor

### Solución: Abrir con un servidor local

Si quieres probar el archivo local correctamente, puedes usar:

**Opción 1: Python (si lo tienes instalado)**
```powershell
cd C:\Users\German\Downloads\Checkin24hs
python -m http.server 8000
```
Luego abre: http://localhost:8000/dashboard.html

**Opción 2: Node.js (si lo tienes instalado)**
```powershell
cd C:\Users\German\Downloads\Checkin24hs
npx http-server -p 8000
```
Luego abre: http://localhost:8000/dashboard.html

---

## 🔄 Sincronizar Archivos

Si el archivo local es diferente al del servidor, tienes dos opciones:

### Opción A: Subir tu versión local al servidor
```powershell
scp dashboard.html root@72.61.58.240:/root/checkin24hs/
```

### Opción B: Descargar la versión del servidor
```powershell
scp root@72.61.58.240:/root/checkin24hs/dashboard.html dashboard.html.servidor
```
