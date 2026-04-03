# 🔧 Configurar Dominio cotizar.checkin24hs.com en EasyPanel

## 📋 Resumen

Configurar el cotizador-cliente.html para que esté disponible en `cotizar.checkin24hs.com` usando EasyPanel con Traefik.

---

## 🎯 Paso 1: Configurar DNS

### En tu proveedor de dominio (Cloudflare, Namecheap, etc.)

1. **Agregar registro DNS tipo A:**
   - **Tipo:** A
   - **Nombre:** `cotizar` (o `cotizar.checkin24hs.com` dependiendo del proveedor)
   - **Valor/IP:** `72.61.58.240` (IP de tu servidor)
   - **TTL:** Auto o 300 segundos
   - **Proxy:** Desactivado (solo DNS, sin proxy de Cloudflare)

2. **Verificar propagación DNS:**
   ```bash
   # Desde tu computadora o servidor
   nslookup cotizar.checkin24hs.com
   # O
   dig cotizar.checkin24hs.com
   ```
   
   Debe devolver: `72.61.58.240`

---

## 🚀 Paso 2: Crear Servicio en EasyPanel

### Opción A: Servicio Estático (Recomendado)

1. **Acceder a EasyPanel:**
   - Ve a: `http://72.61.58.240:3000` (o tu IP de EasyPanel)
   - Inicia sesión

2. **Crear nuevo servicio:**
   - Clic en **"Nuevo Servicio"** o **"+"**
   - Selecciona **"Aplicación Estática"** o **"Static Site"**

3. **Configurar el servicio:**
   - **Nombre del servicio:** `cotizador` (o `cotizador-cliente`)
   - **Build Path:** `/root/checkin24hs` (o donde esté el archivo)
   - **Dockerfile:** (EasyPanel puede generar uno automático para archivos estáticos)
   - **Puerto:** `80` (si usa Nginx interno)

4. **Configurar Dockerfile (si es necesario):**

   Si EasyPanel no genera el Dockerfile automáticamente, crea uno en `/root/checkin24hs/Dockerfile.cotizador`:

   ```dockerfile
   FROM nginx:alpine
   
   # Copiar el archivo HTML
   COPY cotizador-cliente.html /usr/share/nginx/html/index.html
   COPY supabase-config.js /usr/share/nginx/html/
   COPY supabase-client.js /usr/share/nginx/html/
   
   # Exponer puerto 80
   EXPOSE 80
   
   CMD ["nginx", "-g", "daemon off;"]
   ```

---

## 🌐 Paso 3: Agregar Dominio en EasyPanel

1. **Ir al servicio creado:**
   - En EasyPanel, ve al servicio `cotizador` (o el nombre que elegiste)

2. **Ir a la pestaña "Dominios":**
   - Clic en **"Dominios"** en el menú lateral

3. **Agregar dominio:**
   - Clic en **"Agregar dominio"** o **"+"**
   - Ingresa: `cotizar.checkin24hs.com`
   - **HTTPS:** Habilitado (Traefik generará certificado SSL automáticamente)
   - Guarda los cambios

4. **EasyPanel configurará automáticamente:**
   - Traefik detectará el nuevo dominio
   - Generará certificado SSL con Let's Encrypt
   - Enrutará el tráfico al servicio

---

## 🔧 Paso 4: Configurar Servicio con Archivos Estáticos

### Si usas Dockerfile personalizado:

1. **Asegúrate de que los archivos estén en el servidor:**
   ```bash
   # En el servidor
   cd /root/checkin24hs
   ls -la cotizador-cliente.html
   ls -la supabase-config.js
   ls -la supabase-client.js
   ```

2. **Si los archivos no están, cópialos:**
   ```bash
   # Desde tu computadora (PowerShell)
   scp cotizador-cliente.html root@72.61.58.240:/root/checkin24hs/
   scp supabase-config.js root@72.61.58.240:/root/checkin24hs/
   scp supabase-client.js root@72.61.58.240:/root/checkin24hs/
   ```

---

## 🎯 Paso 5: Verificar Configuración

### En el servidor:

```bash
# Ver servicios de Docker
docker ps | grep cotizador

# Ver logs del servicio
docker logs cotizador --tail 50

# Verificar que Traefik detectó el dominio
docker logs traefik --tail 100 | grep cotizar
```

### Desde el navegador:

1. **Espera 2-3 minutos** para que Traefik actualice la configuración
2. **Accede a:** `https://cotizar.checkin24hs.com`
3. **Verifica:**
   - ✅ El formulario se carga correctamente
   - ✅ Los hoteles se cargan desde Supabase
   - ✅ El teléfono se autocompleta desde URL (prueba: `?phone=+54912345678`)

---

## 🔄 Alternativa: Usar Servicio Existente con Ruta

Si prefieres no crear un servicio nuevo, puedes agregar una ruta al servicio del dashboard:

### Opción B: Agregar Ruta en Servicio Dashboard

1. **En EasyPanel:**
   - Ve al servicio `dashboard` (o el servicio principal)
   - Ve a **"Dominios"**
   - Agrega dominio: `cotizar.checkin24hs.com`
   - Configura **Ruta:** `/cotizador-cliente.html`
   - **Destino:** Mismo servicio, pero con ruta específica

**Nota:** Esta opción requiere configuración de Nginx/Traefik más compleja.

---

## 📝 Resumen de Pasos

1. ✅ **DNS:** Agregar registro A `cotizar` → `72.61.58.240`
2. ✅ **EasyPanel:** Crear servicio estático para cotizador
3. ✅ **EasyPanel:** Agregar dominio `cotizar.checkin24hs.com`
4. ✅ **Verificar:** Acceder a `https://cotizar.checkin24hs.com`

---

## 🆘 Si No Funciona

### Verificar DNS:
```bash
nslookup cotizar.checkin24hs.com
```

### Verificar Traefik:
```bash
docker logs traefik --tail 100 | grep -i cotizar
```

### Verificar Servicio:
```bash
docker ps | grep cotizador
docker logs cotizador --tail 50
```

### Verificar Firewall:
```bash
sudo ufw status
# Asegúrate de que los puertos 80 y 443 estén abiertos
```

---

## 💡 Notas Importantes

- **HTTPS automático:** Traefik generará certificado SSL automáticamente
- **Tiempo de propagación:** DNS puede tardar hasta 24 horas (normalmente 5-15 minutos)
- **Traefik:** Puede tardar 1-2 minutos en detectar cambios
- **Archivos necesarios:** Asegúrate de que `supabase-config.js` y `supabase-client.js` estén en el mismo directorio

---

**Última actualización:** 2025-01-27
