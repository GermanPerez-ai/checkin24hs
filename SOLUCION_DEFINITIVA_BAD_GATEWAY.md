# 🔧 Solución Definitiva: Bad Gateway Persistente

## 🚨 Situación

- ✅ Código funciona localmente
- ✅ Código está en GitHub
- ✅ Servicio está en verde en EasyPanel
- ✅ Servidor está funcionando (logs muestran puerto 3000)
- ❌ Sigue dando Bad Gateway

**El problema es de CONFIGURACIÓN DEL SERVIDOR, no del código.**

---

## 🔍 Diagnóstico Completo desde EasyPanel

### Paso 1: Verificar la Configuración del Dominio

1. **En EasyPanel, ve al servicio "dashboard"**
2. **Haz clic en "Domains" o "Dominios"**
3. **Edita `dashboard.checkin24hs.com`**
4. **Verifica EXACTAMENTE estos valores:**
   - **Host:** `dashboard.checkin24hs.com`
   - **HTTPS:** ✅ Activado
   - **Port:** `3000` (puerto interno del contenedor)
   - **Path:** `/`
   - **Internal Protocol:** `http` (NO `https`)
   - **Certificate Resolver:** (puede estar vacío)

5. **Si algo está mal, corrígelo y guarda**

---

### Paso 2: Verificar la Red del Servicio

1. **En EasyPanel, ve al servicio "dashboard"**
2. **Haz clic en "Settings" o "Configuración"**
3. **Busca "Network" o "Red"**
4. **Verifica:**
   - ¿En qué red está?
   - ¿Está en `traefik`?
   - ¿O está en otra red?

5. **Si NO está en `traefik`:**
   - Cámbiala a `traefik`
   - Guarda los cambios
   - Reinicia el servicio

---

### Paso 3: Verificar el Puerto del Servicio

1. **En "Settings" del servicio "dashboard"**
2. **Busca "Ports" o "Puertos"**
3. **Verifica:**
   - **Puerto interno:** Debe ser `3000`
   - **Puerto externo:** Puede ser cualquier cosa (no importa para Traefik)

4. **Si el puerto interno NO es `3000`:**
   - Cámbialo a `3000`
   - Guarda los cambios
   - Reinicia el servicio

---

### Paso 4: Verificar Traefik

1. **En EasyPanel, busca el servicio "traefik"**
2. **Verifica:**
   - ¿Está corriendo? (debe estar en verde 🟢)
   - ¿Está en la misma red que el dashboard?

3. **Si Traefik NO está corriendo:**
   - Inícialo
   - Espera 1-2 minutos

4. **Reinicia Traefik:**
   - Haz clic en "Restart" o "Reiniciar"
   - Espera 1-2 minutos

---

## 🔧 Solución Agresiva: Recrear el Servicio

Si nada funciona, recrea el servicio completamente:

### Paso 1: Anotar la Configuración Actual

Antes de eliminar, anota:
- Repositorio: `https://github.com/GermanPerez-ai/checkin24hs.git`
- Rama: `main`
- Puerto interno: `3000`
- Variable de entorno: `PORT=3000`
- Dominio: `dashboard.checkin24hs.com`

### Paso 2: Eliminar el Servicio Actual

1. **En EasyPanel, haz clic en el servicio "dashboard"**
2. **Busca "Delete" o "Eliminar"**
3. **Confirma la eliminación**

### Paso 3: Crear el Servicio Nuevamente

1. **Crea un nuevo servicio:**
   - **Nombre:** `dashboard`
   - **Tipo:** `App` o `Docker`
   - **Repositorio:** `https://github.com/GermanPerez-ai/checkin24hs.git`
   - **Rama:** `main`
   - **Build Path:** `/`
   - **Dockerfile:** `Dockerfile`

2. **Configuración:**
   - **Puerto interno:** `3000`
   - **Variable de entorno:** `PORT=3000`
   - **Red:** `traefik` (o la red por defecto de EasyPanel)

3. **Dominio:**
   - **Host:** `dashboard.checkin24hs.com`
   - **HTTPS:** ✅ Activado
   - **Port:** `3000`
   - **Internal Protocol:** `http`

4. **Despliega el servicio**

5. **Espera 3-5 minutos** a que se despliegue completamente

6. **Prueba el dashboard**

---

## 🚀 Solución Rápida (Intenta Esto Primero)

**Haz esto en orden:**

1. ✅ **Verifica el dominio:** Puerto `3000`, Protocolo interno `http`
2. ✅ **Verifica la red:** Debe estar en `traefik`
3. ✅ **Reinicia el servicio "dashboard"** desde EasyPanel
4. ✅ **Reinicia el servicio "traefik"** desde EasyPanel
5. ✅ **Espera 2 minutos**
6. ✅ **Prueba el dashboard:** `https://dashboard.checkin24hs.com` (Ctrl+F5)

---

## 📋 Checklist de Verificación

- [ ] Dominio configurado con puerto `3000`
- [ ] Protocolo interno es `http` (no `https`)
- [ ] Servicio está en la red `traefik`
- [ ] Puerto interno del servicio es `3000`
- [ ] Traefik está corriendo (verde 🟢)
- [ ] Reinicié ambos servicios (dashboard y traefik)
- [ ] Esperé 2 minutos después de reiniciar
- [ ] Probé el dashboard con Ctrl+F5

---

## 🆘 Si Nada Funciona

**Última opción: Verificar desde SSH (si puedes acceder al servidor correcto)**

Si puedes acceder al servidor donde está el servicio:

```bash
# Ver todos los contenedores
docker ps

# Ver servicios
docker service ls

# Ver redes
docker network ls

# Ver la red de Traefik
docker network inspect traefik_default

# Ver logs de Traefik
docker logs $(docker ps -q -f name=traefik) --tail 50
```

Pero como no encontramos contenedores antes, esto puede no funcionar.

---

## 💡 Recomendación Final

**El problema más común es:**
1. **El dominio tiene el puerto incorrecto** → Debe ser `3000`
2. **El protocolo interno es `https`** → Debe ser `http`
3. **El servicio está en otra red** → Debe estar en `traefik`

**Empieza verificando estos 3 puntos en EasyPanel.**

---

## 📞 Próximos Pasos

**Por favor:**
1. Ve a EasyPanel → Servicio "dashboard" → "Domains"
2. Verifica que `dashboard.checkin24hs.com` tenga:
   - Port: `3000`
   - Internal Protocol: `http`
3. Ve a "Settings" → Verifica que la red sea `traefik`
4. Reinicia ambos servicios (dashboard y traefik)
5. Espera 2 minutos
6. Prueba el dashboard y dime qué pasa

Si después de verificar y corregir estos puntos sigue fallando, el problema puede ser más profundo y necesitamos revisar la configuración de Traefik directamente.

