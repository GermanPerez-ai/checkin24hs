# Desplegar la web (www.checkin24hs.com) con Git y EasyPanel

## Puertos en uso (resumen)

Cada servicio corre **dentro de su propio contenedor**. El puerto indicado es el **interno** del contenedor; Traefik enruta por **dominio**, no por puerto. No hay conflicto aunque varios usen el puerto 80.

| Servicio   | Puerto interno | Dominio                      |
|-----------|----------------|------------------------------|
| WhatsApp  | 3001           | whatsapp.checkin24hs.com      |
| Cotizador | 80             | cotizar.checkin24hs.com       |
| Webmail   | 80             | webmail.checkin24hs.com       |
| **Web**   | **80**         | **www.checkin24hs.com**       |
| Dashboard | (fuera del compose) | dashboard.checkin24hs.com |

El Dashboard se actualiza por otro flujo (no está en este compose para no pisarlo al hacer "Deploy from Compose").

---

## Flujo con Git

1. **Repositorio**: Tener el código en Git (GitHub, GitLab, etc.).
2. **En EasyPanel**: Crear (o usar) la app que se despliega desde **Compose** apuntando a este repo.
3. **Cada cambio**:
   - `git add` → `git commit` → `git push`
   - En EasyPanel: **Redeploy** (o “Deploy from Compose”). EasyPanel hace pull del repo, build de la imagen `web` desde `checkin24hs-web/` y levanta el servicio con Traefik.

---

## Configuración en EasyPanel

### 1. Origen del deploy

- **Deploy from Compose**: usar el archivo `docker-compose.easypanel.yml` del repo.
- Asegurar que la red `easypanel` exista (suele crearla EasyPanel/Traefik).

### 2. Build de la web

El servicio `web` se construye desde la carpeta `checkin24hs-web/` (Dockerfile dentro de esa carpeta). No hace falta elegir otro contexto.

### 3. Variables de entorno en tiempo de build (Vite)

La web usa variables `VITE_*` que se “hornean” en el build. Si en EasyPanel podés definir **Build args** para el servicio `web`, configurá:

- `VITE_SUPABASE_URL` = URL del proyecto Supabase  
- `VITE_SUPABASE_ANON_KEY` = anon key de Supabase  
- `VITE_COTIZADOR_URL` = `https://cotizar.checkin24hs.com` (o el que uses)  
- `VITE_FLOR_CHATBOT_URL` = URL del iframe del chatbot Flor (opcional)

Si EasyPanel no permite build args, hay dos alternativas:

- **Opción A**: Build en CI (GitHub Actions u otro), subir la imagen a un registry y en EasyPanel usar esa imagen en lugar de `build:`.  
- **Opción B**: Valores por defecto en el código y/o un backend que sirva la config en runtime (más trabajo).

### 4. DNS

- `www.checkin24hs.com` y, si querés, `checkin24hs.com` deben apuntar al servidor donde corre EasyPanel/Traefik.
- Traefik obtendrá el certificado HTTPS (Let’s Encrypt) con los labels del compose.

---

## Cómo correr la web por Git (resumen)

1. **Clonar** el repo en tu máquina o en el servidor.  
2. **Configurar** las variables de build (en EasyPanel Build args o en CI).  
3. **Deploy/Redeploy** desde EasyPanel usando `docker-compose.easypanel.yml`.  
4. La web quedará en **https://www.checkin24hs.com** (y en **https://checkin24hs.com** si configuraste ambos hosts).  
5. Los **puertos** no se exponen al exterior: Traefik escucha 443 y enruta por host; el contenedor `web` solo usa el puerto 80 internamente, sin pisar otros servicios.

---

## Verificar que no se pisen otros servicios

- **WhatsApp**: puerto 3001, solo en el contenedor `whatsapp`.  
- **Cotizador / Webmail / Web**: cada uno escucha 80 **dentro de su contenedor**. Traefik diferencia por `Host(...)`, así que no hay conflicto.  
- Si en el **host** (servidor) tenés algo escuchando en 3000, 3001, 80 o 443, eso es independiente de los contenedores; solo asegurate de que Traefik sea el que reciba el tráfico 80/443 (o el proxy que uses) y que el Dashboard u otras apps que corran en el host no usen el mismo puerto que Traefik.
