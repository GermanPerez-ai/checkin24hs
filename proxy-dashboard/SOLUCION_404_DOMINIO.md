# 🔧 Solución para 404 del Dominio Público

## Problema
El proxy funciona localmente pero el dominio público devuelve 404.

## Solución: Usar nombre completo del contenedor del proxy

EasyPanel probablemente no puede resolver el alias `checkin24hs_dashboard-proxy`. Necesitamos usar el nombre completo del contenedor del proxy en la configuración del dominio.

### Paso 1: Obtener nombre completo del contenedor del proxy

```bash
# Obtener el nombre completo del contenedor del proxy
PROXY_FULL_NAME=$(docker ps --filter "name=checkin24hs_dashboard-proxy" --format "{{.Names}}" | head -1)
echo "Nombre completo del proxy: $PROXY_FULL_NAME"
```

### Paso 2: Actualizar configuración del dominio en EasyPanel

1. Ve a EasyPanel → `dashboard-proxy` service
2. Pestaña "Dominios"
3. Edita `dashboard.checkin24hs.com`
4. En "Destino interno", cambia de:
   - `http://checkin24hs_dashboard-proxy:80/`
   
   A:
   - `http://[NOMBRE_COMPLETO_DEL_PROXY]:80/`
   
   Donde `[NOMBRE_COMPLETO_DEL_PROXY]` es el nombre que obtuviste en el Paso 1 (ejemplo: `checkin24hs_dashboard-proxy.1.f8irkh3xe68be9uvdvqjg560h`)

5. Guarda los cambios

### Paso 3: Esperar y probar

1. Espera 30-60 segundos
2. Prueba: `https://dashboard.checkin24hs.com/`

---

**⚠️ NOTA**: El nombre completo del contenedor cambia cuando se recrea. Si esto sucede, necesitarás actualizar la configuración del dominio nuevamente, o podemos crear un script que actualice automáticamente la configuración del dominio cuando el contenedor cambie.
