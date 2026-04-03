# 🚀 Ejecutar Verificación de CRM

## 📋 Pasos para Ejecutar el Script

### Opción 1: Desde el Servidor (SSH)

1. **Conectarte al servidor:**
   ```bash
   ssh root@tu-servidor-ip
   # O
   ssh usuario@tu-servidor-ip
   ```

2. **Navegar al directorio del proyecto:**
   ```bash
   cd ~/checkin24hs
   # O donde esté tu proyecto
   ```

3. **Subir el script (si no está en el servidor):**
   ```bash
   # Desde tu máquina local (PowerShell)
   scp VERIFICAR_CRM_CHECKIN24HS.sh root@tu-servidor-ip:~/checkin24hs/
   ```

4. **Dar permisos de ejecución:**
   ```bash
   chmod +x VERIFICAR_CRM_CHECKIN24HS.sh
   ```

5. **Ejecutar el script:**
   ```bash
   ./VERIFICAR_CRM_CHECKIN24HS.sh
   ```

---

### Opción 2: Ejecutar Comandos Manualmente

Si prefieres ejecutar los comandos uno por uno:

```bash
# 1. Verificar si el servicio existe
docker service ls | grep crm

# 2. Si existe, ver detalles
docker service inspect checkin24hs_crm

# 3. Ver contenedores activos
docker ps | grep crm

# 4. Verificar Traefik
docker service logs traefik --tail 100 | grep -i crm

# 5. Verificar DNS
nslookup crm.checkin24hs.com

# 6. Verificar archivos
ls -la crm/
```

---

### Opción 3: Desde EasyPanel (Terminal)

1. **Acceder a EasyPanel:**
   - Ve a tu panel de EasyPanel
   - Busca la opción "Terminal" o "SSH"

2. **Ejecutar comandos:**
   ```bash
   cd /root/checkin24hs
   chmod +x VERIFICAR_CRM_CHECKIN24HS.sh
   ./VERIFICAR_CRM_CHECKIN24HS.sh
   ```

---

## 📤 Subir el Script al Servidor

Si el script no está en el servidor, súbelo desde PowerShell:

```powershell
# Desde PowerShell en tu máquina local
cd C:\Users\German\Downloads\Checkin24hs

# Subir el script
scp VERIFICAR_CRM_CHECKIN24HS.sh root@tu-servidor-ip:/root/checkin24hs/

# O si usas otro usuario
scp VERIFICAR_CRM_CHECKIN24HS.sh usuario@tu-servidor-ip:~/checkin24hs/
```

**Nota:** Reemplaza `tu-servidor-ip` con la IP real de tu servidor.

---

## ✅ Resultado Esperado

El script mostrará:

1. ✅ **Si el servicio existe o no**
2. ✅ **Estado del servicio** (si existe)
3. ✅ **Configuración de Traefik** (si está configurado)
4. ✅ **Contenedores activos**
5. ✅ **Referencias en código**
6. ✅ **Resolución DNS**

Y al final dará una **recomendación** sobre si se puede eliminar o no.

---

## 🔍 Interpretar los Resultados

### Si el servicio NO existe:
```
❌ Servicio NO encontrado: checkin24hs_crm
```
✅ **Puedes eliminar:**
- DNS de `crm.checkin24hs.com`
- Archivos del directorio `crm/` (si no los usas)
- Scripts de configuración obsoletos

### Si el servicio SÍ existe:
```
✅ Servicio encontrado: checkin24hs_crm
```
⚠️ **Verificar:**
- Si está activo o detenido
- Si Traefik está configurado
- Si realmente lo necesitas

---

## 📝 Después de Ejecutar

Una vez que tengas los resultados, puedes:

1. **Si no usas el CRM:**
   - Eliminar el servicio: `docker service rm checkin24hs_crm`
   - Eliminar DNS
   - Archivar o eliminar archivos

2. **Si sí usas el CRM:**
   - Verificar que esté configurado correctamente
   - Asegurarte de que Traefik esté funcionando
