# Comandos para Consultar Dominios Habilitados

## 🚀 Opción 1: Usar el Script Automático

He creado un script que consulta todo automáticamente. Para usarlo:

```bash
# Descargar el script (si no lo tienes localmente)
# O copiar el contenido de consultar-dominios-servidor.sh

# Dar permisos de ejecución
chmod +x consultar-dominios-servidor.sh

# Ejecutar el script
./consultar-dominios-servidor.sh
```

O ejecutarlo directamente con bash:

```bash
bash consultar-dominios-servidor.sh
```

---

## 📋 Opción 2: Comandos Manuales

Si prefieres ejecutar comandos individuales:

### 1. Ver Dominios en Nginx

```bash
# Ver sitios disponibles
ls -la /etc/nginx/sites-available/

# Ver sitios habilitados
ls -la /etc/nginx/sites-enabled/

# Ver dominios configurados (server_name)
grep -r "server_name" /etc/nginx/sites-enabled/ | grep -v "^#" | grep -v "default"
```

### 2. Ver Certificados SSL

```bash
# Listar certificados SSL activos
ls -la /etc/letsencrypt/live/

# Ver detalles de un certificado específico
sudo certbot certificates

# Ver información de un dominio específico
sudo openssl x509 -in /etc/letsencrypt/live/TU_DOMINIO/cert.pem -noout -text | grep -A 2 "Subject:"
```

### 3. Ver Puertos en Uso

```bash
# Ver puertos HTTP/HTTPS
sudo netstat -tlnp | grep -E ":80 |:443 "

# Ver puertos de aplicaciones (3000-3010)
sudo netstat -tlnp | grep -E ":300[0-9] |:3010 "

# Ver todos los puertos escuchando
sudo ss -tlnp
```

### 4. Ver IP Pública del Servidor

```bash
# Ver IP pública
curl ifconfig.me
# o
curl ipinfo.io/ip
# o
hostname -I
```

### 5. Ver Configuración de DNS (si tienes acceso)

```bash
# Ver hosts locales
cat /etc/hosts | grep -v "^#" | grep -v "^$"

# Consultar DNS de un dominio específico
nslookup TU_DOMINIO.com
# o
dig TU_DOMINIO.com
```

---

## 🔍 Comandos Específicos por Servicio

### Nginx

```bash
# Ver configuración de un sitio específico
cat /etc/nginx/sites-available/TU_SITIO

# Verificar configuración de Nginx
sudo nginx -t

# Ver logs de acceso
sudo tail -f /var/log/nginx/access.log

# Ver logs de error
sudo tail -f /var/log/nginx/error.log
```

### Certbot (Let's Encrypt)

```bash
# Ver todos los certificados
sudo certbot certificates

# Ver detalles de renovación
sudo certbot renew --dry-run

# Ver logs de Certbot
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

---

## 📊 Resumen Rápido

Para una consulta rápida, ejecuta estos comandos:

```bash
echo "=== DOMINIOS EN NGINX ==="
ls /etc/nginx/sites-enabled/

echo ""
echo "=== CERTIFICADOS SSL ==="
ls /etc/letsencrypt/live/ 2>/dev/null || echo "No hay certificados"

echo ""
echo "=== PUERTOS ACTIVOS ==="
sudo netstat -tlnp | grep -E ":80 |:443 |:300[0-9] "

echo ""
echo "=== IP PÚBLICA ==="
curl -s ifconfig.me
```

---

## 💡 Interpretación de Resultados

### Si ves dominios en `/etc/nginx/sites-enabled/`:
- Esos son los dominios configurados en Nginx
- Pueden o no tener SSL configurado

### Si ves certificados en `/etc/letsencrypt/live/`:
- Esos dominios tienen SSL válido
- Los certificados se renuevan automáticamente

### Si ves puertos 80/443 activos:
- El servidor está escuchando en HTTP/HTTPS
- Puedes verificar qué servicio está usando cada puerto

---

## 🎯 Próximos Pasos

Una vez que identifiques los dominios disponibles:

1. **Si tienes un dominio con SSL**: Úsalo en el dashboard
2. **Si tienes un dominio sin SSL**: Configura SSL siguiendo la guía `GUIA_CONFIGURAR_SSL_WHATSAPP_SERVIDOR.md`
3. **Si no tienes dominio**: Configura uno nuevo siguiendo la guía

