# 🔧 Cambiar Puerto Interno del Dashboard a 80

## Problema
El dominio apunta a `http://checkin24hs_dashboard:80/` pero el dashboard escucha en el puerto 3000.

## Solución: Cambiar el puerto interno del servicio a 80

### Opción 1: Cambiar en EasyPanel (Recomendado)

1. Ve a EasyPanel → `dashboard` service
2. Ve a la pestaña "Implementar" o "Configuración"
3. Busca "Puerto interno" o "Internal Port"
4. Cambia de `3000` a `80`
5. Guarda los cambios
6. Reinicia el servicio

### Opción 2: Cambiar variable de entorno PORT

1. Ve a EasyPanel → `dashboard` service
2. Ve a la pestaña "Entorno" o "Environment"
3. Busca la variable `PORT`
4. Cambia de `PORT=3000` a `PORT=80`
5. Guarda los cambios
6. Reinicia el servicio

### Opción 3: Cambiar en server.js

Si el puerto está hardcodeado en `server.js`, necesitamos cambiarlo:

```javascript
const PORT = process.env.PORT || 80; // Cambiar de 3000 a 80
```

Luego hacer commit y push, y redeployar.

---

**Después de cambiar el puerto, espera 30-60 segundos y prueba: `https://dashboard.checkin24hs.com/`**
