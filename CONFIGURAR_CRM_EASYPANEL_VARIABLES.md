# Configurar CRM en EasyPanel usando Variables de Entorno

Si EasyPanel no muestra la opción de etiquetas Traefik, puedes configurar el CRM usando variables de entorno.

## Pasos en EasyPanel:

1. **Accede a EasyPanel** → Ve al servicio `checkin24hs_crm`

2. **Ve a la sección "Environment Variables" o "Variables de Entorno"**

3. **Agrega estas variables de entorno:**

   ```
   TRAEFIK_ENABLE=true
   TRAEFIK_HTTP_ROUTERS_CRM_RULE=Host(`crm.checkin24hs.com`)
   TRAEFIK_HTTP_ROUTERS_CRM_ENTRYPOINTS=web,websecure
   TRAEFIK_HTTP_SERVICES_CRM_LOADBALANCER_SERVER_PORT=3005
   TRAEFIK_DOCKER_NETWORK=easypanel
   ```

4. **O si EasyPanel tiene una sección de "Labels" o "Etiquetas", agrega:**

   ```
   traefik.enable=true
   traefik.http.routers.crm.rule=Host(`crm.checkin24hs.com`)
   traefik.http.routers.crm.entrypoints=web
   traefik.http.routers.crm.entrypoints=websecure
   traefik.http.services.crm.loadbalancer.server.port=3005
   traefik.docker.network=easypanel
   ```

5. **Guarda los cambios y reinicia el servicio**

6. **Espera 1-2 minutos** para que Traefik detecte los cambios

7. **Prueba acceder a:** `http://crm.checkin24hs.com`

## Alternativa: Configurar Redirección en Traefik

Si EasyPanel no permite configurar etiquetas, puedes crear una configuración de redirección directa en Traefik:

1. **Crea un archivo de configuración de Traefik** (si está montado):
   ```yaml
   http:
     routers:
       crm:
         rule: "Host(`crm.checkin24hs.com`)"
         entryPoints:
           - web
           - websecure
         service: crm-service
     services:
       crm-service:
         loadBalancer:
           servers:
             - url: "http://tasks.checkin24hs_crm:3005"
   ```

2. **O configura una redirección en nginx/apache** si está disponible

## Verificar Configuración Actual

Ejecuta estos comandos para ver cómo está configurado actualmente:

```bash
# Ver variables de entorno del CRM
docker service inspect checkin24hs_crm --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{.}}{{println}}{{end}}'

# Ver variables de entorno del Dashboard (para comparar)
docker service inspect checkin24hs_dashboard --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{.}}{{println}}{{end}}'

# Ver configuración completa del servicio
docker service inspect checkin24hs_crm --format '{{json .Spec}}' | python3 -m json.tool | head -100
```


















