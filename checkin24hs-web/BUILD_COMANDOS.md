# Build checkin24hs-web – PowerShell (PC) y servidor

## 1. En tu PC (PowerShell)

Abrí PowerShell en la carpeta del repo (donde está `checkin24hs-web`).

### Solo build (probar que compila)

```powershell
cd c:\Users\German\Downloads\Checkin24hs\checkin24hs-web

docker build -t checkin24hs-web:local .
```

### Build con variables de Supabase (recomendado)

Reemplazá `TU_SUPABASE_URL` y `TU_ANON_KEY` por los valores reales de tu proyecto Supabase.

```powershell
cd c:\Users\German\Downloads\Checkin24hs\checkin24hs-web

docker build `
  --build-arg VITE_SUPABASE_URL=https://TU_PROYECTO.supabase.co `
  --build-arg VITE_SUPABASE_ANON_KEY=TU_ANON_KEY `
  --build-arg VITE_COTIZADOR_URL=https://cotizar.checkin24hs.com `
  -t checkin24hs-web:local .
```

### Probar la imagen en local (puerto 3002)

```powershell
docker run -p 3002:80 --rm checkin24hs-web:local
```

Abrí en el navegador: **http://localhost:3002**

Para detener: `Ctrl+C`.

---

## 2. En el servidor (SSH + bash)

Conectate al servidor y construí la imagen con el tag que usa EasyPanel.

### Si el repo ya está en el servidor (ej. `/root/checkin24hs`)

```bash
ssh root@72.61.58.240
```

Luego en el servidor:

```bash
cd /root/checkin24hs/checkin24hs-web

# Build con el tag que espera EasyPanel (appwebcheckin24hs)
docker build \
  --build-arg VITE_SUPABASE_URL=https://TU_PROYECTO.supabase.co \
  --build-arg VITE_SUPABASE_ANON_KEY=TU_ANON_KEY \
  --build-arg VITE_COTIZADOR_URL=https://cotizar.checkin24hs.com \
  -t easypanel/checkin24hs/appwebcheckin24hs:latest .
```

Si no usás variables de build (la web funcionará con valores por defecto o vacíos):

```bash
cd /root/checkin24hs/checkin24hs-web

docker build -t easypanel/checkin24hs/appwebcheckin24hs:latest .
```

Después de que el build termine, en EasyPanel hacé clic en **Implementar** (o reiniciar el servicio); debería encontrar la imagen y arrancar el contenedor.

### Si primero tenés que clonar o actualizar el repo en el servidor

```bash
ssh root@72.61.58.240

cd /root
# Si ya existe el repo, solo actualizar:
cd checkin24hs && git pull
# Si no existe:
# git clone https://github.com/GermanPerez-ai/checkin24hs.git && cd checkin24hs

cd checkin24hs-web
docker build \
  --build-arg VITE_SUPABASE_URL=https://TU_PROYECTO.supabase.co \
  --build-arg VITE_SUPABASE_ANON_KEY=TU_ANON_KEY \
  -t easypanel/checkin24hs/appwebcheckin24hs:latest .
```

---

## Resumen

| Dónde   | Comando principal |
|--------|--------------------|
| **PC** | `docker build -t checkin24hs-web:local .` (desde `checkin24hs-web`) |
| **Servidor** | `docker build -t easypanel/checkin24hs/appwebcheckin24hs:latest .` (desde `checkin24hs-web`) |

En el servidor el tag **tiene que ser** `easypanel/checkin24hs/appwebcheckin24hs:latest` para que EasyPanel use esa imagen al hacer Implementar.
