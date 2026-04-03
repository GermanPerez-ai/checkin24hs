# Incógnito vs normal y “subir todo como en local”

## Por qué en incógnito puede verse “versión antigua” aunque diga Build #79

Si en **Chrome normal** ves la versión actualizada y en **incógnito** ves algo que parece antiguo (pero sigue diciendo Build #79), suele ser por:

1. **Sesión distinta**  
   En incógnito no tenés las mismas cookies/sesión que en Chrome normal. Si no te logueás, el dashboard puede mostrarte menos menús (por ejemplo sin “Flor IA”, “Administradores”) o una vista más simple. Eso parece “versión antigua” pero es la misma app con otro estado de login.

2. **Mismo HTML, otra experiencia**  
   El mismo `dashboard.html` (Build #79) puede mostrar distinto según si estás logueado o no. Para comparar bien: **logueate en incógnito con el mismo usuario** que en Chrome normal y volvé a mirar; si después de eso se ve igual, era tema de sesión.

3. **Caché**  
   El servidor ya envía cabeceras para no cachear el HTML y el JS. Si aun así en incognito ves algo raro, probá cerrar la pestaña de incógnito, abrir una nueva y volver a entrar a `https://dashboard.checkin24hs.com`.

No hay service worker en este dashboard; el contenido lo sirve siempre el servidor con el mismo archivo.

## Subir todo como aparece en local

Para que en el servidor quede **exactamente** lo que tenés en tu máquina (dashboard, BUILD_ID, server, Dockerfile, compose):

### Opción A: Script en PowerShell (recomendado)

En tu PC, en la raíz del repo:

```powershell
.\scripts\subir_dashboard_como_local.ps1
```

El script:
1. Hace `git add` de los archivos del dashboard y relacionados.
2. Te pide mensaje de commit (o usa uno por defecto).
3. Hace `git commit` y `git push`.
4. Te muestra los comandos que tenés que ejecutar **en el servidor por SSH**.

Después, en el servidor, copiás y pegás esos comandos (entrar a `/root/checkin24hs`, `git pull`, build con BUILD_ID, `docker service update --force`). Así lo desplegado coincide con lo que tenés en local.

### Opción B: A mano

**En tu PC:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
git add dashboard.html deploy/dashboard.html deploy/dashboard-html/BUILD_ID deploy/dashboard-html/server.js deploy/dashboard-html/Dockerfile docker-compose.easypanel.yml supabase-client.js
git status
git commit -m "Dashboard: subir como local"
git push
```

**En el servidor (SSH):**

```bash
cd /root/checkin24hs
git fetch origin
git reset --hard origin/main
git pull
docker build -f deploy/dashboard-html/Dockerfile --build-arg BUILD_ID=79 -t easypanel/checkin24hs/dashboard:latest --no-cache .
docker service update --force checkin24hs_dashboard
```

(Reemplazá `BUILD_ID=79` por el número que estés usando; debe coincidir con el que está en `docker-compose.easypanel.yml` y en el HTML.)

Así “subís todo como aparece en local”: lo que está en el repo en tu PC es lo que se despliega después del `git pull` y del `docker build` en el servidor.
