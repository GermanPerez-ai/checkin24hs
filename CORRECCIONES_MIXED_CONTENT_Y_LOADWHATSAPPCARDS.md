# Correcciones: Mixed Content y loadWhatsAppCards

## Problemas Corregidos

### 1. ❌ ReferenceError: loadWhatsAppCards is not defined
- **Problema**: La función `loadWhatsAppCards` está comentada pero se intenta asignar globalmente
- **Línea**: 9430
- **Solución**: Comentada la asignación global
- **Código**:
```javascript
// ANTES:
window.loadWhatsAppCards = loadWhatsAppCards;

// DESPUÉS:
// window.loadWhatsAppCards = loadWhatsAppCards; // Función deshabilitada
```

### 2. ⚠️ Mixed Content: HTTP en iframes de WhatsApp
- **Problema**: Los iframes usan HTTP (`http://72.61.58.240:3001/`) en una página HTTPS
- **Errores**: 
  - `Mixed Content: The page at 'https://dashboard.checkin24hs.com/#' was loaded over HTTPS, but requested an insecure frame 'http://72.61.58.240:3001/'.`
- **Solución**: Cambiados a HTTPS con dominios
- **Cambios**:
  - `http://72.61.58.240:3001/` → `https://whatsapp1.checkin24hs.com/`
  - `http://72.61.58.240:3002/` → `https://whatsapp2.checkin24hs.com/`
  - `http://72.61.58.240:3003/` → `https://whatsapp3.checkin24hs.com/`
  - `http://72.61.58.240:3004/` → `https://whatsapp4.checkin24hs.com/`

### 3. ⚠️ Referencias HTTP restantes
- **Ubicaciones encontradas**:
  - Línea 9327: `'http://72.61.58.240'`
  - Línea 9397: `'http://72.61.58.240'`
  - Línea 10244: `serverUrl = 'http://72.61.58.240'`
  - Línea 21859: `'http://72.61.58.240'`
  - Línea 22381: `'http://72.61.58.240:3001'` ✅ **Ya corregido**

## ⚠️ IMPORTANTE: Configurar Dominios HTTPS

Para que los iframes funcionen, necesitas configurar en Traefik:

1. **Crear registros DNS** (A o CNAME):
   - `whatsapp1.checkin24hs.com` → `72.61.58.240`
   - `whatsapp2.checkin24hs.com` → `72.61.58.240`
   - `whatsapp3.checkin24hs.com` → `72.61.58.240`
   - `whatsapp4.checkin24hs.com` → `72.61.58.240`

2. **Configurar Traefik** para cada servicio WhatsApp:
```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.whatsapp1.rule=Host(\`whatsapp1.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.whatsapp1.entrypoints=websecure" \
  --label-add "traefik.http.routers.whatsapp1.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.whatsapp1.loadbalancer.server.port=3001" \
  checkin24hs_whatsapp1
```

3. **Alternativa temporal**: Si no puedes configurar HTTPS ahora, puedes comentar los iframes temporalmente.

## Comandos para Aplicar

```bash
# Subir archivo corregido
scp deploy/dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/

# Copiar al contenedor
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
docker cp /root/checkin24hs/deploy/dashboard.html $CONTAINER_ID:/app/dashboard.html

# Verificar correcciones
docker exec $CONTAINER_ID grep -n "loadWhatsAppCards" /app/dashboard.html | head -3
docker exec $CONTAINER_ID grep -n "whatsapp1.checkin24hs.com" /app/dashboard.html | head -1
```

## Verificación

Después de aplicar:
1. Recargar Dashboard con `Ctrl+F5`
2. Abrir consola (F12)
3. Verificar que NO aparezcan:
   - `ReferenceError: loadWhatsAppCards is not defined`
   - `Mixed Content` warnings
4. Los iframes deberían cargar (si los dominios HTTPS están configurados)

## Nota sobre localStorage lleno

Los warnings de `localStorage` lleno son normales cuando hay muchos datos. El sistema ya está usando Supabase como fuente principal, así que estos warnings no afectan la funcionalidad.


















