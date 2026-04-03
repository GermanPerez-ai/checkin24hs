# Liberar puerto 80 de Apache para que Traefik enrute flor-api

## Problema
Apache escucha en el puerto 80 del host. El tráfico HTTP (flor-api.checkin24hs.com, etc.) llega a Apache y devuelve 404. Traefik (Docker Swarm) tiene 80 y 443 publicados pero no recibe el tráfico en 80 porque Apache lo está usando.

## Solución: dejar de usar 80 en Apache

Ejecutar en el servidor (SSH como root o con sudo).

### Opción A – Deshabilitar el sitio por defecto de Apache (recomendado)

```bash
# Ver sitios habilitados
ls -la /etc/apache2/sites-enabled/

# Deshabilitar el sitio por defecto (libera el puerto 80)
sudo a2dissite 000-default.conf
# Si el archivo se llama 000-default (sin .conf), usá:
# sudo a2dissite 000-default

# Recargar Apache
sudo systemctl reload apache2

# Comprobar que 80 ya no lo usa Apache
sudo ss -tlnp | grep ':80'
# Debería mostrar docker o nada de apache2.
```

### Opción B – Hacer que Apache escuche solo en otro puerto (ej. 8080)

Si necesitás seguir sirviendo algo con Apache en otro puerto:

```bash
# Editar puerto por defecto
sudo sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
# Ajustar el VirtualHost del sitio por defecto a 8080 si hace falta
sudo systemctl reload apache2
```

Luego Traefik debería poder usar el 80 (a veces hace falta reiniciar el servicio traefik en Swarm).

## Después de liberar el 80

1. Probar desde el servidor:
   ```bash
   curl -s -H "Host: flor-api.checkin24hs.com" http://127.0.0.1:80/health
   ```
   Debería devolver: `{"ok":true,"service":"flor-web-api"}`

2. En el navegador:
   - https://flor-api.checkin24hs.com/health
   - https://checkin24hs-flor-api.8vmdd2.easypanel.host/health

Si Apache debe seguir en 80 para otro dominio, en su lugar habría que configurar un proxy inverso en Apache que envíe las peticiones de flor-api.checkin24hs.com (y el host de EasyPanel) a Traefik; es más complejo. Lo más simple es liberar 80 para Traefik.
