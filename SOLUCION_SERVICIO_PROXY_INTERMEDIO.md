# 🔧 Solución: Servicio Proxy Intermedio

## 🎯 Problema

Docker Swarm no permite agregar aliases después de crear el servicio. Necesitamos una solución alternativa.

## ✅ Solución: Crear un Servicio Proxy Intermedio

Crearemos un servicio Nginx simple que redirija las peticiones desde `checkin24hs_dashboard` (guión bajo) a `checkin24hs-dashboard` (guión).

### Paso 1: Crear Dockerfile para el Proxy

Crea un archivo `deploy/proxy/Dockerfile`:

```dockerfile
FROM nginx:alpine

# Crear configuración de nginx que redirija
RUN echo 'server { \
    listen 80; \
    location / { \
        proxy_pass http://checkin24hs-dashboard:80; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Paso 2: Crear el Servicio en EasyPanel

1. En EasyPanel, crea un **nuevo servicio** llamado `dashboard-proxy`
2. Configura:
   - Build Path: `/deploy/proxy` (o donde esté el Dockerfile del proxy)
   - Dockerfile: `Dockerfile`
   - Puerto: `80`
   - Variables de entorno: `PORT=80`
3. Agrega el dominio `dashboard.checkin24hs.com` a este nuevo servicio
4. EasyPanel generará: `http://checkin24hs_dashboard-proxy:80/` o similar

**Problema:** Esto también generará un nombre con guión bajo.

---

## ✅ Solución Alternativa: Modificar Nginx para Aceptar Ambos Nombres

Una solución más simple es modificar la configuración de Nginx en el servicio actual para que responda a ambos nombres.

Pero esto no soluciona el problema de resolución DNS del proxy.

---

## ✅ Solución Recomendada: Usar el Alias "dashboard"

La solución más simple es hacer que EasyPanel use el alias `dashboard` directamente.

**Verifica si puedes:**

1. En EasyPanel, elimina el dominio `dashboard.checkin24hs.com`
2. Crea un nuevo servicio llamado exactamente `dashboard` (sin prefijo)
3. Mueve la configuración del servicio actual a este nuevo servicio
4. Agrega el dominio `dashboard.checkin24hs.com` a este nuevo servicio
5. EasyPanel debería generar: `http://dashboard:80/` (que coincide con el alias)

---

## 🔍 Otra Opción: Verificar si Hay una Forma de Configurar el Alias en EasyPanel

1. En EasyPanel, ve a la configuración del servicio `dashboard`
2. Busca opciones de red o configuración avanzada
3. Puede haber una opción para especificar aliases o nombres de red

---

**¿Puedes crear un nuevo servicio llamado `dashboard` (sin prefijo) y mover la configuración allí?**
