# 🚀 Proceso Completo: Subir dashboard.html Funcionando al Servidor

## 📋 Resumen

Este proceso te guiará paso a paso para subir tu `dashboard.html` funcionando al servidor y verificar que funcione correctamente.

---

## ✅ Paso 1: Verificar el Archivo Local

**Asegúrate de que `dashboard.html` funciona localmente:**

1. Abre el archivo en tu navegador: `file:///C:/Users/German/Downloads/Checkin24hs/dashboard.html`
2. Verifica que:
   - ✅ Puedes iniciar sesión
   - ✅ Puedes navegar entre pestañas
   - ✅ No hay errores en la consola (F12)

**Si funciona localmente, continúa al Paso 2.**

---

## 📤 Paso 2: Subir el Archivo al Servidor

### Opción A: Usando PowerShell (Recomendado)

**En PowerShell, ejecuta:**

```powershell
# 1. Ir a la carpeta
cd C:\Users\German\Downloads\Checkin24hs

# 2. Subir el archivo
scp dashboard.html root@72.61.58.240:/tmp/dashboard.html

# 3. Conectarte al servidor
ssh root@72.61.58.240
```

**Si te pide contraseña, ingrésala.**

### Opción B: Usando WinSCP (Más Fácil)

1. **Descarga WinSCP:** https://winscp.net/
2. **Conecta al servidor:**
   - Host: `72.61.58.240`
   - Usuario: `root`
   - Contraseña: (la de tu servidor)
   - Protocolo: SFTP
3. **Arrastra `dashboard.html`** a `/tmp/` en el servidor

---

## 🔧 Paso 3: Aplicar el Archivo en el Servidor

**Una vez conectado al servidor por SSH, ejecuta:**

```bash
# 1. Descargar el script de reemplazo
curl -o reemplazar_dashboard.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/reemplazar_dashboard_servidor.sh
chmod +x reemplazar_dashboard.sh

# 2. Ejecutar el script
./reemplazar_dashboard.sh
```

**El script hará automáticamente:**
- ✅ Buscar el contenedor del dashboard
- ✅ Hacer backup del archivo actual
- ✅ Copiar tu `dashboard.html` al contenedor
- ✅ Reiniciar el contenedor
- ✅ Mostrar los logs

---

## ✅ Paso 4: Verificar que Funciona

**Después de ejecutar el script:**

1. **Abre el dashboard:** `https://dashboard.checkin24hs.com`
2. **Presiona Ctrl+F5** (limpiar caché completamente)
3. **Abre la consola (F12)**
4. **Verifica:**
   - ❌ NO debe aparecer: `Identifier 'saveHotelChanges' has already been declared`
   - ❌ NO debe aparecer: `searchUsers is not defined`
   - ❌ NO debe aparecer: `window.showSection is not a function`
   - ✅ Debe aparecer: `✅ Cliente de Supabase inicializado correctamente`
5. **Prueba:**
   - Iniciar sesión
   - Navegar entre pestañas (Dashboard, Hoteles, Reservas, etc.)

---

## 🔍 Paso 5: Si Aún No Funciona

### Verificar que el Archivo se Copió Correctamente

**En el servidor, ejecuta:**

```bash
# Verificar que el archivo está en el contenedor
CONTAINER_ID=$(docker ps | grep dashboard | awk '{print $1}' | head -1)
docker exec $CONTAINER_ID ls -lh /app/dashboard.html

# Verificar el tamaño del archivo (debe ser similar al local)
docker exec $CONTAINER_ID wc -l /app/dashboard.html
```

**Compara con tu archivo local:**
```powershell
# En PowerShell
(Get-Item dashboard.html).Length
Get-Content dashboard.html | Measure-Object -Line
```

### Verificar Logs del Contenedor

```bash
# Ver logs recientes
docker logs $CONTAINER_ID --tail 50
```

### Reiniciar el Contenedor Manualmente

```bash
# Reiniciar
docker restart $CONTAINER_ID

# Esperar 20 segundos
sleep 20

# Verificar que está corriendo
docker ps | grep dashboard
```

---

## 🆘 Solución de Problemas

### Problema: "No se encontró el contenedor"

**Solución:**
```bash
# Ver todos los contenedores
docker ps -a

# Buscar por nombre
docker ps -a | grep -i dashboard
```

### Problema: "El archivo no se copió"

**Solución:**
```bash
# Verificar que existe en /tmp
ls -lh /tmp/dashboard.html

# Copiar manualmente
CONTAINER_ID=$(docker ps | grep dashboard | awk '{print $1}' | head -1)
docker cp /tmp/dashboard.html $CONTAINER_ID:/app/dashboard.html
docker restart $CONTAINER_ID
```

### Problema: "Sigue mostrando errores"

**Solución:**
1. **Limpiar caché del navegador completamente:**
   - Presiona Ctrl+Shift+Delete
   - Selecciona "Todo el tiempo"
   - Marca "Caché" e "Imágenes"
   - Haz clic en "Borrar datos"
2. **Abrir en modo incógnito:** Ctrl+Shift+N
3. **Verificar que el archivo en el servidor es el correcto**

---

## 📝 Comandos Completos (Copia y Pega)

### En PowerShell:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp dashboard.html root@72.61.58.240:/tmp/dashboard.html
ssh root@72.61.58.240
```

### En el Servidor:

```bash
curl -o reemplazar_dashboard.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/reemplazar_dashboard_servidor.sh
chmod +x reemplazar_dashboard.sh
./reemplazar_dashboard.sh
```

---

## ✅ Listo

Una vez que completes estos pasos, el dashboard debería funcionar correctamente en el servidor.

Si encuentras algún problema, comparte:
- El error exacto de la consola
- El resultado de los comandos de verificación
- Cualquier mensaje que veas

