# 🔧 Forzar Rebuild Sin Caché en EasyPanel

## ⚠️ PROBLEMA

El servidor está sirviendo una versión antigua del código porque EasyPanel está usando caché de Docker.

## ✅ SOLUCIÓN: Forzar Rebuild Sin Caché

### Opción 1: Desde EasyPanel (Recomendado)

1. **Ve a EasyPanel** → Proyecto `checkin24hs` → Servicio `dashboard`

2. **Ve a la pestaña "Deploy" o "Implementar"**

3. **Busca la opción "Build without cache" o "Rebuild without cache"**
   - Si existe, actívala
   - Luego haz clic en "Deploy" o "Redeploy"

4. **Si NO existe esa opción:**
   - Haz clic en "Deploy" o "Redeploy"
   - Espera a que termine el build

### Opción 2: Modificar Dockerfile Temporalmente

Si EasyPanel no tiene opción de rebuild sin caché, puedes forzar un rebuild modificando el Dockerfile:

1. **Edita el Dockerfile** y agrega un comentario con timestamp único:
   ```dockerfile
   # Forzar rebuild - 2026-01-13T02:00:00Z
   ```

2. **Haz commit y push:**
   ```bash
   git add Dockerfile
   git commit -m "Force rebuild - $(date -u +%Y-%m-%dT%H:%M:%SZ)"
   git push origin main
   ```

3. **Ve a EasyPanel y haz Deploy**

### Opción 3: Desde el Servidor (Avanzado)

Si tienes acceso SSH al servidor:

```bash
# 1. Verificar versión actual
./VERIFICAR_VERSION_CONTENEDOR_COMPLETA.sh

# 2. Forzar actualización del servicio (esto NO reconstruye la imagen)
docker service update --force checkin24hs_dashboard

# 3. Esperar y verificar
sleep 30
./VERIFICAR_VERSION_CONTENEDOR_COMPLETA.sh
```

**NOTA:** `docker service update --force` solo reinicia el contenedor, NO reconstruye la imagen. Para reconstruir la imagen, necesitas hacerlo desde EasyPanel.

## 📋 Verificar Configuración de EasyPanel

### Repositorio y Rama

1. **Ve a EasyPanel** → Servicio `dashboard` → Pestaña **"Source"** o **"Fuente"**

2. **Verifica:**
   - **Repositorio:** `GermanPerez-ai/checkin24hs`
   - **Rama:** `main`
   - **Build Path:** `/` (raíz)

3. **Si está incorrecto, corrígelo y guarda**

### Dockerfile

1. **Ve a la pestaña "Build" o "Compilación"**

2. **Verifica:**
   - **Tipo de build:** `Dockerfile`
   - **Archivo Dockerfile:** `Dockerfile` (debe estar en la raíz)

3. **Si está incorrecto, corrígelo y guarda**

## 🔍 Verificar Después del Rebuild

Ejecuta en el servidor:

```bash
cd ~
curl -O https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/VERIFICAR_VERSION_CONTENEDOR_COMPLETA.sh
chmod +x VERIFICAR_VERSION_CONTENEDOR_COMPLETA.sh
./VERIFICAR_VERSION_CONTENEDOR_COMPLETA.sh
```

Este script te dirá exactamente qué versión está en el contenedor.

## ⚠️ IMPORTANTE

- **EasyPanel usa caché de Docker** para acelerar los builds
- Si el código cambia pero la imagen no se reconstruye, seguirás viendo la versión antigua
- **Siempre verifica la versión en el contenedor** después de un deploy
