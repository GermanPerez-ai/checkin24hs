# Sistema de Cache Busting Automático

Este sistema previene que los navegadores (incluyendo móviles) usen versiones antiguas del dashboard en caché.

## Componentes

### 1. **dashboard.html**
- `BUILD_TIMESTAMP`: Timestamp que se actualiza automáticamente antes de cada deploy
- Verificación automática de versión en el cliente:
  - Compara versión almacenada en `localStorage` con la versión actual
  - Compara `BUILD_TIMESTAMP` almacenado con el actual
  - Verifica periódicamente (cada 30 segundos) la versión del servidor
  - Verifica cuando la ventana recupera el foco (útil para móviles)
  - Fuerza recarga automática si detecta una versión nueva

### 2. **serve-dashboard.js**
- Headers HTTP anti-caché agresivos para HTML y JS
- Endpoint `/api/version` que devuelve:
  - Versión actual del dashboard
  - `BUILD_TIMESTAMP` actual
  - Timestamp de la consulta

### 3. **update-build-timestamp.js**
Script que actualiza automáticamente el `BUILD_TIMESTAMP` en `dashboard.html` antes de cada deploy.

**Uso:**
```bash
npm run update-build
# o
node update-build-timestamp.js
```

### 4. **configurar-traefik-anti-cache-auto.sh**
Script que configura las etiquetas de Traefik para headers anti-caché.

**Características:**
- ✅ **NO requiere reiniciar Traefik**
- Actualiza las labels del servicio Docker
- Traefik detecta los cambios automáticamente en 10-30 segundos

**Uso:**
```bash
bash configurar-traefik-anti-cache-auto.sh
```

**Cómo funciona:**
- Traefik lee las labels de los servicios Docker en tiempo real
- Al actualizar las labels con `docker service update`, Traefik las detecta automáticamente
- No requiere reinicio: Traefik se reconfigura solo

### 5. **post-deploy.sh**
Script opcional que se puede ejecutar después de cada deploy para:
1. Actualizar `BUILD_TIMESTAMP`
2. Configurar Traefik (opcional, descomentar si es necesario)

**Uso:**
```bash
bash post-deploy.sh
```

## Proceso de Deploy

### Opción 1: Manual
```bash
# 1. Actualizar BUILD_TIMESTAMP
npm run update-build

# 2. Hacer commit y push
git add dashboard.html
git commit -m "Update: Actualizar BUILD_TIMESTAMP"
git push

# 3. (Opcional) Configurar Traefik después del deploy
bash configurar-traefik-anti-cache-auto.sh
```

### Opción 2: Automatizado
```bash
# Ejecutar post-deploy después del deploy
bash post-deploy.sh
```

## Verificación

### En el navegador:
1. Abre la consola del navegador (F12)
2. Verifica que aparezca el log: `📊 CHECKIN24HS DASHBOARD`
3. Verifica la versión: `window.DASHBOARD_VERSION`
4. Verifica el build timestamp: `window.BUILD_TIMESTAMP`

### Verificar headers HTTP:
```bash
curl -I https://dashboard.checkin24hs.com/
```

Deberías ver:
- `Cache-Control: no-cache, no-store, must-revalidate`
- `Pragma: no-cache`
- `Expires: 0`

### Verificar endpoint de versión:
```bash
curl https://dashboard.checkin24hs.com/api/version
```

Deberías recibir un JSON con:
```json
{
  "version": "2.1.0",
  "buildTimestamp": "2026-01-12T00:00:00Z",
  "timestamp": "2026-01-12T12:00:00.000Z"
}
```

## Troubleshooting

### El navegador sigue mostrando versión antigua:
1. Verifica que `BUILD_TIMESTAMP` se actualizó: `grep BUILD_TIMESTAMP dashboard.html`
2. Limpia el caché del navegador: `Ctrl+Shift+R` (Windows/Linux) o `Cmd+Shift+R` (Mac)
3. Verifica los headers HTTP con `curl -I`
4. Verifica que Traefik está configurado: `docker service inspect checkin24hs_dashboard | grep -i cache`

### Traefik no detecta los cambios:
1. Espera 30 segundos (Traefik puede tardar en detectar cambios)
2. Verifica que el servicio existe: `docker service ls | grep dashboard`
3. Verifica las labels: `docker service inspect checkin24hs_dashboard | grep -A 10 middlewares`

## Notas Importantes

- El `BUILD_TIMESTAMP` debe actualizarse **antes** de cada deploy
- Traefik detecta cambios automáticamente, **no requiere reinicio**
- Los headers anti-caché se aplican tanto en el servidor (Express) como en Traefik
- El sistema verifica la versión automáticamente cada 30 segundos y al recuperar el foco
