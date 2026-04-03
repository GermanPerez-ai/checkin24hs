# 🔍 Verificar SSL con Traefik

## Comandos para Verificar

### 1. Verificar si el Certificado Existe

```bash
# Verificar si existe el certificado para configwp
ls -la /etc/letsencrypt/live/configwp.checkin24hs.com/ 2>/dev/null

# O buscar en todos los certificados
ls -la /etc/letsencrypt/live/ | grep configwp
```

### 2. Ver Logs de Traefik (EasyPanel usa Traefik)

```bash
# Ver logs de Traefik
docker logs traefik 2>&1 | grep -i configwp | tail -30

# Ver todos los logs recientes de Traefik
docker logs traefik --tail 100 2>&1 | grep -i ssl

# Ver errores relacionados con Let's Encrypt
docker logs traefik 2>&1 | grep -i "letsencrypt\|acme\|certificate" | tail -30
```

### 3. Verificar Contenedores de Traefik

```bash
# Ver contenedores de Traefik corriendo
docker ps | grep traefik

# Ver configuración de Traefik
docker exec traefik cat /etc/traefik/traefik.yml 2>/dev/null
```

### 4. Verificar Archivos de Certificado de Traefik

```bash
# Traefik puede guardar certificados en diferentes lugares
find /var/lib/docker/volumes -name "*configwp*" 2>/dev/null
find /etc/traefik -name "*configwp*" 2>/dev/null
```

### 5. Probar HTTPS desde el Servidor

```bash
# Probar HTTPS
curl -v https://configwp.checkin24hs.com 2>&1 | head -30

# Ver detalles del certificado
echo | openssl s_client -connect configwp.checkin24hs.com:443 -servername configwp.checkin24hs.com 2>&1 | grep -A 5 "Certificate chain"
```


