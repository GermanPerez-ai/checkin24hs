# Instrucciones para Aplicar Dashboard Correctamente

## Problema
Los contenedores siguen corriendo y el archivo no se actualiza correctamente.

## Solución: Detener → Copiar → Reiniciar

### Paso 1: Conecta al servidor
```powershell
ssh root@72.61.58.240
```

### Paso 2: Ejecuta estos comandos EN ORDEN

```bash
cd /root/checkin24hs

# 1. DETENER todos los contenedores
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard")

# Espera 3 segundos para que se detengan completamente
sleep 3

# 2. Verificar que están detenidos
docker ps | grep checkin24hs_dashboard
# Debe mostrar: (nada, ningún contenedor corriendo)

# 3. COPIAR archivo a cada contenedor
for c in $(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard); do
    echo "Copiando a: $c"
    docker cp deploy/dashboard.html $c:/app/dashboard.html 2>/dev/null || \
    docker cp deploy/dashboard.html $c:/usr/share/nginx/html/dashboard.html 2>/dev/null
    echo "✅ $c"
done

# 4. REINICIAR contenedores
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard")

# Espera 3 segundos
sleep 3

# 5. Verificar estado
docker ps | grep checkin24hs_dashboard
```

### O ejecuta el script automático:

```bash
cd /root/checkin24hs
bash APLICAR_DASHBOARD_FINAL.sh
```

## Verificación

Después de ejecutar los comandos:

1. **Espera 10 segundos** para que los contenedores se inicien completamente
2. **Cierra completamente el navegador** (o presiona `Ctrl+F5`)
3. **Abre:** https://dashboard.checkin24hs.com/
4. **Verifica:**
   - No debe haber errores en la consola (F12 → Console)
   - El modal de administradores debe aparecer al hacer clic en "Nuevo Administrador"
   - El botón naranja de WhatsApp debe estar en Flor IA → WhatsApp

## Notas Importantes

- ✅ **SIEMPRE detener contenedores ANTES de copiar**
- ✅ El archivo debe estar en `/root/checkin24hs/deploy/dashboard.html`
- ✅ Los contenedores pueden tener el archivo en `/app/dashboard.html` o `/usr/share/nginx/html/dashboard.html`
- ✅ Si algún contenedor no se detiene, usa: `docker kill <nombre_contenedor>`










