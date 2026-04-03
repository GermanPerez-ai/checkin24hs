# 🔒 Guía Paso a Paso: Configurar HTTPS con EasyPanel

## 📋 Resumen

Vamos a configurar HTTPS para los 4 servicios de WhatsApp usando EasyPanel/Traefik. Esto tomará aproximadamente **10-15 minutos**.

---

## ✅ Paso 1: Agregar Registros DNS en Hostinger

### 1.1. Acceder a Hostinger

1. Ve a [hpanel.hostinger.com](https://hpanel.hostinger.com)
2. Inicia sesión con tus credenciales
3. Selecciona el dominio `checkin24hs.com`

### 1.2. Ir a DNS

1. En el menú lateral, busca **"DNS"** o **"Zona DNS"**
2. Haz clic para abrir la configuración DNS

### 1.3. Agregar 4 Registros Tipo A

Agrega estos **4 registros** uno por uno:

#### Registro 1:
- **Tipo**: `A`
- **Nombre**: `api1`
- **Apunta a**: `72.61.58.240`
- **TTL**: `14400` (o el valor por defecto)
- Haz clic en **"Agregar"** o **"Guardar"**

#### Registro 2:
- **Tipo**: `A`
- **Nombre**: `api2`
- **Apunta a**: `72.61.58.240`
- **TTL**: `14400`
- Haz clic en **"Agregar"** o **"Guardar"**

#### Registro 3:
- **Tipo**: `A`
- **Nombre**: `api3`
- **Apunta a**: `72.61.58.240`
- **TTL**: `14400`
- Haz clic en **"Agregar"** o **"Guardar"**

#### Registro 4:
- **Tipo**: `A`
- **Nombre**: `api4`
- **Apunta a**: `72.61.58.240`
- **TTL**: `14400`
- Haz clic en **"Agregar"** o **"Guardar"**

### 1.4. Verificar

Después de agregar los 4 registros, deberías ver algo como:

```
api1.checkin24hs.com    A    72.61.58.240    14400
api2.checkin24hs.com    A    72.61.58.240    14400
api3.checkin24hs.com    A    72.61.58.240    14400
api4.checkin24hs.com    A    72.61.58.240    14400
```

### 1.5. Esperar Propagación

⏰ **Espera 5-10 minutos** para que los cambios DNS se propaguen.

**Verificar propagación** (opcional):
```bash
# En PowerShell o terminal
nslookup api1.checkin24hs.com
nslookup api2.checkin24hs.com
```

Deberías ver `72.61.58.240` como respuesta.

---

## ✅ Paso 2: Configurar en EasyPanel

### 2.1. Acceder a EasyPanel

1. Ve a tu panel de EasyPanel (normalmente `http://tu-servidor:3000` o similar)
2. Inicia sesión

### 2.2. Configurar Servicio 1: `whatsapp` (Puerto 3001)

1. **Ve a "Servicios"** o **"Services"** en el menú lateral
2. **Busca y selecciona** el servicio `whatsapp` (o el nombre que tenga)
3. **Haz clic en "Dominios"** o **"Domains"** en el menú del servicio
4. **Haz clic en "Agregar Dominio"** o **"Add Domain"**
5. **Configura**:
   - **Dominio**: `api1.checkin24hs.com`
   - **Puerto**: `3001` (verifica que sea el puerto correcto del servicio)
   - **SSL/TLS**: ✅ **Marca esta casilla** para activar HTTPS
6. **Guarda** los cambios
7. **Espera 1-2 minutos** para que Traefik obtenga el certificado SSL

### 2.3. Configurar Servicio 2: `whatsapp2` (Puerto 3002)

1. **Selecciona** el servicio `whatsapp2` (o el nombre correspondiente)
2. **Ve a "Dominios"**
3. **Agrega dominio**:
   - **Dominio**: `api2.checkin24hs.com`
   - **Puerto**: `3002`
   - **SSL/TLS**: ✅ **Activar**
4. **Guarda** y espera 1-2 minutos

### 2.4. Configurar Servicio 3: `whatsapp3` (Puerto 3003)

1. **Selecciona** el servicio `whatsapp3`
2. **Ve a "Dominios"**
3. **Agrega dominio**:
   - **Dominio**: `api3.checkin24hs.com`
   - **Puerto**: `3003`
   - **SSL/TLS**: ✅ **Activar**
4. **Guarda** y espera 1-2 minutos

### 2.5. Configurar Servicio 4: `whatsapp4` (Puerto 3004)

1. **Selecciona** el servicio `whatsapp4`
2. **Ve a "Dominios"**
3. **Agrega dominio**:
   - **Dominio**: `api4.checkin24hs.com`
   - **Puerto**: `3004`
   - **SSL/TLS**: ✅ **Activar**
4. **Guarda** y espera 1-2 minutos

---

## ✅ Paso 3: Verificar que HTTPS Funciona

### 3.1. Verificar desde el Navegador

Abre estos enlaces en tu navegador (deberían mostrar un candado 🔒):

- https://api1.checkin24hs.com
- https://api2.checkin24hs.com
- https://api3.checkin24hs.com
- https://api4.checkin24hs.com

### 3.2. Verificar desde Terminal (Opcional)

```bash
# Verificar certificado SSL
curl -I https://api1.checkin24hs.com
curl -I https://api2.checkin24hs.com
curl -I https://api3.checkin24hs.com
curl -I https://api4.checkin24hs.com
```

Deberías ver `HTTP/2 200` o similar.

### 3.3. Verificar API Endpoint

```bash
# Probar endpoint de estado
curl https://api1.checkin24hs.com/api/status?card=1
```

Debería responder con JSON (no error de Mixed Content).

---

## ✅ Paso 4: Actualizar Dashboard

Después de configurar HTTPS, necesitamos actualizar el código del dashboard para usar las URLs HTTPS correctas.

### 4.1. Mapeo de Tarjetas a URLs

- **Tarjeta 1** → `https://api1.checkin24hs.com`
- **Tarjeta 2** → `https://api2.checkin24hs.com`
- **Tarjeta 3** → `https://api3.checkin24hs.com`
- **Tarjeta 4** → `https://api4.checkin24hs.com`

### 4.2. Próximos Pasos

Después de verificar que HTTPS funciona, necesitaremos:

1. Modificar la función `getServerURL()` en `dashboard.html` para usar HTTPS
2. Modificar las funciones de conexión para usar el subdominio correcto según la tarjeta
3. Actualizar el dashboard en el servidor

**¿Quieres que proceda con estos cambios ahora?**

---

## 🎯 Resumen de URLs HTTPS

Después de completar todos los pasos, tendrás:

- ✅ `https://api1.checkin24hs.com` → Puerto 3001 (Tarjeta 1)
- ✅ `https://api2.checkin24hs.com` → Puerto 3002 (Tarjeta 2)
- ✅ `https://api3.checkin24hs.com` → Puerto 3003 (Tarjeta 3)
- ✅ `https://api4.checkin24hs.com` → Puerto 3004 (Tarjeta 4)

---

## ❓ Problemas Comunes

### El dominio no resuelve

- Espera más tiempo (hasta 30 minutos)
- Verifica que los registros DNS estén correctos
- Usa `nslookup api1.checkin24hs.com` para verificar

### El certificado SSL no se genera

- Verifica que el dominio resuelva correctamente primero
- Asegúrate de que el puerto 80 y 443 estén abiertos
- Revisa los logs de Traefik en EasyPanel

### Error 502 Bad Gateway

- Verifica que el servicio WhatsApp esté corriendo
- Verifica que el puerto configurado sea correcto (3001, 3002, 3003, 3004)
- Revisa los logs del servicio en EasyPanel

---

## 📝 Notas

- Los certificados SSL se renuevan automáticamente cada 90 días
- Traefik maneja todo automáticamente, no necesitas hacer nada más
- Si cambias la IP del servidor, actualiza los registros DNS

---

**¿Listo para empezar? Comienza con el Paso 1 y avísame cuando termines cada paso.**









