# 🔍 Probar Servicio sin curl

## 🎯 El Contenedor No Tiene curl

El contenedor Node.js no tiene `curl` instalado. Probemos de otras formas.

## ✅ Métodos Alternativos

### Método 1: Probar desde el Servidor usando el Alias

```bash
# Probar usando el alias que SÍ existe (con guión)
curl -I http://checkin24hs-dashboard:3000/

# O usando el alias dashboard
curl -I http://dashboard:3000/
```

### Método 2: Probar desde Dentro del Contenedor con wget

```bash
# Verificar si tiene wget
docker exec 49a5f0b632c8 which wget

# Si tiene wget, probar
docker exec 49a5f0b632c8 wget -O- http://localhost:3000/ | head -20
```

### Método 3: Verificar que el Proceso Esté Corriendo

```bash
# Ver procesos dentro del contenedor
docker exec 49a5f0b632c8 ps aux | grep node

# Ver si está escuchando en el puerto 3000
docker exec 49a5f0b632c8 netstat -tlnp | grep 3000
```

### Método 4: Probar desde Otro Contenedor en la Misma Red

```bash
# Probar desde un contenedor que tenga curl (como traefik)
docker exec $(docker ps | grep traefik | head -1 | awk '{print $1}') curl -I http://checkin24hs-dashboard:3000/
```

---

**Ejecuta primero el Método 1 para probar desde el servidor usando el alias que SÍ existe.**
