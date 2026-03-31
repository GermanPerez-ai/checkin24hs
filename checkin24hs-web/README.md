# Checkin24hs Web (www.checkin24hs.com)

Front-end público de la plataforma de reservas hoteleras para Argentina y Chile.

## Stack

- React 18 + TypeScript
- Vite
- React Router
- Supabase (datos y storage)
- Estilos: CSS modules + variables (azul royal, fondo #F5F5F5, acento dorado/esmeralda)

## Requisitos

1. **Supabase**: Ejecutar migraciones en `supabase-migrations/` (021, 022, 023) para columnas web en `hotels`, tabla `novedades` y tabla `slider_ofertas`.
2. **Variables de entorno**: Copiar `.env.example` a `.env` y configurar:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `VITE_FLOR_CHATBOT_URL` (URL del iframe del chatbot Flor; si está vacía, el widget no se muestra)
   - `VITE_COTIZADOR_URL` (por defecto https://cotizar.checkin24hs.com)

## Uso

```bash
npm install
npm run dev    # desarrollo
npm run build  # producción
npm run preview # previsualizar build
```

## Rutas

- `/` — Home: slider, buscador, listado de hoteles, destinos, novedades, sobre nosotros, footer
- `/hotel/:slug` — Detalle del hotel (por slug o id), botón Cotizar con parámetros

## Flor IA

El widget Flor se carga en todas las páginas si `VITE_FLOR_CHATBOT_URL` está definida. Se pasan parámetros por URL al iframe para contexto:

- `hotel` — slug del hotel (cuando el usuario está en la ficha de un hotel)
- `hotel_name` — nombre del hotel
- `destino` — id del destino (ej. bariloche, villa-la-angostura)

En `flor-chatbot.html` (o el backend del chat) se puede leer `window.location.search` para precompletar el contexto de la conversación.

## Cotizador

El botón "Cotizar" redirige a `VITE_COTIZADOR_URL` con: `?hotel_id=...&checkin=...&checkout=...&pax=...`

---

## Docker y EasyPanel

La web está integrada en el compose de EasyPanel del repo raíz.

- **Dockerfile**: build en dos etapas (Node para Vite, nginx para servir). Puerto **80** dentro del contenedor.
- **Compose**: servicio `web` en `docker-compose.easypanel.yml`; dominios `www.checkin24hs.com` y `checkin24hs.com`.
- **Despliegue por Git**: push al repo → en EasyPanel, Redeploy from Compose. Ver `docs/DEPLOY_WEB_EASYPANEL.md` en la raíz del repo.

Build local (con env para Supabase):

```bash
cd checkin24hs-web
docker build --build-arg VITE_SUPABASE_URL=https://xxx.supabase.co --build-arg VITE_SUPABASE_ANON_KEY=xxx -t checkin24hs-web .
docker run -p 3002:80 checkin24hs-web
```

Abrir http://localhost:3002. El puerto 3002 es solo para pruebas locales; en el servidor Traefik enruta por host y el contenedor usa 80 internamente sin pisar otros servicios.
