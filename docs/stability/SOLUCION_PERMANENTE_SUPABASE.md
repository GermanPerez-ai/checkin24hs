# Solución Permanente para @supabase/supabase-js

## Problema
El módulo `@supabase/supabase-js` no persiste cuando el servicio Docker se reinicia porque los `node_modules` no están en un volumen persistente.

## Solución
Modificar el comando de inicio del servicio Docker para que ejecute un script que verifica e instala las dependencias automáticamente antes de iniciar el servidor.

## Pasos para Implementar

### 1. Copiar scripts al servidor
```bash
# En el servidor
cd ~/checkin24hs
# Los scripts ya deberían estar en el repositorio, hacer pull si es necesario
git pull origin main
chmod +x scripts/iniciar-servidor.sh scripts/verificar-supabase.sh
```

### 2. Verificar comando actual del servicio
```bash
docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Command}}'
docker service inspect checkin24hs_dashboard --format '{{.Spec.TaskTemplate.ContainerSpec.Args}}'
```

### 3. Opción A: Modificar el servicio para usar el script de inicio

Si el servicio permite montar el directorio `scripts/`, podemos usar:

```bash
# Agregar mount para scripts
docker service update \
  --mount-add type=bind,source=/root/checkin24hs/scripts/iniciar-servidor.sh,target=/app/iniciar-servidor.sh \
  checkin24hs_dashboard

# Modificar el comando de inicio (reemplazar "node server.js" con "bash iniciar-servidor.sh")
# NOTA: Esto depende de cómo esté configurado el servicio en EasyPanel
```

### 4. Opción B: Modificar directamente el server.js para auto-instalar

Agregar al inicio de `server.js`:

```javascript
// Auto-instalar @supabase/supabase-js si no está disponible
try {
    require('@supabase/supabase-js');
} catch (e) {
    console.log('📦 Instalando @supabase/supabase-js...');
    const { execSync } = require('child_process');
    try {
        execSync('npm install @supabase/supabase-js --silent', { stdio: 'inherit' });
        console.log('✅ @supabase/supabase-js instalado');
    } catch (installError) {
        console.warn('⚠️ No se pudo instalar @supabase/supabase-js automáticamente');
    }
}
```

### 5. Opción C: Usar un volumen para node_modules (NO RECOMENDADO)

Montar `node_modules` como volumen puede causar problemas de compatibilidad entre host y contenedor.

## Recomendación

**Opción B** es la más simple y no requiere cambios en la configuración de Docker. El código se auto-instala si falta el módulo.

## Verificación

Después de implementar, verificar con:

```bash
bash scripts/verificar-supabase.sh servidor
```

O manualmente:
```bash
# Reiniciar el servicio
docker service update --force checkin24hs_dashboard

# Esperar 15 segundos
sleep 15

# Verificar que el módulo está instalado y funcionando
CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)
docker exec $CONTAINER_ID node -e "require('@supabase/supabase-js'); console.log('✅ Módulo disponible')"

# Probar endpoint
curl http://localhost:3000/api/supabase/test
```
