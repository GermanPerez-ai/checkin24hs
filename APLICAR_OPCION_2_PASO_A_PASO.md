# 🚀 Opción 2: Script Automático - Paso a Paso

## 📋 Resumen

Esta opción te permite subir tu `dashboard.html` local directamente al servidor y reemplazarlo automáticamente en el contenedor.

---

## Paso 1: Preparar el archivo local

1. **Abre PowerShell** en tu máquina Windows
2. **Navega a la carpeta del proyecto:**
   ```powershell
   cd C:\Users\German\Downloads\Checkin24hs
   ```
3. **Verifica que `dashboard.html` existe:**
   ```powershell
   ls dashboard.html
   ```

---

## Paso 2: Subir el archivo al servidor

**En PowerShell, ejecuta:**

```powershell
scp dashboard.html root@tu_servidor:/tmp/dashboard.html
```

**Reemplaza `tu_servidor` con:**
- La IP de tu servidor, O
- El hostname de tu servidor (ej: `srv1152402`)

**Ejemplo:**
```powershell
scp dashboard.html root@srv1152402:/tmp/dashboard.html
```

**Si te pide contraseña, ingrésala.**

**Si aparece un error de "host key verification", acepta escribiendo `yes`.**

---

## Paso 3: Conectarte al servidor

**En PowerShell, ejecuta:**

```powershell
ssh root@tu_servidor
```

**Ejemplo:**
```powershell
ssh root@srv1152402
```

**Ingresa tu contraseña cuando te la pida.**

---

## Paso 4: Descargar y ejecutar el script

**Una vez conectado al servidor, ejecuta estos comandos:**

```bash
# 1. Descargar el script
curl -o reemplazar_dashboard.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/reemplazar_dashboard_servidor.sh

# 2. Dar permisos de ejecución
chmod +x reemplazar_dashboard.sh

# 3. Ejecutar el script
./reemplazar_dashboard.sh
```

---

## Paso 5: Verificar

El script hará automáticamente:
- ✅ Buscar el contenedor del dashboard
- ✅ Hacer backup del archivo actual
- ✅ Copiar tu `dashboard.html` al contenedor
- ✅ Reiniciar el contenedor
- ✅ Mostrar los logs

**Al final, te preguntará si quieres eliminar el archivo temporal. Puedes responder `s` (sí) o `n` (no).**

---

## Paso 6: Probar el dashboard

1. **Abre tu navegador:**
   ```
   https://dashboard.checkin24hs.com
   ```

2. **Presiona Ctrl+F5** (limpiar caché)

3. **Abre la consola (F12)**

4. **Verifica que NO hay errores:**
   - ❌ NO debe aparecer: `window.showSection is not a function`
   - ❌ NO debe aparecer: `Cannot access 'allUsersData' before initialization`
   - ✅ Debe aparecer: `✅ Cliente de Supabase inicializado correctamente`

5. **Prueba navegar entre las pestañas** (Dashboard, Hoteles, Reservas, etc.)

---

## 🔧 Solución de Problemas

### Error: "scp: command not found"

**Solución:** Usa WinSCP o PowerShell con OpenSSH instalado.

**Para instalar OpenSSH en Windows:**
```powershell
# En PowerShell como Administrador
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

### Error: "Permission denied"

**Solución:** Verifica que estés usando `root` y la contraseña correcta.

### Error: "No such file or directory" en el servidor

**Solución:** Verifica que el archivo se subió correctamente:
```bash
ls -lh /tmp/dashboard.html
```

Si no existe, vuelve a ejecutar el comando `scp` del Paso 2.

### Error: "No se encontró el contenedor"

**Solución:** El script buscará automáticamente. Si no encuentra nada, verifica manualmente:
```bash
docker ps
```

---

## 📝 Comandos Completos (Copia y Pega)

### En PowerShell (Windows):

```powershell
# 1. Ir a la carpeta
cd C:\Users\German\Downloads\Checkin24hs

# 2. Subir archivo (reemplaza srv1152402 con tu servidor)
scp dashboard.html root@srv1152402:/tmp/dashboard.html

# 3. Conectarse al servidor
ssh root@srv1152402
```

### En el Servidor (SSH):

```bash
# 1. Descargar script
curl -o reemplazar_dashboard.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/reemplazar_dashboard_servidor.sh

# 2. Dar permisos
chmod +x reemplazar_dashboard.sh

# 3. Ejecutar
./reemplazar_dashboard.sh
```

---

## ✅ Listo!

Una vez que el script termine, tu `dashboard.html` local estará funcionando en el servidor.

Si encuentras algún problema, comparte el error y te ayudo a solucionarlo.

