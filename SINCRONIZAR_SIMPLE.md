# 🔄 Sincronizar Build #41 - Método Simple

## 📊 Situación
- **Local**: Build #41 ✅
- **Servidor**: Build #40 ⚠️

---

## 🚀 Pasos Simples (Sin Scripts)

### Paso 1: Subir archivo (PowerShell - 1 comando)

Abre PowerShell y ejecuta:

```powershell
scp C:\Users\German\Downloads\Checkin24hs\dashboard.html root@72.61.58.240:/root/checkin24hs/
```

**Espera a que termine** (puede tardar 1-2 minutos si el archivo es grande).

---

### Paso 2: Conectar al servidor (SSH)

En otra ventana de PowerShell o terminal:

```bash
ssh root@72.61.58.240
```

---

### Paso 3: Aplicar cambios (3 comandos simples)

Una vez conectado al servidor, ejecuta uno por uno:

```bash
# 1. Ir al directorio
cd /root/checkin24hs

# 2. Buscar el contenedor
docker ps | grep dashboard
```

**Anota el nombre del contenedor** (ejemplo: `checkin24hs_dashboard_1`)

```bash
# 3. Copiar y reiniciar (reemplaza NOMBRE_CONTENEDOR con el que viste arriba)
docker cp dashboard.html NOMBRE_CONTENEDOR:/app/dashboard.html
docker restart NOMBRE_CONTENEDOR
```

**O si es un servicio Docker Swarm:**

```bash
docker service update --force checkin24hs_dashboard
```

---

### Paso 4: Verificar (Navegador)

1. Abre: https://dashboard.checkin24hs.com/
2. **Ctrl+Shift+R** (hard refresh)
3. **F12** → Console → Escribe: `window.DASHBOARD_BUILD_NUMBER`
4. Debe mostrar: `41` ✅

---

## ⚠️ Si algo falla

### No se sube el archivo
- Usa **WinSCP** (más fácil): https://winscp.net/
- Conecta a `72.61.58.240` (usuario: `root`)
- Arrastra `dashboard.html` a `/root/checkin24hs/`

### No encuentras el contenedor
```bash
docker ps -a | grep dashboard
```

### El servicio no se actualiza
```bash
docker service ls | grep dashboard
docker service update --force checkin24hs_dashboard
```

---

**Eso es todo. Sin scripts, sin bucles. Solo comandos simples.** ✅
