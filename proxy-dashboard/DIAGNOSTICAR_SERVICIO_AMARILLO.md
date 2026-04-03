# 🔍 Diagnosticar Servicio Dashboard-Proxy Amarillo

## 📊 Problema

- ⚠️ Servicio `dashboard-proxy` tiene punto amarillo (no está funcionando correctamente)

## 🔍 Diagnóstico

### Paso 1: Ver logs del servicio

En EasyPanel:
1. Haz clic en el servicio `dashboard-proxy`
2. Ve a la pestaña "Logs" o "Registros"
3. Revisa los últimos mensajes de error

O desde el servidor (SSH):

```bash
# Ver logs del servicio
docker service logs dashboard-proxy --tail 50

# Ver estado del servicio
docker service ps dashboard-proxy --no-trunc
```

### Paso 2: Verificar contenedores

```bash
# Ver contenedores del proxy
docker ps | grep dashboard-proxy

# Ver contenedores detenidos
docker ps -a | grep dashboard-proxy
```

### Paso 3: Verificar configuración en EasyPanel

1. Ve a la pestaña "Implementar" o "Deploy"
2. Verifica:
   - **Build Path**: `/proxy-dashboard`
   - **Dockerfile**: `Dockerfile`
   - **Puerto interno**: `80`
   - **Comando**: (debe estar vacío o no tener `node server.js`)

### Paso 4: Problemas Comunes

#### Error: "Cannot find Dockerfile"
- **Solución**: Verifica que el Build Path sea `/proxy-dashboard` y el Dockerfile sea `Dockerfile`

#### Error: "nginx: not found" o similar
- **Solución**: El Dockerfile debería usar `FROM nginx:alpine` y no tener comandos de Node.js

#### Error: "Port 80 already in use"
- **Solución**: Verifica que no haya otro servicio usando el puerto 80

#### Error: "Build failed"
- **Solución**: Verifica que los archivos estén en GitHub en la rama `main`

---

**Ejecuta primero el Paso 1 para ver qué error específico está ocurriendo.**
