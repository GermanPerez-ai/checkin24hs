# 🔍 Comandos para Verificar dashboard.html en el Servidor

## Si ya estás conectado al servidor (root@srv1152402)

### Verificar directamente:

```bash
# Contar tags <html> (debe ser 1)
grep -c '<html' /root/checkin24hs/deploy/dashboard.html

# Contar tags </html> (debe ser 1)
grep -c '</html>' /root/checkin24hs/deploy/dashboard.html

# Contar líneas totales
wc -l /root/checkin24hs/deploy/dashboard.html

# Verificar elementos de WhatsApp (debe ser 1 cada uno)
grep -c 'whatsapp-server-url' /root/checkin24hs/deploy/dashboard.html
grep -c 'whatsapp-cards-container' /root/checkin24hs/deploy/dashboard.html

# Verificar elementos de Knowledge (debe ser 1 cada uno)
grep -c 'knowledge-hotel-selector' /root/checkin24hs/deploy/dashboard.html
grep -c 'hotels-knowledge-list' /root/checkin24hs/deploy/dashboard.html

# Ver primeras líneas
head -5 /root/checkin24hs/deploy/dashboard.html

# Ver últimas líneas
tail -5 /root/checkin24hs/deploy/dashboard.html
```

### Usar el script de verificación:

```bash
# Copiar el script al servidor (desde tu máquina local)
scp verificar_dashboard_servidor.sh root@72.61.58.240:/root/

# En el servidor, ejecutar:
chmod +x /root/verificar_dashboard_servidor.sh
/root/verificar_dashboard_servidor.sh
```

## Si el archivo está corrupto (muestra 3 tags <html>)

### Transferir el archivo correcto desde Windows:

```powershell
# Desde PowerShell en tu máquina local
cd C:\Users\German\Downloads\Checkin24hs

# Transferir el archivo
scp -o StrictHostKeyChecking=no "deploy\dashboard.html" "root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html"
```

### O usar el script PowerShell:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
.\transferir_dashboard_correcto.ps1
```

## Después de transferir

### En el servidor, verificar de nuevo:

```bash
# Verificar que ahora tiene 1 tag <html>
grep -c '<html' /root/checkin24hs/deploy/dashboard.html
# Debe mostrar: 1

# Si EasyPanel usa Docker, puede necesitar reiniciar el servicio
# O si el archivo está en un volumen montado, verificar que se actualizó
```

## Nota sobre srv1152402 vs 72.61.58.240

Si estás en `srv1152402` y necesitas conectarte a `72.61.58.240`, pueden ser:
- El mismo servidor con diferentes nombres
- Diferentes servidores

Si son el mismo servidor, puedes verificar directamente:

```bash
# Si ya estás en el servidor correcto
cd /root/checkin24hs
grep -c '<html' deploy/dashboard.html
```

