# Flor-api en puerto 8081 (solución que funciona)

En el servidor, el proxy de Apache para **flor-api.checkin24hs.com** en el **puerto 80** no se usa (otro vhost responde antes). El **mismo proxy en el puerto 8081** sí responde correctamente.

## Comprobar que 8081 funciona

En el servidor:

```bash
curl -v -H "Host: flor-api.checkin24hs.com" http://127.0.0.1:8081/health
```

Debe devolver **HTTP 200** y JSON (p. ej. `{"ok":true,"service":"flor-web-api"}`).

## Usar flor-api desde la web

1. **Firewall:** abrir el puerto **8081** para que las peticiones externas lleguen a Apache:
   ```bash
   sudo ufw allow 8081/tcp
   sudo ufw reload
   ```

2. **URL de la API:**  
   - Con **HTTP:** `http://flor-api.checkin24hs.com:8081`  
   - Con **HTTPS:** configurar SSL en el vhost de 8081 (certbot u otro) y usar `https://flor-api.checkin24hs.com:8081`

3. **Build de la web:** definir la variable de entorno al construir:
   ```bash
   VITE_FLOR_API_URL=https://flor-api.checkin24hs.com:8081
   ```
   (o `http://...` si no tenés SSL en 8081).  
   En EasyPanel / compose, usar ese valor en `VITE_FLOR_API_URL` para el servicio de la web.

4. **CORS:** `flor-web-api` ya permite `www.checkin24hs.com`; si usás otro origen, añadirlo en el backend.

## Resumen

| Puerto | Estado |
|--------|--------|
| 80     | El vhost de flor-api no se usa; responde otro sitio (p. ej. 404). |
| 8081   | El proxy funciona; usar esta URL para la web y abrir 8081 en el firewall. |

Configuración Apache que funciona: `/etc/apache2/sites-available/flor-api-8081.conf` (VirtualHost *:8081) con `ProxyPass / http://127.0.0.1:8080/` y `Listen 8081` en `ports.conf`.
