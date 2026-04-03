# Solución a Problemas del Dashboard

## Problemas Identificados

### 1. ❌ CSS de `.table-container` no está en el contenedor
**Síntoma**: Las tablas de Gastos y Cotizaciones no se ven aunque los datos se cargan.

**Causa**: El código local tiene el CSS correcto, pero la imagen de Docker no se ha reconstruido desde EasyPanel.

**Solución**: Reconstruir la imagen desde EasyPanel.

### 2. ℹ️ Modal de Administradores no aparece
**Síntoma**: El menú "Administradores" no se ve en el sidebar.

**Causa**: El menú de Administradores está oculto por defecto y solo se muestra si el usuario tiene rol "Administrador Total". Esto es un comportamiento de seguridad correcto.

**Solución**: Si necesitas ver el menú, debes iniciar sesión como "Administrador Total".

### 3. ❌ Tablas no se muestran visualmente
**Síntoma**: Los datos se cargan (39 gastos, 0 cotizaciones) pero las tablas no son visibles.

**Causa**: El CSS de `.table-container` no está aplicado en el contenedor.

**Solución**: Reconstruir la imagen desde EasyPanel.

---

## Pasos para Solucionar

### Paso 1: Reconstruir la Imagen desde EasyPanel

1. Ve a **EasyPanel** → **Servicios** → **`dashboard`**
2. Haz clic en el botón **"Implementar"** (botón verde)
3. Espera a que termine el build (puede tardar varios minutos)
4. Verifica que el servicio esté en estado **verde** ✅

### Paso 2: Restaurar Etiquetas de Traefik

Después de implementar, ejecuta este comando en el servidor:

```bash
docker service update \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)" \
  --label-add "traefik.http.routers.dashboard.entrypoints=websecure" \
  --label-add "traefik.http.routers.dashboard.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.routers.dashboard.service=dashboard" \
  --label-add "traefik.http.services.dashboard.loadbalancer.server.port=3000" \
  --label-add "traefik.docker.network=easypanel" \
  checkin24hs_dashboard
```

Espera 20-30 segundos y prueba el dominio.

### Paso 3: Verificar que el CSS está Aplicado

Después de implementar, verifica:

```bash
DASHBOARD_ID=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.ID}}" | head -1)
docker exec $DASHBOARD_ID grep -A 5 "\.table-container" /app/dashboard.html | head -10
```

Deberías ver:
```css
.table-container {
    width: 100%;
    min-width: 100%;
    overflow-x: auto;
    margin-top: 24px;
}
```

### Paso 4: Verificar Funcionamiento

1. Abre `https://dashboard.checkin24hs.com/`
2. Inicia sesión
3. Ve a la sección **"Gastos"** → Deberías ver la tabla con 39 gastos
4. Ve a la sección **"Cotizaciones"** → Deberías ver la tabla (aunque esté vacía)

---

## Sobre el Modal de Administradores

El menú "Administradores" solo aparece si:
- El usuario tiene rol **"Administrador Total"**
- La función `updateAdminMenuVisibility()` detecta que `isAdminTotal()` retorna `true`

Si necesitas ver el menú:
1. Inicia sesión como un usuario con rol "Administrador Total"
2. O modifica temporalmente el código para forzar la visibilidad (solo para pruebas)

---

## Nota Importante

**Cada vez que implementes cambios desde EasyPanel**, las etiquetas de Traefik se eliminan. Debes restaurarlas manualmente usando el comando del Paso 2, o usar el script `RESTAURAR_TRAEFIK_AUTOMATICO.sh` que creamos anteriormente.

---

## Resumen de Cambios en el Código

El código local ya tiene:
- ✅ CSS de `.table-container` (líneas 327-332)
- ✅ Lógica para cargar `loadQuotesTable()` cuando se muestra la sección "quotes" (líneas 5115-5124)
- ✅ Lógica para cargar `loadExpensesData()` cuando se muestra la sección "expenses" (líneas 5107-5113)
- ✅ Modal de Administradores correctamente definido (líneas 19609-19661)
- ✅ Función `updateAdminMenuVisibility()` para mostrar/ocultar el menú según el rol (líneas 19569-19578)

**Todo está correcto en el código local. Solo falta reconstruir la imagen desde EasyPanel.**
