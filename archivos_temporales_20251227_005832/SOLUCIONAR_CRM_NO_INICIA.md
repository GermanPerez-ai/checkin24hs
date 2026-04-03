# Solucionar CRM que No Inicia

## Problema
El servicio `checkin24hs_crm` está intentando iniciar pero falla repetidamente. La imagen Docker existe pero el servicio no puede iniciar.

## Diagnóstico Rápido

Ejecuta estos comandos en el servidor:

```bash
# Ver logs del servicio
docker service logs checkin24hs_crm --tail 50

# Ver estado detallado
docker service ps checkin24hs_crm --no-trunc | head -10

# Ver errores específicos
docker service logs checkin24hs_crm --tail 100 | grep -i "error\|cannot\|failed"
```

## Soluciones Comunes

### Error 1: "Cannot find module '/app/serve-crm.js'"

**Causa**: El archivo `serve-crm.js` no está en la imagen Docker.

**Solución**:
1. Verifica que `Dockerfile.crm` esté en Git
2. Verifica que `serve-crm.js` esté en Git
3. En EasyPanel, verifica que "Archivo Dockerfile" sea `Dockerfile.crm`
4. Haz un nuevo deploy en EasyPanel

### Error 2: "Cannot find module 'express'"

**Causa**: `package.json` no se está instalando correctamente.

**Solución**:
1. Verifica que `package.json` esté en la raíz del repositorio
2. Verifica que tenga `express` en `dependencies`
3. Haz un nuevo deploy

### Error 3: "Cannot find module '/app/crm.html'"

**Causa**: El archivo `crm.html` no está en la imagen.

**Solución**:
1. Verifica que `deploy/crm.html` esté en Git
2. Verifica que el Dockerfile lo copie correctamente
3. Haz un nuevo deploy

### Error 4: El servicio se reinicia constantemente

**Causa**: El contenedor se cae inmediatamente después de iniciar.

**Solución**:
1. Ver los logs completos: `docker service logs checkin24hs_crm --tail 100`
2. Buscar el error específico en los logs
3. Corregir el problema según el error

## Verificar la Imagen Manualmente

Para verificar qué hay dentro de la imagen:

```bash
# Ver archivos en /app
docker run --rm easypanel/checkin24hs/crm:latest ls -lah /app/

# Verificar serve-crm.js
docker run --rm easypanel/checkin24hs/crm:latest ls -lh /app/serve-crm.js

# Intentar ejecutar manualmente
docker run --rm easypanel/checkin24hs/crm:latest node serve-crm.js
```

## Solución Definitiva: Reconstruir la Imagen

Si nada funciona, reconstruye la imagen desde EasyPanel:

1. Ve a EasyPanel → Servicio `crm`
2. Busca la opción "Rebuild" o "Reconstruir"
3. O elimina el servicio y créalo de nuevo
4. Asegúrate de que:
   - "Archivo Dockerfile" sea `Dockerfile.crm`
   - La ruta de compilación sea `/` o `.`
   - El repositorio y la rama sean correctos

## Comandos Útiles

```bash
# Ver logs en tiempo real
docker service logs -f checkin24hs_crm

# Ver estado del servicio
docker service ps checkin24hs_crm --no-trunc

# Eliminar y recrear el servicio (CUIDADO: esto eliminará el servicio)
docker service rm checkin24hs_crm
# Luego créalo de nuevo en EasyPanel
```






