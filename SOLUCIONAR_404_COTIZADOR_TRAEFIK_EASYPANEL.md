# 🔧 Solucionar Error 404 del Cotizador - Traefik

## 🎯 Problema

Después de implementar/reconstruir el servicio del cotizador en EasyPanel, aparece error **404** al acceder a `https://cotizar.checkin24hs.com/`.

## 🔍 Causa

El problema es que **Traefik no tiene las etiquetas (labels) configuradas** para enrutar el dominio al servicio. Cuando reconstruyes un servicio en EasyPanel, las etiquetas de Traefik pueden perderse si no están configuradas en la interfaz.

## ✅ Solución Rápida

### Opción 1: Usar el Script Automático (Recomendado)

1. **Conectarse al servidor:**
   ```bash
   ssh root@72.61.58.240
   ```

2. **Ejecutar el script:**
   ```bash
   cd /root/checkin24hs
   chmod +x SOLUCIONAR_404_COTIZADOR_TRAEFIK.sh
   ./SOLUCIONAR_404_COTIZADOR_TRAEFIK.sh
   ```

3. **Esperar 1-2 minutos** y probar: `https://cotizar.checkin24hs.com/`

---

### Opción 2: Configurar Manualmente desde SSH

1. **Conectarse al servidor:**
   ```bash
   ssh root@72.61.58.240
   ```

2. **Buscar el servicio del cotizador:**
   ```bash
   docker service ls | grep -i cotizador
   ```
   
   Anota el nombre del servicio (puede ser `cotizador` o `checkin24hs_cotizador`)

3. **Verificar la red del servicio:**
   ```bash
   docker service inspect <NOMBRE_SERVICIO> --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'
   ```
   
   Debe estar en la red `easypanel`

4. **Configurar etiquetas Traefik:**
   ```bash
   docker service update \
     --label-add "traefik.enable=true" \
     --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
     --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
     --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
     --label-add "traefik.http.routers.cotizador.service=cotizador-service" \
     --label-add "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
     --label-add "traefik.docker.network=easypanel" \
     <NOMBRE_SERVICIO>
   ```

5. **Esperar 30-60 segundos** y probar: `https://cotizar.checkin24hs.com/`

---

### Opción 3: Configurar desde EasyPanel (Si está disponible)

1. **Accede a EasyPanel:**
   - Ve a: `http://72.61.58.240:3000`
   - Inicia sesión

2. **Ve al servicio del cotizador:**
   - Busca el servicio `cotizador` o similar
   - Haz clic en él

3. **Ve a la pestaña "Dominios":**
   - Verifica que `cotizar.checkin24hs.com` esté configurado
   - Si no está, agrégalo:
     - **Host:** `cotizar.checkin24hs.com`
     - **HTTPS:** Habilitado
     - **Protocolo:** HTTP
     - **Puerto:** `80`
     - **Ruta:** `/`

4. **Guarda los cambios** y espera 1-2 minutos

---

## 🔍 Verificación

### 1. Verificar que el servicio está corriendo:
```bash
docker service ps <NOMBRE_SERVICIO>
```

Debe mostrar estado "Running"

### 2. Verificar etiquetas Traefik:
```bash
docker service inspect <NOMBRE_SERVICIO> --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik
```

Debe mostrar las etiquetas configuradas

### 3. Verificar que el contenedor responde:
```bash
CONTAINER_ID=$(docker ps --format "{{.ID}}" --filter "name=<NOMBRE_SERVICIO>" | head -1)
docker exec $CONTAINER_ID wget -qO- http://localhost:80 | head -10
```

Debe mostrar el contenido HTML del cotizador

### 4. Verificar logs de Traefik:
```bash
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
docker logs $TRAEFIK_CONTAINER --tail 100 | grep -i cotizar
```

Debe mostrar referencias al dominio `cotizar.checkin24hs.com`

### 5. Probar desde el navegador:
- Abre: `https://cotizar.checkin24hs.com/`
- Debe mostrar el formulario de cotización (NO error 404)

---

## 🆘 Si Sigue Dando 404

### Verificar DNS:
```bash
nslookup cotizar.checkin24hs.com
```

Debe devolver la IP del servidor: `72.61.58.240`

### Verificar que Traefik está corriendo:
```bash
docker ps | grep traefik
```

### Verificar que el servicio está en la red correcta:
```bash
docker service inspect <NOMBRE_SERVICIO> --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'
```

Debe incluir `easypanel`

### Reiniciar Traefik (último recurso):
```bash
docker service update --force traefik
```

Espera 1-2 minutos y prueba de nuevo

---

## 📝 Etiquetas Traefik Necesarias

Para que Traefik enrute correctamente, el servicio necesita estas etiquetas:

- `traefik.enable=true` - Habilita Traefik para este servicio
- `traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)` - Regla de enrutamiento
- `traefik.http.routers.cotizador.entrypoints=websecure` - Entrypoint HTTPS
- `traefik.http.routers.cotizador.tls.certresolver=letsencrypt` - Certificado SSL
- `traefik.http.routers.cotizador.service=cotizador-service` - Servicio asociado
- `traefik.http.services.cotizador-service.loadbalancer.server.port=80` - Puerto del servicio
- `traefik.docker.network=easypanel` - Red Docker

---

## ✅ Resumen

**Problema:** Error 404 después de reconstruir el servicio  
**Causa:** Faltan etiquetas Traefik  
**Solución:** Configurar etiquetas Traefik manualmente o desde EasyPanel  
**Tiempo:** 1-2 minutos después de configurar
