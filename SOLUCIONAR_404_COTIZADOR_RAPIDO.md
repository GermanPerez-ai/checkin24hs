# 🔧 Solución Rápida: Error 404 del Cotizador

## 🎯 Problema
El cotizador da error **404** en `https://cotizar.checkin24hs.com/`

## ✅ Solución Rápida (2 minutos)

### Opción 1: Ejecutar Script Automático (Recomendado)

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

### Opción 2: Comando Manual (Si el script no funciona)

```bash
# En el servidor
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.cotizador.rule=Host(\`cotizar.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.cotizador.entrypoints=websecure" \
  --label-add "traefik.http.routers.cotizador.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.cotizador.tls=true" \
  --label-add "traefik.http.routers.cotizador.service=cotizador-service" \
  --label-add "traefik.http.services.cotizador-service.loadbalancer.server.port=80" \
  --label-add "traefik.docker.network=easypanel" \
  checkin24hs_cotizador
```

Luego espera 1-2 minutos y prueba: `https://cotizar.checkin24hs.com/`

---

## 🔍 Verificación

### Verificar que las etiquetas se aplicaron:
```bash
docker service inspect checkin24hs_cotizador --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik
```

Debe mostrar todas las etiquetas `traefik.*`

### Verificar que el servicio está corriendo:
```bash
docker service ps checkin24hs_cotizador
```

Debe mostrar estado "Running"

---

## ⚠️ Si Sigue Dando 404

1. **Verificar DNS:**
   ```bash
   nslookup cotizar.checkin24hs.com
   ```
   Debe devolver: `72.61.58.240`

2. **Verificar que está en la red easypanel:**
   ```bash
   docker service inspect checkin24hs_cotizador --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{println}}{{end}}'
   ```
   Debe incluir: `easypanel`

3. **Reiniciar Traefik (último recurso):**
   ```bash
   docker service update --force traefik
   ```
   Espera 2 minutos y prueba de nuevo

---

## 📝 Explicación

El problema es que **Traefik no tiene las etiquetas (labels) configuradas** para enrutar el dominio `cotizar.checkin24hs.com` al servicio del cotizador. Cuando reconstruyes un servicio en EasyPanel, las etiquetas de Traefik pueden perderse si no están configuradas en la interfaz.

Las etiquetas le dicen a Traefik:
- ✅ Habilitar Traefik para este servicio
- ✅ Enrutar `cotizar.checkin24hs.com` a este servicio
- ✅ Usar HTTPS con certificado Let's Encrypt
- ✅ El servicio escucha en el puerto 80
- ✅ Usar la red `easypanel`
