# Comandos para aplicar cambios (PowerShell + Servidor)

Usá este documento cada vez que hagas cambios en el repo y quieras subirlos y desplegarlos.

---

## 1. PowerShell (en tu PC Windows)

Ejecutá en la carpeta del proyecto. Reemplazá la lista de archivos si solo tocaste otros.

### Subir cambios al repo (GitHub)

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Ver qué archivos cambiaron
git status

# Añadir los archivos modificados (ajustá si cambiaste otros)
git add whatsapp-server/whatsapp-server-baileys.js dashboard.html deploy/dashboard.html

# Commit con mensaje descriptivo
git commit -m "Flor: alerta Slack reserva, pie cotización, modo silencio 20min, context window 10 mensajes"

# Traer cambios remotos y poner tu commit encima (evita rechazo del push)
git pull --rebase origin main

# Subir a GitHub
git push origin main
```

### Si solo tocaste el servidor WhatsApp

```powershell
git add whatsapp-server/whatsapp-server-baileys.js
git commit -m "Flor: modo silencio + context window 10 mensajes"
git pull --rebase origin main
git push origin main
```

### Si solo tocaste el dashboard (HTML)

```powershell
git add dashboard.html deploy/dashboard.html
git commit -m "Dashboard: pie cotización Gracias por su consulta"
git pull --rebase origin main
git push origin main
```

---

## 2. Servidor (Linux – SSH como root o usuario con acceso)

Conectate por SSH y ejecutá en el directorio del proyecto (ej. `~/checkin24hs`).

### Actualizar código desde GitHub

```bash
cd ~/checkin24hs
git pull origin main
```

### Redeploy del servicio WhatsApp (EasyPanel / Docker)

Si usás **EasyPanel**: después del `git pull`, en la interfaz de EasyPanel → Servicio **whatsapp** → **Redeploy** (o **Deploy**).

Si usás **Docker/Swarm** directo en el servidor:

```bash
# Ver nombre del servicio
docker service ls | grep whatsapp

# Forzar actualización del servicio (usa la imagen/código actual)
docker service update --force checkin24hs_whatsapp
```

### Aplicar Traefik a WhatsApp (si da 404 en https://whatsapp.checkin24hs.com)

Solo si el dominio de WhatsApp deja de responder (404). Ejecutá en el servidor:

```bash
cd ~/checkin24hs

# Opción A: script del repo (si existe)
bash scripts/aplicar_traefik_whatsapp_servidor.sh

# Opción B: comandos manuales
docker service update --network-add easypanel checkin24hs_whatsapp

docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.docker.network=easypanel" \
  --label-add 'traefik.http.routers.whatsapp.rule=Host(`whatsapp.checkin24hs.com`)' \
  --label-add "traefik.http.routers.whatsapp.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp.service=whatsapp" \
  --label-add "traefik.http.routers.whatsapp.tls=true" \
  --label-add "traefik.http.routers.whatsapp.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp.loadbalancer.server.port=3001" \
  checkin24hs_whatsapp
```

Luego esperar ~1 minuto y probar:

```bash
curl -sI https://whatsapp.checkin24hs.com/status
```

---

## Orden recomendado cada vez que cambies código

1. **En PowerShell (PC):** `git add` → `git commit` → `git pull --rebase origin main` → `git push origin main`
2. **En el servidor:** `cd ~/checkin24hs` → `git pull origin main`
3. **Redeploy** del servicio afectado (WhatsApp y/o Dashboard) desde EasyPanel o con `docker service update --force ...`
