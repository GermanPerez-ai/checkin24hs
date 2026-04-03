# 🚀 Crear Servicio Cotizador en EasyPanel

## 📋 Paso 1: Eliminar Servicio Actual por SSH

Primero, elimina el servicio que creamos por SSH:

```bash
docker service rm cotizador
```

Espera 5 segundos para que se elimine completamente.

---

## 🎛️ Paso 2: Crear Servicio en EasyPanel

### 2.1. Acceder a EasyPanel

1. Accede a EasyPanel (usa la URL que normalmente usas)
2. Inicia sesión

### 2.2. Crear Nuevo Servicio

1. **Clic en "Nuevo Servicio"** o el botón **"+"** (verde)
2. Selecciona el proyecto: `checkin24hs`
3. **Nombre del servicio:** `cotizador` (o `cotizador-cliente`)
4. Haz clic en **"Crear"** o **"Siguiente"**

### 2.3. Configurar la Fuente (Source) desde GitHub

1. **Ve a la pestaña "Fuente"** o **"Source"** (en el menú lateral del servicio)
2. **Selecciona la pestaña "Github"** (no "Upload" ni "Dockerfile directo")
3. Configura:
   - **Propietario/Owner:** `GermanPerez-ai` (o tu usuario de GitHub)
   - **Repositorio/Repository:** `checkin24hs`
   - **Rama/Branch:** `main`
   - **Build Path:** `/` (raíz del repositorio, porque `Dockerfile.cotizador` está en la raíz)
   - **Dockerfile Path:** `Dockerfile.cotizador` (o solo el nombre del archivo)

**Importante:** El Build Path debe ser `/` (raíz) porque el `Dockerfile.cotizador` está en la raíz del repositorio.

### 2.4. Configurar Puerto

1. **Ve a la pestaña "Recursos"** o **"Resources"** (si hay una sección de puertos separada)
2. **Puerto interno:** `80`
3. **Guarda** los cambios (si hay botón Guardar en esta sección)

### 2.5. Configurar Dominio

1. **Ve a la pestaña "Dominios"** o **"Domains"** (en el menú lateral del servicio)
2. **Clic en "Agregar dominio"** o **"+"**
3. Ingresa: `cotizar.checkin24hs.com`
4. **HTTPS:** ✅ Habilitado (Traefik generará certificado SSL automáticamente)
5. **Puerto:** `80` (puerto interno del contenedor)
6. **Guarda** los cambios

### 2.6. Guardar y Construir

1. **Clic en "Guardar"** o **"Save"** en la pestaña Source
2. **Clic en "Deploy"** o **"Desplegar"** (botón verde)
3. EasyPanel descargará el código desde GitHub y construirá la imagen Docker automáticamente
4. Espera 2-3 minutos para que termine el build
5. El servicio se iniciará automáticamente

---

## ✅ Paso 3: Verificar

### En EasyPanel:

1. Ve al servicio `cotizador` creado
2. Verifica que esté en estado **"Running"** (verde)
3. En la pestaña "Dominios", verifica que `cotizar.checkin24hs.com` esté configurado

### Desde el navegador:

1. **Espera 2-3 minutos** después de crear el servicio
2. Accede a: `https://cotizar.checkin24hs.com`
3. Deberías ver el formulario del cotizador

---

## 🔧 Notas sobre el Build Path

**Build Path:** `/` (raíz del repositorio)

Esto es correcto porque:
- El archivo `Dockerfile.cotizador` está en la raíz del repositorio `checkin24hs`
- Los archivos que necesita el Dockerfile (`cotizador-cliente.html`, `supabase-config.js`, `supabase-client.js`) también están en la raíz

Si en el futuro mueves estos archivos a una carpeta (ej: `cotizador/`), entonces el Build Path sería `/cotizador`

---

## 📝 Notas Importantes

- **EasyPanel agregará automáticamente las etiquetas de Traefik** cuando agregues el dominio
- **No necesitas configurar manualmente las etiquetas** (EasyPanel lo hace)
- **El certificado SSL se generará automáticamente** con Let's Encrypt
- **Espera 2-3 minutos** para que Traefik configure todo

---

**Después de crear el servicio en EasyPanel, ejecuta en SSH para verificar:**

```bash
# Verificar que el servicio está corriendo
docker service ls | grep cotizador

# Verificar etiquetas de Traefik (EasyPanel las habrá agregado automáticamente)
docker service inspect cotizador --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | sort

# Ver logs de Traefik
docker service logs traefik --tail 30 | grep -i cotizar
```
