# Solución Error Línea 5150

## Problema
El archivo `dashboard.html` no se copió correctamente a los contenedores mientras estaban corriendo, causando el error:
```
Uncaught SyntaxError: Invalid or unexpected token (at (index):5150:9)
```

## Solución Correcta

**IMPORTANTE:** Debes DETENER los contenedores ANTES de copiar el archivo, luego reiniciarlos.

### Opción 1: Ejecutar Script Automático

1. **Sube el script al servidor:**
   ```powershell
   scp APLICAR_DASHBOARD_CORRECTO.sh root@72.61.58.240:/root/checkin24hs/
   ```

2. **Conecta al servidor:**
   ```powershell
   ssh root@72.61.58.240
   ```

3. **Ejecuta el script:**
   ```bash
   cd /root/checkin24hs
   chmod +x APLICAR_DASHBOARD_CORRECTO.sh
   bash APLICAR_DASHBOARD_CORRECTO.sh
   ```

### Opción 2: Comandos Manuales

1. **Conecta al servidor:**
   ```powershell
   ssh root@72.61.58.240
   ```

2. **Ejecuta estos comandos en orden:**
   ```bash
   cd /root/checkin24hs
   
   # 1. Detener TODOS los contenedores de dashboard
   docker stop $(docker ps -q --filter "name=checkin24hs_dashboard")
   
   # 2. Copiar archivo a cada contenedor (intenta ambas rutas)
   for container in $(docker ps -a --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
       docker cp deploy/dashboard.html $container:/app/dashboard.html 2>/dev/null || \
       docker cp deploy/dashboard.html $container:/usr/share/nginx/html/dashboard.html 2>/dev/null
       echo "✅ Copiado a: $container"
   done
   
   # 3. Reiniciar contenedores
   docker start $(docker ps -aq --filter "name=checkin24hs_dashboard")
   
   # 4. Verificar estado
   docker ps --format "table {{.Names}}\t{{.Status}}" | grep "checkin24hs_dashboard"
   ```

### Opción 3: Todo desde PowerShell (una línea)

```powershell
ssh root@72.61.58.240 "cd /root/checkin24hs && docker stop `$(docker ps -q --filter 'name=checkin24hs_dashboard') && for c in `$(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard); do docker cp deploy/dashboard.html `$c:/app/dashboard.html 2>/dev/null || docker cp deploy/dashboard.html `$c:/usr/share/nginx/html/dashboard.html 2>/dev/null; done && docker start `$(docker ps -aq --filter 'name=checkin24hs_dashboard')"
```

## Verificación

Después de aplicar los cambios:

1. **Cierra completamente el navegador** (o presiona `Ctrl+F5` para hard refresh)
2. **Abre:** https://dashboard.checkin24hs.com/
3. **Verifica que no haya errores en la consola** (F12 → Console)

## Notas Importantes

- ✅ **SIEMPRE detener contenedores antes de copiar**
- ✅ El archivo debe estar en `/root/checkin24hs/deploy/dashboard.html` en el servidor
- ✅ Los contenedores pueden tener el archivo en `/app/dashboard.html` o `/usr/share/nginx/html/dashboard.html`
- ✅ Después de reiniciar, espera 10-15 segundos antes de probar










