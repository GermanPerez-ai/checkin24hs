# ✅ Verificación de Variables de Entorno - Roundcube

## 📋 Variables Configuradas

Tus variables de entorno están configuradas así:

```env
ROUNDCUBEMAIL_DEFAULT_HOST=72.61.58.240
ROUNDCUBEMAIL_DEFAULT_PORT=143
ROUNDCUBEMAIL_SMTP_SERVER=72.61.58.240
ROUNDCUBEMAIL_SMTP_PORT=587
ROUNDCUBEMAIL_PLUGINS=archive,zipdownload
ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=5M
```

## ✅ Análisis

### Correcto ✅
- **ROUNDCUBEMAIL_DEFAULT_HOST**: IP del servidor de correo (correcto)
- **ROUNDCUBEMAIL_SMTP_SERVER**: IP del servidor SMTP (correcto)
- **ROUNDCUBEMAIL_SMTP_PORT**: 587 (puerto SMTP estándar, correcto)
- **ROUNDCUBEMAIL_PLUGINS**: Plugins configurados (correcto)
- **ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE**: 5M (correcto)

### ⚠️ Nota sobre el Puerto IMAP

**ROUNDCUBEMAIL_DEFAULT_PORT=143** es el puerto IMAP sin SSL.

**Opciones:**
- **143**: IMAP sin SSL/TLS (menos seguro)
- **993**: IMAP con SSL/TLS (recomendado, más seguro)

Si tu servidor de correo soporta SSL (que es lo recomendado), deberías cambiar a:

```env
ROUNDCUBEMAIL_DEFAULT_PORT=993
```

Y también agregar:

```env
ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
```

## 🔧 Configuración Recomendada (con SSL)

Si tu servidor de correo soporta SSL (recomendado):

```env
ROUNDCUBEMAIL_DEFAULT_HOST=72.61.58.240
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true
ROUNDCUBEMAIL_SMTP_SERVER=72.61.58.240
ROUNDCUBEMAIL_SMTP_PORT=587
ROUNDCUBEMAIL_SMTP_USER=%u
ROUNDCUBEMAIL_SMTP_PASS=%p
ROUNDCUBEMAIL_PLUGINS=archive,zipdownload
ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=5M
```

## 📋 Próximos Pasos

Ahora que las variables están configuradas:

1. ✅ **Guarda las variables de entorno** (si hiciste cambios)
2. ✅ **Verifica "Recursos"**:
   - Reserva de memoria: 512 MB
   - Límite de memoria: 1024 MB
   - Reserva de CPU: 0.5
   - Límite de CPU: 1.0
3. ✅ **Verifica "Dominios"**:
   - Puerto: 8080 (NO 80)
   - Protocolo: HTTP
4. ✅ **Haz clic en "Implementar"** (botón verde)
5. ✅ **Espera 1-2 minutos**
6. ✅ **Observa los logs** para ver si inicia correctamente

## 🎯 Orden de Verificación Final

Antes de hacer clic en "Implementar", verifica:

- [ ] **Recursos**: Memoria 512/1024 MB, CPU 0.5/1.0
- [ ] **Dominio**: Puerto 8080 configurado
- [ ] **Variables de entorno**: Guardadas (como las mostraste)
- [ ] **Sin conflictos**: roundcube y webmail usan puertos diferentes

## 💡 Nota sobre el Puerto IMAP

Si no estás seguro si tu servidor soporta SSL:
- **Deja 143** si no tienes SSL configurado
- **Cambia a 993** si tienes SSL configurado (más seguro)

El error 503 no está relacionado con estas variables, pero es bueno tenerlas correctas para cuando el servicio inicie.

