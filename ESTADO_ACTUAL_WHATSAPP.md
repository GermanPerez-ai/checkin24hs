# 📊 Estado Actual de Conexiones WhatsApp

## ❌ RESULTADO: NO HAY CONEXIONES ACTIVAS

Según la verificación realizada:
- **PM2 List:** Tabla vacía - **NO hay procesos corriendo**
- **Estado:** Todas las instancias están **detenidas**

## 🔍 Verificación Detallada

### Comandos Ejecutados:
```bash
pm2 list                    # Resultado: Tabla vacía
netstat -tulpn | grep ...   # Sin resultados
curl localhost:4001/api/status  # Sin respuesta
```

## 📋 Instancias Configuradas (pero no activas)

| Instancia | Nombre PM2 | Puerto | Estado |
|-----------|------------|--------|--------|
| WhatsApp 1 | whatsapp-1 | 4001 | ❌ Detenido |
| WhatsApp 2 | whatsapp-2 | 4002 | ❌ Detenido |
| WhatsApp 3 | whatsapp-3 | 4003 | ❌ Detenido |
| WhatsApp 4 | whatsapp-4 | 4004 | ❌ Detenido |

## ✅ Próximos Pasos para Activar las Conexiones

### Opción 1: Iniciar con ecosystem.config.js (Recomendado)

```bash
cd /root/checkin24hs/whatsapp-server

# Verificar que existe el archivo
ls -la ecosystem.config.js

# Iniciar todas las instancias
pm2 start ecosystem.config.js

# Verificar que iniciaron
pm2 list

# Ver logs
pm2 logs whatsapp-1
```

### Opción 2: Iniciar manualmente una por una

```bash
cd /root/checkin24hs/whatsapp-server

# WhatsApp 1
pm2 start whatsapp-server.js --name whatsapp-1 \
  --env PORT=4001 --env INSTANCE_NUMBER=1 \
  --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co \
  --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4

# WhatsApp 2
pm2 start whatsapp-server.js --name whatsapp-2 \
  --env PORT=4002 --env INSTANCE_NUMBER=2 \
  --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co \
  --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4

# WhatsApp 3
pm2 start whatsapp-server.js --name whatsapp-3 \
  --env PORT=4003 --env INSTANCE_NUMBER=3 \
  --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co \
  --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4

# WhatsApp 4
pm2 start whatsapp-server.js --name whatsapp-4 \
  --env PORT=4004 --env INSTANCE_NUMBER=4 \
  --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co \
  --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4

# Guardar configuración
pm2 save
```

### Opción 3: Verificar si hay procesos con otros nombres

```bash
# Ver todos los procesos de Node.js
ps aux | grep node

# Ver todos los puertos en uso
netstat -tulpn | grep LISTEN

# Ver si hay procesos de WhatsApp corriendo de otra forma
ps aux | grep whatsapp
```

## 🔧 Comandos de Verificación Post-Inicio

Una vez iniciados los servicios:

```bash
# Ver estado de PM2
pm2 list

# Ver información detallada
pm2 describe whatsapp-1

# Ver logs en tiempo real (verás el QR)
pm2 logs whatsapp-1

# Verificar que los puertos están activos
netstat -tulpn | grep -E "4001|4002|4003|4004"

# Probar API de estado
curl http://localhost:4001/api/status | jq
curl http://localhost:4002/api/status | jq
curl http://localhost:4003/api/status | jq
curl http://localhost:4004/api/status | jq
```

## 📝 Notas Importantes

1. **Primera vez:** Al iniciar, cada instancia generará un código QR que debes escanear con WhatsApp
2. **Logs:** Usa `pm2 logs whatsapp-1` para ver el QR en formato texto/ASCII
3. **Persistencia:** Ejecuta `pm2 save` para que los procesos se inicien automáticamente al reiniciar el servidor
4. **Auto-restart:** Los procesos están configurados para reiniciarse automáticamente si fallan

## 🚨 Si Hay Errores

```bash
# Ver logs de errores
pm2 logs whatsapp-1 --err

# Ver información del proceso
pm2 describe whatsapp-1

# Reiniciar si hay problemas
pm2 restart whatsapp-1

# Verificar dependencias
cd /root/checkin24hs/whatsapp-server
npm list
```




