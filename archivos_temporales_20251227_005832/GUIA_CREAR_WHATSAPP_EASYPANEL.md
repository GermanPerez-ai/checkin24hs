# Guía Paso a Paso: Crear 4 Servicios de WhatsApp en EasyPanel

## 📋 Resumen

Vamos a crear 4 servicios de WhatsApp, cada uno en un puerto diferente:
- **whatsapp1** → Puerto 3001 → `https://whatsapp1.checkin24hs.com`
- **whatsapp2** → Puerto 3002 → `https://whatsapp2.checkin24hs.com`
- **whatsapp3** → Puerto 3003 → `https://whatsapp3.checkin24hs.com`
- **whatsapp4** → Puerto 3004 → `https://whatsapp4.checkin24hs.com`

---

## 🔧 Paso 1: Preparar Información

Antes de empezar, necesitas tener esta información lista:

### Variables de Entorno que necesitarás:
```
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Nota:** Si no tienes la `SUPABASE_ANON_KEY`, puedes obtenerla desde tu proyecto de Supabase → Settings → API → anon/public key.

---

## 📱 Paso 2: Crear WhatsApp 1 (Puerto 3001)

### 2.1. Ir a EasyPanel
1. Abre tu navegador y ve a tu panel de EasyPanel
2. Haz clic en **"New Service"** o **"Nuevo Servicio"**

### 2.2. Seleccionar Tipo de Servicio
1. Elige **"App"** o **"Aplicación"**
2. Selecciona **"GitHub"** como fuente

### 2.3. Configurar Repositorio
1. **Repository:** `checkin24hs` (o el nombre de tu repositorio)
2. **Branch:** `main` o `master`
3. **Source Directory:** `/whatsapp-server`

### 2.4. Configurar Nombre y Puerto
1. **Service Name:** `whatsapp1`
2. **Port:** `3001`
3. **Command:** `node whatsapp-server.js`

### 2.5. Configurar Variables de Entorno
En la sección **"Environment Variables"** o **"Variables de Entorno"**, agrega:

```
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**⚠️ IMPORTANTE:** Reemplaza `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` con tu clave real de Supabase.

### 2.6. Configurar Red
1. Asegúrate de que el servicio esté en la red **"easypanel"**
2. Si no aparece automáticamente, agrégalo manualmente

### 2.7. Crear el Servicio
1. Haz clic en **"Create"** o **"Crear"**
2. Espera a que el servicio se inicie (puede tardar 1-2 minutos)

---

## 📱 Paso 3: Crear WhatsApp 2 (Puerto 3002)

Repite los pasos 2.1 a 2.7, pero con estos cambios:

### Cambios para WhatsApp 2:
- **Service Name:** `whatsapp2`
- **Port:** `3002`
- **Variable de Entorno:** `INSTANCE_NUMBER=2` y `PORT=3002`

**Todo lo demás es igual.**

---

## 📱 Paso 4: Crear WhatsApp 3 (Puerto 3003)

Repite los pasos 2.1 a 2.7, pero con estos cambios:

### Cambios para WhatsApp 3:
- **Service Name:** `whatsapp3`
- **Port:** `3003`
- **Variable de Entorno:** `INSTANCE_NUMBER=3` y `PORT=3003`

**Todo lo demás es igual.**

---

## 📱 Paso 5: Crear WhatsApp 4 (Puerto 3004)

Repite los pasos 2.1 a 2.7, pero con estos cambios:

### Cambios para WhatsApp 4:
- **Service Name:** `whatsapp4`
- **Port:** `3004`
- **Variable de Entorno:** `INSTANCE_NUMBER=4` y `PORT=3004`

**Todo lo demás es igual.**

---

## ✅ Paso 6: Verificar que los Servicios Están Corriendo

Ejecuta en el servidor:

```bash
docker service ls | grep -i whatsapp
```

Deberías ver 4 servicios:
- `checkin24hs_whatsapp1`
- `checkin24hs_whatsapp2`
- `checkin24hs_whatsapp3`
- `checkin24hs_whatsapp4`

---

## 🔧 Paso 7: Configurar Traefik

Una vez que los 4 servicios estén corriendo, ejecuta en el servidor:

```bash
cd /root/checkin24hs
bash CONFIGURAR_TRAEFIK_WHATSAPP_TODOS.sh
```

Esto configurará Traefik para que enrute el tráfico a cada servicio.

---

## 🌐 Paso 8: Configurar DNS

Ve a tu panel de DNS y agrega estos registros A:

| Tipo | Nombre | Apunta a | TTL |
|------|--------|----------|-----|
| A | whatsapp1 | 72.61.58.240 | 14400 |
| A | whatsapp2 | 72.61.58.240 | 14400 |
| A | whatsapp3 | 72.61.58.240 | 14400 |
| A | whatsapp4 | 72.61.58.240 | 14400 |

**Nota:** La propagación DNS puede tardar hasta 24 horas, pero generalmente es más rápido (15 minutos - 1 hora).

---

## 🧪 Paso 9: Probar los Servicios

Después de configurar DNS y esperar unos minutos, prueba:

```bash
# Probar WhatsApp 1
curl -I https://whatsapp1.checkin24hs.com

# Probar WhatsApp 2
curl -I https://whatsapp2.checkin24hs.com

# Probar WhatsApp 3
curl -I https://whatsapp3.checkin24hs.com

# Probar WhatsApp 4
curl -I https://whatsapp4.checkin24hs.com
```

Deberías recibir respuestas HTTP 200 o 302 (redirección).

---

## 📝 Resumen de Configuración por Servicio

### WhatsApp 1
```
Nombre: whatsapp1
Puerto: 3001
INSTANCE_NUMBER=1
PORT=3001
Dominio: whatsapp1.checkin24hs.com
```

### WhatsApp 2
```
Nombre: whatsapp2
Puerto: 3002
INSTANCE_NUMBER=2
PORT=3002
Dominio: whatsapp2.checkin24hs.com
```

### WhatsApp 3
```
Nombre: whatsapp3
Puerto: 3003
INSTANCE_NUMBER=3
PORT=3003
Dominio: whatsapp3.checkin24hs.com
```

### WhatsApp 4
```
Nombre: whatsapp4
Puerto: 3004
INSTANCE_NUMBER=4
PORT=3004
Dominio: whatsapp4.checkin24hs.com
```

**Variables comunes para todos:**
```
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=[TU_CLAVE_AQUI]
```

---

## ⚠️ Problemas Comunes

### Error: "Puerto ya en uso"
- Verifica que no haya otro servicio usando el puerto
- Ejecuta: `docker ps | grep 3001` (o el puerto que corresponda)

### Error: "Servicio no inicia"
- Revisa los logs: `docker service logs checkin24hs_whatsapp1 --tail 50`
- Verifica que las variables de entorno estén correctas
- Verifica que el archivo `whatsapp-server.js` exista en `/whatsapp-server`

### Error: "No se puede conectar a Supabase"
- Verifica que `SUPABASE_URL` y `SUPABASE_ANON_KEY` sean correctos
- Prueba la conexión desde el servidor: `curl https://lmoeuyasuvoqhtvhkyia.supabase.co`

---

## 🎯 Checklist Final

- [ ] WhatsApp 1 creado y corriendo
- [ ] WhatsApp 2 creado y corriendo
- [ ] WhatsApp 3 creado y corriendo
- [ ] WhatsApp 4 creado y corriendo
- [ ] Traefik configurado para los 4 servicios
- [ ] DNS configurado para los 4 dominios
- [ ] Certificados SSL generados (automático con Traefik)
- [ ] Servicios accesibles vía HTTPS

---

## 📞 Siguiente Paso

Una vez que hayas creado los 4 servicios, ejecuta el script de configuración de Traefik y luego configura DNS. Si tienes algún problema durante la creación, avísame y te ayudo a resolverlo.






