# Apache: proxy flor-api.checkin24hs.com → contenedor en 8080

Flor-api escucha en **puerto 8080** dentro del contenedor.

> **Si en el puerto 80 el vhost no responde** (p. ej. 404 en lugar del JSON de `/health`), usar el proxy en **puerto 8081**. Ver [FLOR_API_PUERTO_8081.md](FLOR_API_PUERTO_8081.md). Apache sigue en 80 y hace proxy solo para este subdominio, sin tocar webmail.

## 1. Publicar el puerto 8080 del contenedor en el host

En **EasyPanel** → **flor-api** → pestaña **Recursos** (o donde esté "Puertos" / "Published ports"):  
publicar **8080** hacia el host (ej. 8080:8080). Así el host escucha en 8080 y reenvía al contenedor.

Si no ves esa opción, en el servidor podés publicar el puerto del servicio (una vez desplegado):

```bash
docker service update --publish-add 8080:8080 checkin24hs_flor-api
```

## 2. Sitio Apache para flor-api (proxy al 8080)

Crear el archivo del sitio:

```bash
sudo nano /etc/apache2/sites-available/flor-api.checkin24hs.com.conf
```

Contenido:

```apache
<VirtualHost *:80>
    ServerName flor-api.checkin24hs.com
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/
</VirtualHost>
```

Para que Apache use este vhost antes que webmail, el archivo debe cargarse primero. Renombrar el enlace en `sites-enabled`:

```bash
sudo mv /etc/apache2/sites-enabled/flor-api.checkin24hs.com.conf /etc/apache2/sites-enabled/000-flor-api.checkin24hs.com.conf
sudo systemctl reload apache2
```

Habilitar módulos y sitio:

```bash
sudo a2enmod proxy proxy_http
sudo a2ensite flor-api.checkin24hs.com.conf
sudo systemctl reload apache2
```

## 3. Comprobar

En el servidor:

```bash
curl -s -H "Host: flor-api.checkin24hs.com" http://127.0.0.1:80/health
```

Debería devolver: `{"ok":true,"service":"flor-web-api"}`.

En el navegador: **http://flor-api.checkin24hs.com/health** (y luego **https://** si tenés SSL en Apache para ese dominio).

## Resumen

- Apache sigue en 80; webmail y el resto no se tocan.
- Solo las peticiones a **flor-api.checkin24hs.com** se reenvían al contenedor en 8080.
- El contenedor flor-api debe tener el puerto **8080** publicado en el host (EasyPanel o `docker service update`).
