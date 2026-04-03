# 📤 Instrucciones para Subir Scripts al Servidor

## Opción 1: Usar el Script PowerShell (Recomendado)

1. **Abre PowerShell** en tu computadora
2. **Navega a la carpeta** donde están los scripts:
   ```powershell
   cd C:\Users\German\Downloads\Checkin24hs
   ```
3. **Ejecuta el script:**
   ```powershell
   .\subir_scripts_al_servidor.ps1
   ```
4. **Si te pide confirmación SSH**, acepta (escribir `yes`)
5. **Ingresa tu contraseña** del servidor cuando se solicite

## Opción 2: Usar SCP Manualmente

Si el script PowerShell no funciona, puedes usar SCP directamente:

```powershell
# Desde PowerShell, en la carpeta Checkin24hs
scp actualizar_webmail_traefik.sh root@72.61.58.240:/root/
scp actualizar_dashboard_traefik.sh root@72.61.58.240:/root/
```

## Opción 3: Crear los Scripts Directamente en el Servidor (SSH)

Si SCP no funciona, puedes crear los archivos directamente en el servidor:

1. **Conéctate al servidor por SSH:**
   ```powershell
   ssh root@72.61.58.240
   ```

2. **Crea el script de webmail:**
   ```bash
   nano /root/actualizar_webmail_traefik.sh
   ```
   
   Luego copia y pega el contenido del archivo `actualizar_webmail_traefik.sh` (está en tu carpeta local).
   
   Para guardar: `Ctrl+X`, luego `Y`, luego `Enter`

3. **Crea el script de dashboard:**
   ```bash
   nano /root/actualizar_dashboard_traefik.sh
   ```
   
   Luego copia y pega el contenido del archivo `actualizar_dashboard_traefik.sh`.
   
   Para guardar: `Ctrl+X`, luego `Y`, luego `Enter`

4. **Haz los scripts ejecutables:**
   ```bash
   chmod +x /root/actualizar_webmail_traefik.sh
   chmod +x /root/actualizar_dashboard_traefik.sh
   ```

## Opción 4: Usar WinSCP (Interfaz Gráfica)

Si prefieres una interfaz gráfica:

1. **Descarga WinSCP** (si no lo tienes): https://winscp.net/
2. **Conéctate al servidor:**
   - Host: `72.61.58.240`
   - Usuario: `root`
   - Contraseña: (tu contraseña)
3. **Navega a `/root/`** en el servidor
4. **Arrastra los archivos** desde tu computadora:
   - `actualizar_webmail_traefik.sh`
   - `actualizar_dashboard_traefik.sh`
5. **Haz clic derecho** en cada archivo → **Propiedades** → Marca **Ejecutable** → **OK**

## ✅ Verificar que los Scripts Están en el Servidor

Después de subir los scripts, verifica:

```bash
# Conéctate por SSH
ssh root@72.61.58.240

# Verifica que los archivos existen
ls -la /root/actualizar_*.sh

# Deberías ver:
# -rwxr-xr-x 1 root root ... actualizar_dashboard_traefik.sh
# -rwxr-xr-x 1 root root ... actualizar_webmail_traefik.sh
```

## 🧪 Probar los Scripts

Una vez que los scripts estén en el servidor y sean ejecutables:

```bash
# Probar el script de webmail
/root/actualizar_webmail_traefik.sh

# Probar el script de dashboard
/root/actualizar_dashboard_traefik.sh
```

## 📝 Notas

- Si tienes problemas con SCP, asegúrate de que SSH esté habilitado en el servidor
- Si usas claves SSH en lugar de contraseña, SCP debería funcionar automáticamente
- Los scripts deben tener permisos de ejecución (`chmod +x`) para funcionar

