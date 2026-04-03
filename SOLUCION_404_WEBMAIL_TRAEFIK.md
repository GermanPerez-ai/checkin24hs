# Solución: 404 en Webmail (Traefik o contenedor)

## Diagnosticar de dónde sale el 404

Ejecuta en el servidor (o copia/pega todo el bloque):

```bash
SERVICE_NAME="checkin24hs_webmail"
DOMAIN="webmail.checkin24hs.com"
CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)

echo "1. Contenedor: $CONTAINER_ID"
echo "2. Respuesta DIRECTA del contenedor (sin Traefik):"
docker exec "$CONTAINER_ID" curl -s -o /dev/null -w "   HTTP %{http_code}\n" http://localhost/

echo "3. Respuesta via Traefik (desde el servidor):"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" -k "https://$DOMAIN/"

echo "4. Headers de respuesta:"
curl -sI -k "https://$DOMAIN/" | head -10

echo "5. Labels Traefik del servicio webmail:"
docker service inspect "$SERVICE_NAME" --format '{{range $k,$v := .Spec.Labels}}{{if or (eq (printf "%.6s" $k) "traefik") (eq (printf "%.6s" $k) "Traefik")}}{{$k}}={{$v}}{{"\n"}}{{end}}{{end}}'
```

### Cómo interpretar

| Contenedor directo | Via Traefik | Conclusión |
|-------------------|-------------|------------|
| 200 | 404 | **Problema en Traefik** (ruta, backend o dominio). |
| 200 | 200 | No deberías ver 404; revisa la URL exacta que usas. |
| 404 | 404 | **Problema en Roundcube** (ruta interna o config). |
| 000 / error | 404 | Contenedor caído o Traefik no llega al backend. |

---

## Si el 404 viene de Traefik

1. **Comprobar que el servicio webmail está en la red de Traefik**
   ```bash
   docker service inspect checkin24hs_webmail --format '{{json .Spec.TaskTemplate.Networks}}'
   docker network ls | grep -i traefik
   ```
   El servicio debe estar conectado a la misma red que Traefik (p. ej. `easypanel` o la que use Traefik).

2. **Comprobar labels de Traefik del servicio webmail**
   En EasyPanel → Servicio **webmail** → pestaña donde se configuran dominios/labels (a veces "Domains" o "Advanced").
   Debe haber algo como:
   - `traefik.http.routers.webmail.rule=Host(\`webmail.checkin24hs.com\`)`
   - `traefik.http.services.webmail.loadbalancer.server.port=80`
   Y el **puerto** del backend debe ser **80** (el que escucha Roundcube dentro del contenedor).

3. **Recrear el router de Traefik**
   A veces Traefik no actualiza bien. En EasyPanel:
   - Guarda de nuevo el servicio webmail (sin cambiar nada) y haz **Implementar/Deploy**.
   O por consola:
   ```bash
   docker service update --force checkin24hs_webmail
   ```
   Espera ~30 s y prueba de nuevo `https://webmail.checkin24hs.com`.

4. **Ver logs de Traefik**
   ```bash
   docker service logs traefik --tail 100 2>&1 | grep -i webmail
   ```
   Si ves errores de "backend not found" o "service not found", el problema es la definición del servicio/ruta en Traefik.

---

## Si el 404 viene del contenedor (Roundcube)

1. **Comprobar que el archivo de config SSL no rompió nada**
   Entrar al contenedor y listar la config:
   ```bash
   CONTAINER_ID=$(docker ps --filter "name=webmail" --format "{{.ID}}" | head -1)
   docker exec "$CONTAINER_ID" ls -la /var/www/html/config/
   docker exec "$CONTAINER_ID" head -5 /var/www/html/config/config.ssl.inc.php
   ```
   Si `config.ssl.inc.php` tiene sintaxis PHP incorrecta (comillas raras, etc.), podría afectar. En ese caso puedes renombrarlo para desactivarlo:
   ```bash
   docker exec "$CONTAINER_ID" mv /var/www/html/config/config.ssl.inc.php /var/www/html/config/config.ssl.inc.php.bak
   ```
   Y volver a probar la URL (sin el fix SSL, el login IMAP puede seguir fallando, pero al menos verás si el 404 era por la config).

2. **URL correcta**
   Usar exactamente:
   - `https://webmail.checkin24hs.com/`
   - o `https://webmail.checkin24hs.com/?_task=login`
   Evitar rutas que no existan (p. ej. `/login` a secas puede dar 404 en algunas instalaciones).

3. **Reiniciar el servicio webmail**
   ```bash
   docker service update --force checkin24hs_webmail
   ```
   Por si el cambio de config dejó el PHP en un estado raro.

---

## Resumen

- **404 y sospecha de Traefik:** usa el script de diagnóstico; si el contenedor responde 200 y Traefik 404, revisa red, labels y puerto del backend en Traefik/EasyPanel.
- **404 y sospecha de Roundcube:** revisa `config.ssl.inc.php`, URL exacta y reinicio del servicio.

Si quieres, pega aquí la salida del bloque de diagnóstico (puntos 1–5) y la interpretamos.
