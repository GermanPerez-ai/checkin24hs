# Implementar Dashboard en EasyPanel

## ✅ Cambios Subidos a GitHub

Los siguientes cambios están ahora en GitHub:
- ✅ Dockerfile actualizado (usa `serve-dashboard.js`)
- ✅ `serve-dashboard.js` actualizado
- ✅ `dashboard.html` sin login
- ✅ Merge con cambios remotos completado

## Pasos para Implementar en EasyPanel

### 1. Acceder a EasyPanel

1. Abre tu navegador
2. Ve a: **http://72.61.58.240:3000**
3. Inicia sesión si es necesario

### 2. Ir al Servicio Dashboard

1. En el menú lateral izquierdo, busca el proyecto **"checkin24hs"**
2. Haz clic en el servicio **"dashboard"**

### 3. Verificar Configuración

En la pestaña **"Fuente"** verifica:
- ✅ Propietario: `GermanPerez-ai`
- ✅ Repositorio: `checkin24hs`
- ✅ Rama: `main`
- ✅ Ruta de compilación: `/`
- ✅ Método: `Dockerfile`
- ✅ Archivo: `Dockerfile`

Si todo está correcto, continúa al siguiente paso.

### 4. Implementar el Servicio

1. Haz clic en el botón verde **"Implementar"** (Deploy) en la parte superior
2. EasyPanel comenzará a:
   - Clonar el repositorio desde GitHub
   - Construir la imagen Docker usando el Dockerfile
   - Desplegar el servicio

### 5. Monitorear el Progreso

1. Ve a la pestaña **"Implementaciones"** (Implementations)
2. Verás el progreso del despliegue:
   - Estado: "Building", "Deploying", "Running"
   - Logs en tiempo real
   - Tiempo estimado: 5-10 minutos

### 6. Verificar que Funcione

Una vez que el estado sea **"Running"** (Verde):

1. Ve a la pestaña **"Dominios"** para ver la URL del servicio
2. O accede directamente al puerto configurado
3. El dashboard debería aparecer **sin login**

## Solución de Problemas

### Si el despliegue falla:

1. Ve a **"Implementaciones"**
2. Haz clic en la implementación fallida
3. Revisa los logs para ver el error
4. Errores comunes:
   - Error de compilación Docker: Verifica el Dockerfile
   - Error de dependencias: Verifica `package.json`
   - Error de puerto: Verifica la configuración del servicio

### Si aparece el login:

1. Verifica que `dashboard.html` en GitHub tenga el código sin login
2. Haz un nuevo commit y push
3. Vuelve a implementar desde EasyPanel

### Si el servicio no inicia:

1. Ve a **"Recursos"** y verifica:
   - CPU y memoria asignadas
   - Puerto configurado
2. Ve a **"Logs"** para ver errores del servicio

## Comandos Útiles para Verificar en el Servidor

```bash
# Ver servicios corriendo
docker ps | grep -E "easypanel|dashboard|checkin24hs"

# Ver servicios de Docker Swarm
docker service ls

# Ver logs del servicio dashboard
docker service logs checkin24hs_dashboard --tail 50

# Ver puertos en uso
sudo lsof -i :3000
sudo lsof -i :3001
```

## Checklist Final

- [ ] Cambios subidos a GitHub
- [ ] Acceso a EasyPanel
- [ ] Servicio "dashboard" encontrado
- [ ] Configuración verificada
- [ ] Implementación iniciada
- [ ] Despliegue completado
- [ ] Dashboard accesible sin login


