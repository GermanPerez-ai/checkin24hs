# Instrucciones para Transferir dashboard.html

## Opción 1: Usando PowerShell (Recomendado)

1. **Ejecutar el script de transferencia:**
   ```powershell
   cd C:\Users\German\Downloads\Checkin24hs
   .\transferir_dashboard.ps1
   ```

2. **Cuando te pida la contraseña SSH, ingresala manualmente.**

3. **Después de la transferencia, conectarte al servidor y verificar:**
   ```bash
   ssh root@72.61.58.240
   bash verificar_dashboard_servidor.sh
   ```

## Opción 2: Usando SCP Manualmente

**En PowerShell:**
```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html
```

Ingresa la contraseña cuando te la pida.

## Opción 3: Usando WinSCP (Interfaz Gráfica)

1. **Descargar WinSCP:** https://winscp.net/

2. **Conectar al servidor:**
   - Host: `72.61.58.240`
   - Usuario: `root`
   - Contraseña: (tu contraseña SSH)
   - Protocolo: SFTP

3. **Navegar a:** `/root/checkin24hs/deploy/`

4. **Arrastrar** `deploy\dashboard.html` desde tu máquina local a esa carpeta en el servidor.

## Verificación en el Servidor

**Después de transferir, conectarte por SSH y ejecutar:**

```bash
ssh root@72.61.58.240
cd /root/checkin24hs
bash verificar_dashboard_servidor.sh
```

**O verificar manualmente:**

```bash
# Verificar que solo tiene 1 tag <html>
grep -c '<html' /root/checkin24hs/deploy/dashboard.html

# Debe mostrar: 1

# Verificar elementos WhatsApp
grep -c 'whatsapp-server-url' /root/checkin24hs/deploy/dashboard.html

# Debe mostrar: al menos 1

# Verificar elementos Knowledge
grep -c 'knowledge-hotel-selector' /root/checkin24hs/deploy/dashboard.html

# Debe mostrar: al menos 1
```

## Si el Archivo Está Corrupto en el Servidor

Si después de transferir, el archivo sigue corrupto (más de 1 tag `<html>`), intenta:

1. **Eliminar el archivo en el servidor:**
   ```bash
   rm /root/checkin24hs/deploy/dashboard.html
   ```

2. **Transferir nuevamente** desde tu máquina local.

3. **Verificar nuevamente** usando el script de verificación.

## Copiar a Contenedores Docker (Si es Necesario)

**Si necesitas copiar el archivo a los contenedores Docker:**

```bash
# Encontrar contenedores
docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}"

# Copiar a cada contenedor
docker cp /root/checkin24hs/deploy/dashboard.html CONTAINER_NAME:/app/dashboard.html

# Reiniciar contenedores
docker restart CONTAINER_NAME
```


