# Apache: proxy www.checkin24hs.com y checkin24hs.com → Traefik (cuando Apache tiene el 80)

Si **Apache** usa el puerto 80 en el host, el tráfico a www.checkin24hs.com llega a Apache y devuelve 404 porque la web está en **Traefik** (EasyPanel). Hay que hacer que Apache reenvíe esas peticiones a Traefik.

## 1. Ver quién escucha en 80 y 443

En el servidor:

```bash
ss -tlnp | grep -E ':80 |:443 '
```

- Si **Apache** aparece en **:80** y **Traefik** (o docker) en **:443**, entonces **HTTPS** (https://www.checkin24hs.com) debería ir a Traefik y funcionar. Probá primero **https://www.checkin24hs.com**.
- Si Apache tiene ambos (80 y 443), entonces tanto HTTP como HTTPS llegan a Apache y hay que hacer proxy de ambos a Traefik.

## 2. Saber en qué puerto escucha Traefik en el host

Traefik en Docker suele publicar 80 y 443. Si Apache ya usa 80, Traefik puede estar en otro puerto o no tener 80. Ejecutá:

```bash
ss -tlnp | grep -E 'docker|traefik|:80|:443'
docker service ls | grep -i traefik
docker service inspect checkin24hs_traefik --format '{{json .Endpoint.Ports}}' 2>/dev/null | jq .
```

Anotá en qué puerto del host está Traefik para HTTP y para HTTPS. Ejemplo: HTTP en 8080, HTTPS en 443 (o 8443 si 443 lo tiene Apache).

## 3. Crear vhost en Apache que haga proxy a Traefik

Sustituí `TRAEFIK_HTTP_PORT` (y si hace falta `TRAEFIK_HTTPS_PORT`) por el puerto que uses. Ejemplo: si Traefik en el host escucha HTTP en **8080** y HTTPS en **443**:

```bash
sudo nano /etc/apache2/sites-available/www-checkin24hs-proxy.conf
```

Contenido (proxy solo HTTP a Traefik en 8080; si querés también HTTPS, añadís un bloque similar para 443):

```apache
# Proxy www y checkin24hs.com (puerto 80) → Traefik
<VirtualHost *:80>
    ServerName www.checkin24hs.com
    ServerAlias checkin24hs.com
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/
</VirtualHost>
```

Si Traefik en el host usa otro puerto (por ejemplo 8880), cambiá `8080` por ese puerto.

Habilitar módulos y sitio:

```bash
sudo a2enmod proxy proxy_http
sudo a2ensite www-checkin24hs-proxy.conf
sudo systemctl reload apache2
```

## 4. Probar

```bash
curl -sI -H "Host: www.checkin24hs.com" http://127.0.0.1:80/
```

Deberías ver una respuesta 200 o 301/302, no 404.

En el navegador: **http://www.checkin24hs.com** debería cargar (o redirigir a https si lo configurás).

## 5. Si también querés HTTPS en Apache para www

Si Apache tiene 443 y querés que las peticiones HTTPS a www lleguen a la web (vía Traefik), necesitás un bloque `VirtualHost *:443` que haga proxy a la **puerto HTTPS** de Traefik en el host (ej. 8443 si Traefik usa ese para HTTPS cuando Apache usa 443). Eso implica certificados y más pasos; si Traefik ya tiene 443 en el host, lo más simple es que **HTTPS** vaya directo a Traefik (no a Apache) y solo uses este proxy para **HTTP** en el 80.

## Resumen

| Puerto | Quién lo tiene | Acción |
|--------|----------------|--------|
| 80     | Apache         | Vhost proxy www/checkin24hs.com → Traefik (puerto interno de Traefik en el host, ej. 8080). |
| 443    | Traefik        | Entrar con **https://www.checkin24hs.com** y no debería hacer falta proxy. |
| 443    | Apache         | Configurar proxy HTTPS a Traefik o liberar 443 para Traefik. |

Si **https://www.checkin24hs.com** ya funciona, solo hace falta este proxy para **http** (puerto 80).
