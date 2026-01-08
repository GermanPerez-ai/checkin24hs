# 🚀 Reemplazar dashboard.html en el Servidor - Directo

## Opción 1: Desde tu Máquina Local (Recomendado)

### Paso 1: Preparar el archivo

Asegúrate de que `dashboard.html` esté actualizado en tu máquina local.

### Paso 2: Subir al servidor

**Desde Windows (PowerShell):**

```powershell
# 1. Conectarte al servidor por SSH
ssh root@tu_servidor

# 2. Una vez conectado, encontrar el contenedor
docker ps | grep dashboard

# 3. Anotar el ID del contenedor (primera columna)
# Ejemplo: CONTAINER_ID="abc123def456"

# 4. En otra terminal de Windows, copiar el archivo
scp C:\Users\German\Downloads\Checkin24hs\dashboard.html root@tu_servidor:/tmp/dashboard.html
```

**O desde el servidor directamente:**

```bash
# 1. Conectarte al servidor
ssh root@tu_servidor

# 2. Encontrar el contenedor
CONTAINER_ID=$(docker ps | grep dashboard | awk '{print $1}' | head -1)
echo "Contenedor: $CONTAINER_ID"

# 3. Hacer backup del archivo actual
docker exec $CONTAINER_ID cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)

# 4. Desde tu máquina local, subir el archivo:
# (En PowerShell de Windows)
scp dashboard.html root@tu_servidor:/tmp/dashboard.html

# 5. Copiar al contenedor
docker cp /tmp/dashboard.html $CONTAINER_ID:/app/dashboard.html

# 6. Reiniciar el contenedor
docker restart $CONTAINER_ID

# 7. Esperar 15 segundos
sleep 15

# 8. Verificar logs
docker logs $CONTAINER_ID --tail 20
```

---

## Opción 2: Usar WinSCP (Más Fácil para Windows)

### Paso 1: Descargar WinSCP

Si no lo tienes, descárgalo de: https://winscp.net/

### Paso 2: Conectarte al servidor

1. Abre WinSCP
2. Conecta a tu servidor:
   - **Host:** `tu_servidor` (o IP)
   - **Usuario:** `root`
   - **Contraseña:** (la de tu servidor)
   - **Protocolo:** SFTP

### Paso 3: Subir el archivo

1. Navega a `/tmp/` en el servidor
2. Arrastra `dashboard.html` desde tu máquina local a `/tmp/` en el servidor
3. Luego ejecuta estos comandos en el servidor (por SSH):

```bash
# Encontrar contenedor
CONTAINER_ID=$(docker ps | grep dashboard | awk '{print $1}' | head -1)

# Backup
docker exec $CONTAINER_ID cp /app/dashboard.html /app/dashboard.html.backup

# Copiar al contenedor
docker cp /tmp/dashboard.html $CONTAINER_ID:/app/dashboard.html

# Reiniciar
docker restart $CONTAINER_ID
```

---

## Opción 3: Script Automático (Más Rápido)

### Paso 1: Crear script en el servidor

Conéctate por SSH y crea este script:

```bash
ssh root@tu_servidor

# Crear script
cat > reemplazar_dashboard.sh << 'EOF'
#!/bin/bash

echo "🔧 REEMPLAZANDO dashboard.html"
echo "================================"

# 1. Encontrar contenedor
CONTAINER_ID=$(docker ps | grep dashboard | awk '{print $1}' | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ No se encontró el contenedor del dashboard"
    exit 1
fi

echo "✅ Contenedor encontrado: $CONTAINER_ID"

# 2. Verificar que el archivo existe en /tmp
if [ ! -f "/tmp/dashboard.html" ]; then
    echo "❌ No se encontró /tmp/dashboard.html"
    echo "💡 Sube el archivo primero con: scp dashboard.html root@servidor:/tmp/dashboard.html"
    exit 1
fi

# 3. Backup
echo "📋 Haciendo backup..."
docker exec $CONTAINER_ID cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S)

# 4. Copiar al contenedor
echo "📋 Copiando archivo al contenedor..."
docker cp /tmp/dashboard.html $CONTAINER_ID:/app/dashboard.html

# 5. Reiniciar
echo "📋 Reiniciando contenedor..."
docker restart $CONTAINER_ID

# 6. Esperar
echo "⏳ Esperando 15 segundos..."
sleep 15

# 7. Verificar
echo "📋 Verificando logs..."
docker logs $CONTAINER_ID --tail 10

echo ""
echo "✅ PROCESO COMPLETADO"
echo "================================"
EOF

chmod +x reemplazar_dashboard.sh
```

### Paso 2: Subir el archivo desde tu máquina

**En PowerShell de Windows:**

```powershell
# Navegar a la carpeta del proyecto
cd C:\Users\German\Downloads\Checkin24hs

# Subir el archivo
scp dashboard.html root@tu_servidor:/tmp/dashboard.html
```

### Paso 3: Ejecutar el script

**En el servidor (por SSH):**

```bash
./reemplazar_dashboard.sh
```

---

## Opción 4: Forzar Redeploy desde EasyPanel (Más Simple)

Si el código local ya está en GitHub:

1. **Asegúrate de que el código local esté en GitHub:**
   ```bash
   # En tu máquina local
   cd C:\Users\German\Downloads\Checkin24hs
   git add dashboard.html
   git commit -m "Actualizar dashboard.html desde local funcionando"
   git push origin main
   ```

2. **Forzar redeploy desde EasyPanel:**
   - Ve a EasyPanel → Servicio "dashboard"
   - Haz clic en "Redeploy" o "Redesplegar"
   - Espera 2-3 minutos

---

## Recomendación

**Para rapidez:** Usa la **Opción 2 (WinSCP)** - es la más fácil en Windows.

**Para automatización:** Usa la **Opción 3 (Script)** - una vez configurado, es muy rápido.

**Para mantener sincronización:** Usa la **Opción 4 (EasyPanel)** - mantiene todo sincronizado con GitHub.

---

## Verificación

Después de reemplazar:

1. Abre `https://dashboard.checkin24hs.com`
2. Presiona Ctrl+F5 (limpiar caché)
3. Abre la consola (F12)
4. Verifica que NO hay errores
5. Prueba navegar entre las pestañas

