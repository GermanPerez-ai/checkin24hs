# 🔧 Solución: Puerto Ingress - Uso Interno vs Externo

## 🚨 Problema

El puerto 30000 (publicado en modo ingress) no es accesible desde la red interna de Docker Swarm. Esto es normal porque:

- **Modo ingress**: El puerto publicado (30000) es para acceso **externo** (desde fuera del cluster)
- **Acceso interno**: Desde dentro de la red Docker Swarm, debemos usar el **puerto interno** (3000)

## ✅ Solución: Usar el Puerto Interno 3000

Desde dentro de la red Docker Swarm (como Traefik), debemos usar el puerto **3000** (interno), no el 30000 (externo).

### Pruebas:

```bash
# 1. Probar desde Traefik usando el puerto INTERNO 3000
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -20

# 2. Probar desde otro contenedor en la misma red
docker run --rm --network easypanel alpine wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -20

# 3. Verificar desde dentro del contenedor del servicio
docker exec $(docker ps | grep checkin24hs_dashboard | awk '{print $1}') wget -O- http://localhost:3000 2>&1 | head -20

# 4. Verificar el puerto publicado (para acceso externo)
curl http://localhost:30000 | head -20
```

## 🔧 Configuración en EasyPanel

En EasyPanel, para la configuración del dominio:

1. **Ve a EasyPanel** → **Servicios** → **dashboard** → **Dominios**
2. **Edita el dominio** del dashboard
3. **Puerto**: Usa `3000` (puerto interno del contenedor)
   - **NO** uses 30000 (ese es el puerto externo publicado)
4. **Target Service**: `checkin24hs-dashboard` (con guión)
5. **Guarda** los cambios

## 📋 Explicación

- **Puerto 30000 (externo)**: Para acceso desde fuera del cluster (ej: `http://tu-servidor:30000`)
- **Puerto 3000 (interno)**: Para acceso desde dentro de la red Docker Swarm (ej: desde Traefik)
- **Configuración del dominio**: Debe usar el puerto **interno** (3000), no el externo (30000)

## 🎯 Resumen

- ✅ El servicio está corriendo
- ✅ Escucha en el puerto 3000 internamente
- ✅ El puerto 30000 es para acceso externo
- ✅ Traefik debe usar el puerto 3000 (interno)
- ✅ La configuración del dominio en EasyPanel debe usar el puerto 3000

