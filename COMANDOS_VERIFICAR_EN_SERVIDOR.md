# Comandos para Verificar dashboard.html en el Servidor

Estás conectado al servidor Linux (`root@srv1152402`). Ejecuta estos comandos directamente en el servidor:

## Verificación Rápida

```bash
# 1. Verificar conteo de tags <html>
echo "Tags <html>:"
grep -c '<html' /root/checkin24hs/deploy/dashboard.html

# Debe mostrar: 1 (si está correcto)
# Si muestra más de 1, el archivo está corrupto (duplicado)

# 2. Verificar elementos WhatsApp
echo ""
echo "Elementos whatsapp-server-url:"
grep -c 'whatsapp-server-url' /root/checkin24hs/deploy/dashboard.html

# 3. Verificar elementos Knowledge
echo ""
echo "Elementos knowledge-hotel-selector:"
grep -c 'knowledge-hotel-selector' /root/checkin24hs/deploy/dashboard.html

# 4. Verificar tamaño del archivo
echo ""
echo "Tamaño del archivo:"
ls -lh /root/checkin24hs/deploy/dashboard.html

# 5. Ver primeras líneas
echo ""
echo "Primeras 5 líneas:"
head -5 /root/checkin24hs/deploy/dashboard.html

# 6. Ver últimas líneas
echo ""
echo "Últimas 5 líneas:"
tail -5 /root/checkin24hs/deploy/dashboard.html
```

## Si el Archivo Está Corrupto

Si el conteo de tags `<html>` es mayor a 1, el archivo está corrupto. Para corregirlo:

### Opción 1: Desde Windows (tu máquina local)

1. **Abre PowerShell en Windows** (no en el servidor)

2. **Ejecuta:**
   ```powershell
   cd C:\Users\German\Downloads\Checkin24hs
   .\transferir_dashboard.ps1
   ```

3. **Ingresa la contraseña SSH** cuando te la pida

### Opción 2: Transferir el Script de Verificación

**Desde PowerShell en Windows:**
```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp verificar_dashboard_servidor.sh root@72.61.58.240:/root/checkin24hs/
```

**Luego en el servidor (SSH):**
```bash
cd /root/checkin24hs
chmod +x verificar_dashboard_servidor.sh
bash verificar_dashboard_servidor.sh
```


