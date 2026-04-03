# 🔧 Solución: Puerto 3001 en Uso

## ❌ Problema

- Puerto 3001 está en uso por otro proceso
- Variables de entorno no se están pasando correctamente

## ✅ Solución

### Paso 1: Ver qué está usando el puerto

```bash
lsof -i :3001
```

O:

```bash
netstat -tulpn | grep 3001
```

### Paso 2: Detener el proceso que usa el puerto

Si es `whatsapp-flor`:

```bash
pm2 stop whatsapp-flor
pm2 delete whatsapp-flor
```

### Paso 3: Reiniciar con variables de entorno correctas

PM2 necesita la sintaxis correcta para variables de entorno:

```bash
pm2 start whatsapp-server.js --name whatsapp-1 --update-env --env PORT=3001 --env INSTANCE_NUMBER=1 --env SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co --env SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

O mejor aún, crear un archivo `.env` y usar `--env-file`:

```bash
echo 'PORT=3001
INSTANCE_NUMBER=1
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4' > .env
```

