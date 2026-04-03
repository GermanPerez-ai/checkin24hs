# 🔍 Verificar que el Alias Funciona desde la Red Docker

## 🎯 Verificación

Aunque agregamos el alias, necesitamos verificar que funciona desde dentro de la red Docker.

## ✅ Comandos para Ejecutar

### Paso 1: Probar el Alias desde Dentro de la Red

```bash
# Probar usando curl desde un contenedor temporal en la misma red
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://checkin24hs_dashboard:3000/
```

Si esto funciona (devuelve 200), el alias está correcto y el problema puede ser Traefik.

### Paso 2: Verificar la Configuración del Dominio en EasyPanel

1. En EasyPanel, ve a la pestaña **"Dominios"**
2. Verifica el dominio `dashboard.checkin24hs.com`:
   - ¿El destino es `http://checkin24hs_dashboard:3000/`?
   - ¿El puerto es 3000 (no 80)?

### Paso 3: Reiniciar Traefik (Si es Necesario)

A veces Traefik necesita recargar su configuración:

```bash
# Reiniciar Traefik
docker service update --force traefik
```

O si Traefik no es un servicio:

```bash
docker restart $(docker ps | grep traefik | head -1 | awk '{print $1}')
```

### Paso 4: Verificar Logs de Traefik

```bash
# Ver logs de Traefik para ver si hay errores
docker logs $(docker ps | grep traefik | head -1 | awk '{print $1}') --tail 50
```

---

**Ejecuta primero el Paso 1 para verificar que el alias funciona desde dentro de la red Docker.**
