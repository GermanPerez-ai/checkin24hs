# 🗑️ Eliminar Todas las Conexiones de WhatsApp

## ⚠️ ADVERTENCIA

Este proceso eliminará:
- ✅ Procesos PM2 de WhatsApp
- ✅ Archivos de sesión
- ✅ Logs
- ⚠️ Opcional: Datos en Supabase

## 📋 Pasos para Eliminar

### Paso 1: Eliminar Procesos y Archivos en el Servidor

```bash
# Conectarse al servidor
ssh root@72.61.58.240

# Ejecutar el script de eliminación
cd /root/checkin24hs
bash ELIMINAR_CONEXIONES_WHATSAPP.sh
```

O ejecutar manualmente:

```bash
# Detener y eliminar procesos PM2
pm2 stop whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4
pm2 delete whatsapp-1 whatsapp-2 whatsapp-3 whatsapp-4
pm2 save

# Eliminar archivos de sesión
rm -rf /root/checkin24hs/whatsapp-server/.wwebjs_auth
rm -rf /root/checkin24hs/whatsapp-server/.wwebjs_cache
rm -rf /root/checkin24hs/whatsapp-server/session

# Eliminar logs
rm -rf /root/checkin24hs/whatsapp-server/logs/*whatsapp*

# Verificar que se eliminó todo
pm2 list
```

### Paso 2: Limpiar Base de Datos (Opcional)

Si quieres eliminar también los datos en Supabase:

1. **Opción A: Solo resetear estados (recomendado)**
   - Ejecuta en Supabase SQL Editor:
   ```sql
   UPDATE whatsapp_cards 
   SET 
       status = 'disconnected',
       phone = '-',
       name = '-',
       qr = NULL,
       qr_data = NULL,
       connection_id = NULL,
       connected_at = NULL,
       updated_at = NOW();
   ```

2. **Opción B: Eliminar completamente**
   - Ejecuta en Supabase SQL Editor:
   ```sql
   DELETE FROM whatsapp_cards;
   ```

3. **Opción C: Eliminar TODO (mensajes, chats, conexiones)**
   - Ejecuta en Supabase SQL Editor:
   ```sql
   DELETE FROM whatsapp_messages;
   DELETE FROM whatsapp_chats;
   DELETE FROM whatsapp_cards;
   ```

## ✅ Verificación Post-Eliminación

```bash
# Verificar PM2 (debe estar vacío de procesos WhatsApp)
pm2 list

# Verificar puertos (deben estar libres)
netstat -tulpn | grep -E "3001|3002|3003|3004|4001|4002|4003|4004"

# Verificar archivos de sesión (no deben existir)
ls -la /root/checkin24hs/whatsapp-server/.wwebjs* 2>/dev/null || echo "✅ No hay archivos de sesión"
```

## 📝 Notas

- Los procesos PM2 se eliminan permanentemente
- Los archivos de sesión se eliminan (necesitarás escanear QR de nuevo si reinicias)
- Los datos en Supabase se mantienen a menos que los elimines manualmente
- Puedes reiniciar los servicios después con `INICIAR_WHATSAPP.sh`

## 🔄 Si Quieres Reiniciar Después

```bash
cd /root/checkin24hs/whatsapp-server
pm2 start ecosystem.config.js
pm2 save
```




