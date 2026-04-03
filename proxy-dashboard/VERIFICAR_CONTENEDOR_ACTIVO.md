# 🔍 Verificar Contenedor Activo del Proxy

## 📊 Problema

- ⚠️ Múltiples contenedores del proxy se han detenido
- ⚠️ Servicio muestra estado "Shutdown"

## 🔍 Verificación

### Paso 1: Verificar contenedores activos

```bash
# Ver contenedores activos del proxy
docker ps | grep dashboard-proxy

# Ver todos los contenedores (incluyendo detenidos)
docker ps -a | grep dashboard-proxy
```

### Paso 2: Verificar estado del servicio

```bash
# Ver estado del servicio
docker service ps checkin24hs_dashboard-proxy

# Ver detalles del servicio
docker service inspect checkin24hs_dashboard-proxy --pretty | head -30
```

### Paso 3: Si no hay contenedor activo, forzar actualización

```bash
# Forzar actualización del servicio
docker service update --force checkin24hs_dashboard-proxy

# Esperar 30 segundos
sleep 30

# Verificar que haya un contenedor activo
docker ps | grep dashboard-proxy
```

### Paso 4: Verificar configuración en EasyPanel

En EasyPanel, verifica que:
1. El servicio esté en estado "Verde" o que tenga botón "Implementar"
2. Si está amarillo/rojo, haz clic en "Implementar" para desplegarlo

---

**Ejecuta primero el Paso 1 para ver si hay un contenedor activo. Si no hay ninguno, ejecuta el Paso 3.**
