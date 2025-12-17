# 🔍 Diagnóstico: Servicio Sigue en Rojo

## 🚨 Problema

El servicio **webmail** sigue en rojo después de implementar, a pesar de tener:
- ✅ Recursos configurados (512/1025 MB, CPU 0.5/1.0)
- ✅ Dominio configurado (puerto 8080)
- ✅ Variables de entorno configuradas

## 🔍 Paso 1: Ver los Logs (CRÍTICO)

**Esto es lo más importante ahora:**

1. En la sección **"Registros"**, haz clic en **"Actualizar registros"**
2. **Copia los últimos 30-50 líneas** de logs
3. Busca específicamente estos errores:
   - `Killed`
   - `Out of memory`
   - `Port already in use`
   - `Cannot bind to port`
   - `Error starting container`
   - `Exit code`

**Los logs te dirán exactamente qué está fallando.**

## 🎯 Posibles Causas

### Causa 1: Conflicto de Puertos

Aunque configuraste el puerto 8080, puede que:
- Otro servicio esté usando el puerto 8080
- El contenedor interno esté intentando usar un puerto diferente
- Haya un conflicto con roundcube

**Solución**: Cambiar el puerto a uno diferente (ej: `8081`, `8082`, `3002`)

### Causa 2: Memoria Insuficiente

Aunque configuraste 1025 MB, puede que:
- El servidor no tenga suficiente memoria disponible
- Otros servicios estén usando mucha memoria
- Necesites más memoria para Roundcube

**Solución**: Aumentar el límite de memoria a `2048` MB (2 GB)

### Causa 3: El Contenedor se Mata Inmediatamente

El contenedor puede estar:
- Iniciando pero matándose por falta de recursos
- Teniendo un error de configuración
- No pudiendo conectarse a los volúmenes

**Solución**: Revisar los logs para el error específico

### Causa 4: Conflicto con Roundcube

Si tienes **roundcube** y **webmail** ambos corriendo:
- Pueden estar compitiendo por recursos
- Pueden tener configuraciones conflictivas
- Uno puede estar bloqueando al otro

**Solución**: Verificar que roundcube y webmail usen puertos diferentes

## 🛠️ Soluciones a Probar

### Solución 1: Cambiar el Puerto

1. Ve a **"Dominios"**
2. Cambia el puerto de `8080` a `8081` o `3002`
3. **Guarda** los cambios
4. Haz clic en **"Implementar"** de nuevo

### Solución 2: Aumentar la Memoria

1. Ve a **"Recursos"**
2. Aumenta el **Límite de memoria** a `2048` MB (2 GB)
3. **Guarda** los cambios
4. Haz clic en **"Implementar"** de nuevo

### Solución 3: Verificar Roundcube

1. Ve a **"roundcube"** en la lista de servicios
2. Verifica qué puerto está usando
3. Asegúrate de que sea diferente al de webmail
4. Si ambos usan el mismo puerto, cambia uno

### Solución 4: Reiniciar Todo

1. Haz clic en el botón de **stop** (cuadrado) en webmail
2. Espera 5 segundos
3. Haz clic en **"Implementar"** de nuevo
4. O haz clic en el botón de **play** (▶️)

## 📋 Información Necesaria

Para ayudarte mejor, necesito saber:

1. **¿Qué dicen los logs?** (últimas 30-50 líneas)
   - Esto es lo más importante
   - Copia y pega los mensajes de error

2. **¿Qué puerto está usando roundcube?**
   - Ve a roundcube → Dominios
   - Verifica el puerto

3. **¿Hay otros servicios usando puertos similares?**
   - Verifica whatsapp, whatsapp2, etc.

## 🆘 Si No Puedes Ver los Logs

1. Haz clic en el icono de **terminal** (`>_`) en webmail
2. Ejecuta:
   ```bash
   docker logs webmail --tail 50
   # O
   docker logs checkin24hs-webmail --tail 50
   ```
3. Copia los mensajes que aparezcan

## 💡 Nota sobre el Puerto 3001

El puerto 3001 que usas para WhatsApp no debería causar conflicto con webmail (puerto 8080), pero verifica que:
- No haya otro servicio usando el puerto 8080
- El puerto 8080 esté disponible

## 🎯 Próximo Paso Inmediato

**LO MÁS IMPORTANTE**: Ve a "Registros", actualiza, y comparte los últimos mensajes. Con esa información podré darte la solución exacta.

