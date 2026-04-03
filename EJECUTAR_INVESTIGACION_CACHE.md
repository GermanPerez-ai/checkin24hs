# 🔍 Ejecutar Investigación de Cache Externo

## 📋 Opción 1: Ejecutar Comandos Directamente (Recomendado)

Copia y pega estos comandos uno por uno en el servidor (SSH):

### Comando 1: Headers HTTP
```bash
curl -I https://dashboard.checkin24hs.com 2>&1 | head -20
```

### Comando 2: Verificar CDN/Proxy
```bash
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cf-|cloudflare|cdn-|x-forwarded"
```

### Comando 3: Headers de Caché
```bash
curl -I https://dashboard.checkin24hs.com 2>&1 | grep -iE "cache-control|pragma|expires|etag|last-modified|age|via"
```

### Comando 4: Verificar servicios de caché
```bash
docker ps --format "{{.Names}}" | grep -iE "cache|redis|varnish|nginx|cloudflare"
```

### Comando 5: Verificación completa (verbose)
```bash
curl -v https://dashboard.checkin24hs.com 2>&1 | head -40
```

---

## 📋 Opción 2: Usar el Script Completo

Si prefieres usar el script completo:

1. **Subir el script desde tu computadora (PowerShell):**
```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp INVESTIGAR_CACHE_EXTERNO.sh root@72.61.58.240:/root/checkin24hs/
```

2. **En el servidor (SSH):**
```bash
cd /root/checkin24hs
chmod +x INVESTIGAR_CACHE_EXTERNO.sh
./INVESTIGAR_CACHE_EXTERNO.sh
```

---

**Recomiendo empezar con el Comando 1 (headers HTTP) para ver rápidamente qué está pasando.**
