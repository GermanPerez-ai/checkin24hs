# 🔍 Verificar Logs SSL/Let's Encrypt

## 📋 Comandos para Verificar SSL en el Servidor

### 1. Verificar Certificados SSL Generados

```bash
# Ver certificados de Let's Encrypt
ls -la /etc/letsencrypt/live/configwp.checkin24hs.com/

# O si están en otro lugar
find /etc/letsencrypt -name "*configwp*" -type d
```

### 2. Ver Logs de Let's Encrypt

```bash
# Ver logs de certificados
tail -f /var/log/letsencrypt/letsencrypt.log

# O buscar errores específicos
grep -i error /var/log/letsencrypt/letsencrypt.log | tail -20
```

### 3. Verificar Estado del Certificado

```bash
# Verificar certificado directamente
openssl s_client -connect configwp.checkin24hs.com:443 -servername configwp.checkin24hs.com

# Verificar fecha de expiración
echo | openssl s_client -connect configwp.checkin24hs.com:443 -servername configwp.checkin24hs.com 2>/dev/null | openssl x509 -noout -dates
```

### 4. Verificar Configuración Traefik (si EasyPanel usa Traefik)

```bash
# Ver logs de Traefik
docker logs traefik 2>&1 | grep -i ssl
docker logs traefik 2>&1 | grep -i letsencrypt
docker logs traefik 2>&1 | tail -50
```

### 5. Verificar que el Puerto 443 esté Abierto

```bash
# Verificar que el puerto 443 esté escuchando
netstat -tuln | grep 443
# O
ss -tuln | grep 443
```

### 6. Probar Certificado desde el Servidor

```bash
# Probar HTTPS desde el servidor
curl -I https://configwp.checkin24hs.com

# Ver detalles del certificado
curl -v https://configwp.checkin24hs.com 2>&1 | grep -i ssl
```

---

## 🔧 Solución si el Certificado No se Genera

### Opción 1: Forzar Renovación Manual

```bash
# Si tienes acceso a certbot
certbot certonly --standalone -d configwp.checkin24hs.com

# O renovar todos
certbot renew --force-renewal
```

### Opción 2: Verificar Validación DNS

Let's Encrypt necesita validar el dominio. Verifica:
- DNS resuelve correctamente: `nslookup configwp.checkin24hs.com`
- Puerto 80 está abierto (para validación HTTP)
- El dominio apunta a la IP correcta

### Opción 3: Verificar Configuración en EasyPanel

1. Ve a EasyPanel → Servicio `whatsapp-api`
2. Verifica que el dominio tenga SSL habilitado
3. Revisa si hay opción de "Forzar renovación" o "Regenerar certificado"

---

## ⚠️ Problemas Comunes

### Problema: Puerto 80 Bloqueado
**Solución:** Let's Encrypt necesita el puerto 80 abierto para validar. Verifica:
```bash
# Verificar que el puerto 80 esté abierto
netstat -tuln | grep 80
```

### Problema: DNS No Propagado
**Solución:** Espera más tiempo o verifica DNS:
```bash
nslookup configwp.checkin24hs.com
```

### Problema: Límite de Rate Limiting de Let's Encrypt
**Solución:** Si intentaste muchas veces, espera 1 hora antes de volver a intentar.

---

## 📞 Siguiente Paso

Ejecuta estos comandos en el servidor y comparte los resultados para diagnosticar el problema SSL.


