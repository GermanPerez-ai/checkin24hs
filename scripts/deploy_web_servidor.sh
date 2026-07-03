#!/bin/bash
# Build y deploy de la WEB (www.checkin24hs.com) SIN CACHÉ.
# Ejecutar EN EL SERVIDOR: cd /root/checkin24hs && bash scripts/deploy_web_servidor.sh
# Requiere: .env en /root/checkin24hs con VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY (para npm run build).

set -e
cd /root/checkin24hs

echo "=== 1. Git pull ==="
git pull origin main || true
echo "Último commit: $(git log -1 --oneline)"
if ! grep -qE "carouselTrack|AlojamientosCarousel" checkin24hs-web/src/components/Novedades.tsx checkin24hs-web/src/components/AlojamientosCarousel.tsx 2>/dev/null; then
  echo "AVISO: En el repo no aparece el código del carrusel. ¿Hiciste push de los cambios?"
fi

echo ""
echo "=== 2. Build de la imagen web SIN CACHÉ (desde checkin24hs-web para contexto correcto) ==="
# Cargar .env del repo para build-args
set -a
[ -f .env ] && . ./.env
set +a
cd checkin24hs-web
# Tag unico para que EasyPanel no pise esta imagen con un build viejo
WEB_TAG="build-$(git rev-parse --short HEAD 2>/dev/null || echo $(date +%s))"
echo "Imagen: easypanel/checkin24hs/web:$WEB_TAG"
docker build --no-cache -t "easypanel/checkin24hs/web:$WEB_TAG" \
  --build-arg VITE_SUPABASE_URL="${VITE_SUPABASE_URL}" \
  --build-arg VITE_SUPABASE_ANON_KEY="${VITE_SUPABASE_ANON_KEY}" \
  --build-arg VITE_COTIZADOR_URL="${VITE_COTIZADOR_URL:-https://cotizar.checkin24hs.com}" \
  --build-arg VITE_FLOR_CHATBOT_URL="${VITE_FLOR_CHATBOT_URL:-https://www.checkin24hs.com/flor-chatbot.html}" \
  --build-arg VITE_FLOR_API_URL="${VITE_FLOR_API_URL:-https://flor-api.checkin24hs.com}" \
  -f Dockerfile .
cd ..
# Verificar que la imagen nueva incluye carruseles (novedades + alojamientos)
if ! docker run --rm "easypanel/checkin24hs/web:$WEB_TAG" grep -rqE "carousel|AlojamientosCarousel|alojamientos-layout" /usr/share/nginx/html/ 2>/dev/null; then
  echo "AVISO: La imagen construida NO contiene marcadores de carrusel. Revisá si el build falló o usó código viejo."
  exit 1
fi
echo "OK: La imagen contiene el código de carruseles (novedades/alojamientos)."
# Verificar que incluye el botón WhatsApp en el HTML
if ! docker run --rm "easypanel/checkin24hs/web:$WEB_TAG" grep -q "whatsapp-floating-btn" /usr/share/nginx/html/index.html 2>/dev/null; then
  echo "AVISO: index.html en la imagen NO contiene el botón WhatsApp."
else
  echo "OK: La imagen incluye el botón WhatsApp en index.html."
fi
# Verificar Supabase (anon key JWT) y Google tag
if ! docker run --rm "easypanel/checkin24hs/web:$WEB_TAG" sh -c "grep -rq 'eyJ' /usr/share/nginx/html/assets/index-*.js" 2>/dev/null; then
  echo "ERROR: La imagen NO incluye VITE_SUPABASE_ANON_KEY. Revisá .env (sin comillas) y volvé a construir."
  exit 1
fi
echo "OK: La imagen incluye la anon key de Supabase."
if docker run --rm "easypanel/checkin24hs/web:$WEB_TAG" grep -q "AW-18248233784" /usr/share/nginx/html/index.html 2>/dev/null; then
  echo "OK: La imagen incluye el Google tag."
else
  echo "AVISO: index.html no contiene el Google tag AW-18248233784."
fi
# Tambien como latest para quien use ese tag
docker tag "easypanel/checkin24hs/web:$WEB_TAG" easypanel/checkin24hs/web:latest

echo ""
echo "=== 3. Actualizar servicios con la imagen con tag unico (evita que otro build pise) ==="
for svc in checkin24hs_web checkin24hs_appwebcheckin24hs; do
  if docker service ls -q --filter "name=$svc" | grep -q .; then
    echo "Actualizando $svc con easypanel/checkin24hs/web:$WEB_TAG ..."
    docker service update --image "easypanel/checkin24hs/web:$WEB_TAG" "$svc"
  else
    echo "($svc no existe, se omite)"
  fi
done

echo ""
echo "=== Listo. En 1-2 min probá https://www.checkin24hs.com (Ctrl+Shift+R o ventana incógnito). ==="
echo "Si no cambia nada, revisá scripts/diagnostico_web_deploy.md y ejecutá los comandos que indica."
