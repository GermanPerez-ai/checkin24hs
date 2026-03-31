# Corregir 404: construir imagen web en el servidor

El 404 ocurre porque la imagen actual de **appwebcheckin24hs** se construyó con el Dockerfile del **dashboard**, no con el de la web pública. Hay que construir desde la carpeta **checkin24hs-web**.

## Paso 1: Que el servidor tenga la carpeta checkin24hs-web

La carpeta `checkin24hs-web` tiene que estar en el repositorio de GitHub. Si aún no la subiste:

**En tu PC (en la carpeta del repo):**
```powershell
cd c:\Users\German\Downloads\Checkin24hs
git add checkin24hs-web
git status
git commit -m "Agregar checkin24hs-web para www.checkin24hs.com"
git push origin main
```

## Paso 2: En el servidor, actualizar repo y construir desde checkin24hs-web

Conectate por SSH y ejecutá (reemplazá TU_PROYECTO y TU_ANON_KEY por los de Supabase):

```bash
ssh root@72.61.58.240

cd /root/checkin24hs
git pull

# Comprobar que exista la carpeta
ls -la checkin24hs-web

# Construir la imagen correcta (web React + nginx)
cd checkin24hs-web
docker build \
  --build-arg VITE_SUPABASE_URL=https://TU_PROYECTO.supabase.co \
  --build-arg VITE_SUPABASE_ANON_KEY=TU_ANON_KEY \
  --build-arg VITE_COTIZADOR_URL=https://cotizar.checkin24hs.com \
  -t easypanel/checkin24hs/appwebcheckin24hs:latest .
```

## Paso 3: Reiniciar el servicio en EasyPanel

En EasyPanel → **appwebcheckin24hs** → clic en **Reiniciar** (icono circular) o **Implementar**. Así el contenedor vuelve a arrancar con la nueva imagen.

Luego probá de nuevo: **https://www.checkin24hs.com**
