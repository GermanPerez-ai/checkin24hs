# 🔄 Proceso Permanente para Actualizar Cotizador en el Servidor

## 📋 Resumen del Proceso

Este proceso garantiza que los cambios en `cotizador-cliente.html` se suban a GitHub y se actualicen permanentemente en el servidor.

---

## 🚀 Paso 1: Subir Cambios a GitHub (Local)

### 1.1 Verificar Estado de Git

```powershell
# En PowerShell, desde la carpeta del proyecto
cd c:\Users\German\Downloads\Checkin24hs

# Ver qué archivos han cambiado
git status
```

### 1.2 Agregar Archivos Modificados

```powershell
# Agregar el archivo del cotizador (y archivos relacionados si cambiaron)
git add cotizador-cliente.html

# Si también modificaste estos archivos, agrégalos:
git add supabase-config.js supabase-client.js
```

### 1.3 Hacer Commit

```powershell
# Commit con mensaje descriptivo
git commit -m "feat: Actualizar cotizador-cliente con validación de promociones

- Agregar validación de fechas de viaje en promociones
- Agregar validación de cantidad de noches
- Agregar modal de validación con opciones (revisar/enviar igual)
- Mejorar logging y debugging"
```

### 1.4 Subir a GitHub

```powershell
# Subir cambios a GitHub
git push origin main
```

### 1.5 Verificar en GitHub

1. Abre: https://github.com/GermanPerez-ai/checkin24hs
2. Verifica que `cotizador-cliente.html` esté actualizado
3. Puedes ver el contenido directamente en:
   - https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html

---

## 🔧 Paso 2: Actualizar en el Servidor desde GitHub

### Opción A: Usando Script Automático (RECOMENDADO)

#### 2.1 Conectarse al Servidor

```bash
# Conectarse por SSH
ssh root@TU_SERVIDOR_IP
# O si usas una clave específica:
ssh -i ~/.ssh/tu_clave root@TU_SERVIDOR_IP
```

#### 2.2 Copiar Script al Servidor (si no existe)

```powershell
# Desde PowerShell en tu máquina local
scp ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh root@TU_SERVIDOR_IP:/root/
```

#### 2.3 Ejecutar Script en el Servidor

```bash
# En el servidor
chmod +x /root/ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh
/root/ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh
```

El script:
- ✅ Busca automáticamente el contenedor/servicio del cotizador
- ✅ Descarga los archivos desde GitHub
- ✅ Copia los archivos al lugar correcto
- ✅ Reinicia el servicio si es necesario

### Opción B: Usando EasyPanel (Si está configurado)

1. **Acceder a EasyPanel:**
   - Ve a: `http://TU_SERVIDOR_IP:3000`
   - Inicia sesión

2. **Buscar el servicio del cotizador:**
   - Busca el servicio llamado `cotizador` o similar

3. **Usar Terminal/SSH desde EasyPanel:**
   - Si EasyPanel tiene terminal integrada, úsala
   - O ejecuta el script desde SSH externo

4. **Hacer Redeploy (si el servicio está conectado a GitHub):**
   - Si el servicio está configurado para usar GitHub como fuente
   - Haz clic en **"Redeploy"** o **"Rebuild"**
   - EasyPanel descargará automáticamente los archivos desde GitHub

### Opción C: Actualización Manual

```bash
# En el servidor
# 1. Buscar el contenedor del cotizador
docker ps | grep cotizador

# 2. Descargar archivos desde GitHub
curl -L -o /tmp/cotizador-cliente.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html
curl -L -o /tmp/supabase-config.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-config.js
curl -L -o /tmp/supabase-client.js https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/supabase-client.js

# 3. Copiar al contenedor (reemplaza CONTAINER_ID)
docker cp /tmp/cotizador-cliente.html CONTAINER_ID:/usr/share/nginx/html/cotizador-cliente.html
docker cp /tmp/cotizador-cliente.html CONTAINER_ID:/usr/share/nginx/html/index.html
docker cp /tmp/supabase-config.js CONTAINER_ID:/usr/share/nginx/html/supabase-config.js
docker cp /tmp/supabase-client.js CONTAINER_ID:/usr/share/nginx/html/supabase-client.js

# 4. Reiniciar el contenedor
docker restart CONTAINER_ID
```

---

## ✅ Paso 3: Verificar que Funcionó

### 3.1 Verificar en el Navegador

1. **Abrir el cotizador:**
   ```
   https://cotizar.checkin24hs.com/
   ```

2. **Limpiar caché del navegador:**
   - Presiona `Ctrl + Shift + R` (Windows/Linux)
   - O `Cmd + Shift + R` (Mac)
   - O abre en modo incógnito

3. **Abrir consola del navegador (F12)**

4. **Probar funcionalidad:**
   - Seleccionar un hotel
   - Seleccionar una promoción
   - Ingresar fechas y noches
   - Intentar enviar cotización

5. **Verificar en la consola:**
   - Debe aparecer: `🔍 Validando fechas de viaje para promoción: ...`
   - Debe aparecer: `📅 Comparando fechas: ...`
   - Si la promoción no cumple, debe aparecer el modal de validación

### 3.2 Verificar en el Dashboard

1. **Abrir el dashboard:**
   ```
   https://dashboard.checkin24hs.com/
   ```

2. **Ir a la sección "Cotizaciones"**

3. **Abrir una cotización que tenga promoción seleccionada**

4. **Verificar que aparezca la advertencia:**
   - Si la promoción no corresponde, debe aparecer:
     - "⚠️ Advertencia: El cliente eligió una promoción que no corresponde"
     - Con los detalles de los errores

---

## 🔄 Proceso Completo Resumido

```bash
# ============================================
# PASO 1: LOCAL - Subir a GitHub
# ============================================
# En PowerShell (máquina local)
cd c:\Users\German\Downloads\Checkin24hs
git add cotizador-cliente.html
git commit -m "feat: Actualizar cotizador con validación de promociones"
git push origin main

# ============================================
# PASO 2: SERVIDOR - Actualizar desde GitHub
# ============================================
# En SSH (servidor)
ssh root@TU_SERVIDOR_IP
/root/ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh

# ============================================
# PASO 3: VERIFICAR
# ============================================
# En navegador
# Abrir https://cotizar.checkin24hs.com/
# Probar funcionalidad y verificar logs en consola
```

---

## 🎯 Hacer el Proceso Permanente

### Opción 1: Configurar EasyPanel con GitHub (MÁS PERMANENTE)

1. **En EasyPanel:**
   - Ve al servicio del cotizador
   - Ve a **"Settings"** o **"Configuración"**
   - Configura **"Source"** como **"GitHub"**
   - **Owner:** `GermanPerez-ai`
   - **Repository:** `checkin24hs`
   - **Branch:** `main`
   - **Build Path:** `/` (o la ruta donde está `cotizador-cliente.html`)

2. **Configurar Auto-Deploy (opcional):**
   - Si EasyPanel soporta webhooks, configura para que se actualice automáticamente cuando hagas push a GitHub

3. **Ventajas:**
   - ✅ Cada vez que hagas `git push`, EasyPanel puede hacer redeploy automáticamente
   - ✅ Los cambios quedan permanentemente sincronizados con GitHub
   - ✅ No necesitas ejecutar scripts manualmente

### Opción 2: Script Automatizado con Cron (Alternativa)

```bash
# En el servidor, crear un script que se ejecute periódicamente
# (No recomendado para producción, pero puede ser útil)

# Crear script de actualización automática
cat > /root/actualizar_cotizador_auto.sh << 'EOF'
#!/bin/bash
# Script para actualizar cotizador automáticamente desde GitHub
# Ejecutar manualmente cuando sea necesario

/root/ACTUALIZAR_COTIZADOR_DESDE_GITHUB.sh
EOF

chmod +x /root/actualizar_cotizador_auto.sh
```

---

## 🆘 Solución de Problemas

### Si los archivos no se actualizan:

1. **Verificar que se subieron a GitHub:**
   - Ve a: https://github.com/GermanPerez-ai/checkin24hs/tree/main
   - Verifica que `cotizador-cliente.html` tenga la fecha/hora reciente
   - Verifica el contenido en: https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/cotizador-cliente.html

2. **Verificar que se descargaron en el servidor:**
   ```bash
   # Verificar tamaño de archivos descargados
   ls -lh /tmp/cotizador-cliente.html
   ```

3. **Verificar que se copiaron al contenedor:**
   ```bash
   docker exec CONTAINER_ID ls -la /usr/share/nginx/html/cotizador-cliente.html
   docker exec CONTAINER_ID head -20 /usr/share/nginx/html/cotizador-cliente.html
   ```

4. **Limpiar caché del navegador:**
   - Presiona `Ctrl + Shift + R` para recargar sin caché
   - O abre en modo incógnito

5. **Reiniciar el contenedor/servicio:**
   ```bash
   docker restart CONTAINER_ID
   # O si es un servicio
   docker service update --force SERVICIO_NOMBRE
   ```

### Si el script no encuentra el contenedor:

1. **Listar todos los contenedores:**
   ```bash
   docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
   ```

2. **Buscar servicios Docker Swarm:**
   ```bash
   docker service ls
   ```

3. **Ejecutar el script manualmente con el ID:**
   - El script te pedirá que ingreses el ID manualmente

---

## 📝 Notas Importantes

- ⚠️ **Siempre verifica** que los archivos se subieron correctamente a GitHub antes de actualizar en el servidor
- 🔄 Puede tomar unos minutos para que los cambios se reflejen
- 🌐 Si usas CDN o caché, puede ser necesario limpiarlo
- 📱 Prueba desde diferentes dispositivos para asegurarte
- 💾 **Hacer backup** antes de actualizar (el script lo hace automáticamente)
- 🔐 Asegúrate de tener permisos SSH en el servidor

---

## 🎯 Mejores Prácticas

1. **Siempre hacer commit con mensajes descriptivos:**
   ```powershell
   git commit -m "feat: Descripción clara de los cambios"
   ```

2. **Verificar cambios localmente antes de subir:**
   - Abre `cotizador-cliente.html` en el navegador localmente
   - Prueba la funcionalidad
   - Verifica que no haya errores en la consola

3. **Hacer push frecuentemente:**
   - No acumules muchos cambios sin hacer push
   - Facilita el rollback si algo sale mal

4. **Documentar cambios importantes:**
   - Si agregas funcionalidades nuevas, documenta cómo funcionan
   - Actualiza este documento si cambia el proceso

---

**Última actualización:** 2026-01-23
