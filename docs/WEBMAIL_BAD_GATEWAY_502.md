# Webmail 502 Bad Gateway – Solución

Cuando **webmail.checkin24hs.com** responde con **502 Bad Gateway**, Traefik recibe la petición pero no logra conectar con el contenedor de Roundcube.

---

## Causa

En Docker Swarm, el nombre del servicio (`checkin24hs_webmail`) resuelve por defecto a una **VIP** (Virtual IP). En algunos entornos esa VIP no es alcanzable desde Traefik, por eso devuelve 502 aunque el servicio esté en marcha.

**Solución:** usar `endpoint-mode dnsrr` para que el nombre resuelva a la **IP real del task**, a la que Traefik sí puede conectar.

---

## Solución rápida (en el servidor)

```bash
cd /root/checkin24hs
bash SOLUCIONAR_WEBMAIL_502_BAD_GATEWAY.sh
```

El script:
- Solo modifica **checkin24hs_webmail**
- No toca dashboard, whatsapp ni cotizador
- Quita puertos publicados si los hay (requisito para dnsrr)
- Activa `endpoint-mode dnsrr`
- Asegura red easypanel y etiquetas Traefik
- Reinicia Traefik

---

## Pasos manuales (si prefieres)

### 1. Quitar puerto publicado

EasyPanel puede publicar un puerto (ej. 3080→80). Hay que quitarlo para poder usar dnsrr:

```bash
docker service inspect checkin24hs_webmail --format '{{json .Spec.EndpointSpec}}'
# Si ves "Ports":[...], quita el puerto destino 80:
docker service update --publish-rm 80 checkin24hs_webmail
```

En **EasyPanel** → webmail → **Puertos**: elimina cualquier regla si aparece.

### 2. Activar dnsrr

```bash
docker service update --endpoint-mode dnsrr checkin24hs_webmail
```

### 3. Verificar red

```bash
# Asegurar que webmail esté en la red de Traefik
docker service update --network-add easypanel checkin24hs_webmail
```

### 4. Reiniciar Traefik

```bash
docker service update --force traefik
```

Espera 1–2 minutos y prueba https://webmail.checkin24hs.com

---

## Servicios que no se modifican

| Servicio     | Puerto | No se toca |
|-------------|--------|------------|
| dashboard   | 80     | Sí         |
| whatsapp    | 3001   | Sí         |
| cotizador   | 80     | Sí         |
| webmail     | 80     | Este es el que se corrige |

---

## Diagnóstico

```bash
# Estado del servicio
docker service ps checkin24hs_webmail --no-trunc

# Modo de endpoint
docker service inspect checkin24hs_webmail --format '{{json .Spec.EndpointSpec}}'
# Debe mostrar: {"Mode":"dnsrr"} sin "Ports"

# Probar desde la red easypanel
docker run --rm --network easypanel curlimages/curl:latest curl -sI http://checkin24hs_webmail:80/
```

Si el curl devuelve HTTP 200 y el navegador sigue mostrando 502, suele bastar con reiniciar Traefik:  
`docker service update --force traefik`
