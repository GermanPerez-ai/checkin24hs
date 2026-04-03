# 🔧 Solución Rápida: Error SSL en Webmail

## ❌ Problema
Error `NET::ERR_CERT_AUTHORITY_INVALID` al acceder a `https://webmail.checkin24hs.com`

## ✅ Solución Inmediata: Usar HTTP

**Accede usando HTTP (sin 's'):**
```
http://webmail.checkin24hs.com
```

Esto funcionará inmediatamente, aunque mostrará una advertencia de "No seguro" en el navegador.

---

## 🔒 Solución Permanente: Configurar SSL

### Opción 1: Desde EasyPanel (Recomendado)

1. **Ve a EasyPanel** → **Servicios** → **webmail**
2. **Ve a "Dominios"** o **"Domains"**
3. **Busca** `webmail.checkin24hs.com`
4. **Activa SSL/TLS** (marca la casilla)
5. **Guarda** los cambios
6. **Espera 2-5 minutos** para que Let's Encrypt genere el certificado
7. **Recarga** la página

### Opción 2: Desde el Servidor (Script Automático)

Ejecuta este script en el servidor:

```bash
cd /root/checkin24hs
bash SOLUCIONAR_WEBMAIL_SSL.sh
```

---

## 🔍 Verificar Configuración Actual

Ejecuta estos comandos en el servidor para verificar:

```bash
# 1. Verificar que el servicio existe
docker service ls | grep webmail

# 2. Ver configuración de Traefik
docker service inspect checkin24hs_webmail --format '{{range $k, $v := .Spec.Labels}}{{printf "%s=%s\n" $k $v}}{{end}}' | grep -i traefik

# 3. Verificar DNS
nslookup webmail.checkin24hs.com

# 4. Ver logs de Traefik
docker service logs traefik --tail 50 | grep -i webmail
```

---

## 📋 Checklist

- [ ] DNS configurado: `webmail.checkin24hs.com` → `72.61.58.240`
- [ ] Dominio agregado en EasyPanel
- [ ] SSL/TLS activado en EasyPanel
- [ ] Esperaste 2-5 minutos después de activar SSL
- [ ] Puertos 80 y 443 abiertos en el servidor

---

## 🆘 Si Nada Funciona

1. **Usa HTTP temporalmente**: `http://webmail.checkin24hs.com`
2. **Verifica los logs** del servicio webmail
3. **Verifica que Traefik tenga Let's Encrypt configurado**






