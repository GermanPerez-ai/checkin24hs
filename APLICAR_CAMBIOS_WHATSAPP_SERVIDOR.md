# 🚀 Comandos para Aplicar Cambios al Servidor

## 📋 Pasos para Aplicar los Cambios

### Paso 1: Subir el archivo al servidor

**Desde PowerShell (en tu computadora):**

```powershell
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html
```

**O desde Git Bash / Terminal:**

```bash
scp deploy/dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html
```

---

### Paso 2: Conectar al servidor

```powershell
ssh root@72.61.58.240
```

---

### Paso 3: Aplicar a todos los contenedores

**Una vez conectado al servidor, ejecuta:**

```bash
cd /root/checkin24hs

# Buscar contenedores de dashboard
docker ps --format "{{.Names}}" | grep checkin24hs_dashboard

# Aplicar a cada contenedor
for c in $(docker ps --format "{{.Names}}" | grep checkin24hs_dashboard); do
    echo "📦 Procesando: $c"
    docker stop $c
    docker cp deploy/dashboard.html $c:/app/dashboard.html 2>/dev/null || docker cp deploy/dashboard.html $c:/usr/share/nginx/html/dashboard.html 2>/dev/null
    docker start $c
    echo "✅ $c actualizado"
done
```

---

## 🔄 Script Completo (Todo en Uno)

**Desde PowerShell (en tu computadora):**

```powershell
# 1. Subir archivo
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

# 2. Aplicar a contenedores (todo en una línea)
ssh root@72.61.58.240 "cd /root/checkin24hs && for c in \$(docker ps --format '{{.Names}}' | grep checkin24hs_dashboard); do echo '📦 Procesando: '\$c; docker stop \$c 2>/dev/null; docker cp deploy/dashboard.html \$c:/app/dashboard.html 2>/dev/null || docker cp deploy/dashboard.html \$c:/usr/share/nginx/html/dashboard.html 2>/dev/null; docker start \$c 2>/dev/null; echo '✅ '\$c' actualizado'; done"
```

---

## ✅ Verificación

Después de aplicar, verifica:

1. **Recarga el dashboard** con Ctrl+F5
2. **Ve a**: Flor IA → Pestaña WhatsApp
3. **Busca el botón naranja** arriba a la derecha: "⚙️ Configurar Servidor"

---

## 📝 Notas

- El archivo se sube a: `/root/checkin24hs/deploy/dashboard.html`
- Se copia a cada contenedor en: `/app/dashboard.html` o `/usr/share/nginx/html/dashboard.html`
- Los contenedores se reinician automáticamente

---

## 🆘 Si algo falla

1. Verifica que el archivo se subió:
   ```bash
   ssh root@72.61.58.240 "ls -lh /root/checkin24hs/deploy/dashboard.html"
   ```

2. Verifica los contenedores:
   ```bash
   ssh root@72.61.58.240 "docker ps | grep checkin24hs_dashboard"
   ```

3. Verifica que el archivo está en el contenedor:
   ```bash
   ssh root@72.61.58.240 "docker exec <NOMBRE_CONTENEDOR> ls -lh /app/dashboard.html"
   ```










