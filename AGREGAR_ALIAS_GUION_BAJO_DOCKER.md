# 🔧 Solución: Agregar Alias con Guión Bajo al Servicio Docker

## 🎯 Problema

- EasyPanel genera: `http://checkin24hs_dashboard:80/` (con **guión bajo**)
- Alias real: `checkin24hs-dashboard` (con **guión**)
- **No coinciden** → 404

## ✅ Solución: Agregar Alias con Guión Bajo

Necesitamos agregar el alias `checkin24hs_dashboard` (con guión bajo) al servicio Docker para que coincida con lo que EasyPanel genera.

### Opción 1: Modificar el Servicio Docker Directamente (Recomendado)

En el servidor, ejecuta:

```bash
# Obtener la configuración actual del servicio
docker service inspect checkin24hs_dashboard > service_config.json

# Actualizar el servicio para agregar el alias
docker service update \
  --network-add alias=checkin24hs_dashboard \
  checkin24hs_dashboard
```

**Nota:** Esto puede requerir que el servicio se reinicie.

### Opción 2: Verificar si EasyPanel Puede Agregar el Alias

1. En EasyPanel, ve a la pestaña **"Entorno"** del servicio `dashboard`
2. Busca si hay alguna variable de entorno relacionada con redes o aliases
3. O busca en la configuración del servicio opciones de red

### Opción 3: Crear un Servicio Proxy Intermedio

Si no podemos modificar el alias directamente, podemos crear un servicio proxy que redirija:

1. Crea un nuevo servicio en EasyPanel llamado `dashboard-proxy`
2. Configúralo para que apunte a `http://checkin24hs-dashboard:80/`
3. Configura el dominio `dashboard.checkin24hs.com` para que apunte a `dashboard-proxy`
4. EasyPanel generará `http://checkin24hs_dashboard-proxy:80/` o similar

**No es ideal** pero podría funcionar como solución temporal.

---

## 🔍 Verificar Después de Agregar el Alias

Después de agregar el alias, verifica:

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Deberías ver `checkin24hs_dashboard` (con guión bajo) en la lista de aliases.

---

**Ejecuta el comando para agregar el alias y comparte el resultado.**
