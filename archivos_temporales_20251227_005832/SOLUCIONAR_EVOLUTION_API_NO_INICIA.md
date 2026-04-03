# 🔧 Solucionar: Evolution API No Inicia

## 🔍 Paso 1: Verificar Estado de Contenedores

```bash
# Ver todos los contenedores (incluyendo detenidos)
docker ps -a | grep evolution

# Ver si hay algún contenedor corriendo
docker ps
```

## 🚀 Paso 2: Iniciar Evolution API

```bash
cd ~/evolution-api

# Iniciar Evolution API
docker-compose up -d

# Ver logs para verificar que inicia correctamente
docker-compose logs -f evolution-api
```

Espera unos segundos y deberías ver mensajes como:
- "Evolution API started"
- "Server listening on port 8080"

## 🔍 Paso 3: Verificar que Está Corriendo

```bash
# Ver contenedores corriendo
docker ps | grep evolution

# Verificar que responde
curl http://localhost:8080

# Ver puertos abiertos
netstat -tulpn | grep 8080
```

## ⚠️ Si Hay Errores

### Error: Puerto 8080 ya en uso

```bash
# Ver qué está usando el puerto 8080
lsof -i :8080
# O
netstat -tulpn | grep 8080

# Si necesitas cambiar el puerto, edita docker-compose.yml
# Cambia "8080:8080" por otro puerto, ej: "8081:8080"
```

### Error: No se puede conectar a Redis

```bash
# Verificar que Redis está corriendo
docker ps | grep redis

# Si no está corriendo, iniciar todo de nuevo
docker-compose up -d
```

### Error: Imagen no encontrada

```bash
# Forzar descarga de la imagen
docker-compose pull

# Luego iniciar
docker-compose up -d
```

## 📋 Comandos Útiles

```bash
# Ver logs en tiempo real
docker-compose logs -f evolution-api

# Ver últimos 50 líneas de logs
docker-compose logs --tail=50 evolution-api

# Reiniciar Evolution API
docker-compose restart evolution-api

# Detener Evolution API
docker-compose down

# Detener y eliminar volúmenes (CUIDADO: borra datos)
docker-compose down -v
```

## ✅ Verificación Final

Una vez que Evolution API esté corriendo, deberías ver:

```bash
# Contenedores corriendo
docker ps
# Deberías ver: evolution-api-checkin24hs y evolution-redis

# Respuesta HTTP
curl http://localhost:8080
# Debería responder con HTML o JSON

# Logs sin errores
docker-compose logs evolution-api | tail -20
# No debería haber errores críticos
```


