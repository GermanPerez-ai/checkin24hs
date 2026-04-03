# 🔍 Cómo Ver los Logs en EasyPanel

## 🎯 Objetivo

Necesitamos ver los logs del servicio webmail para identificar por qué el contenedor se está matando o no inicia.

## 📋 Pasos para Ver los Logs

### Método 1: Desde la Sección "Registros"

1. En la pantalla de **webmail**, desplázate hacia abajo
2. Busca la sección **"Registros"** (Logs)
3. Verás un área negra grande
4. **Haz clic en el icono de refresh** (flecha circular) arriba de esa sección
5. O haz clic en **"Actualizar registros"** si hay un botón
6. **Espera unos segundos** para que se carguen los logs
7. **Copia los últimos 30-50 líneas** que aparezcan

### Método 2: Desde el Icono de Terminal

1. En la barra de botones de webmail, busca el icono de **terminal** (`>_`)
2. Haz clic en él
3. Se abrirá una terminal
4. Ejecuta este comando:
   ```bash
   docker logs webmail --tail 50
   ```
5. O si el contenedor tiene otro nombre:
   ```bash
   docker logs checkin24hs-webmail --tail 50
   ```
6. **Copia los mensajes** que aparezcan

### Método 3: Desde "Implementaciones"

1. En el menú lateral, haz clic en **"Implementaciones"**
2. Busca la implementación más reciente de webmail
3. Haz clic en ella
4. Verás los logs de esa implementación
5. **Copia los mensajes de error**

## 🔍 Qué Buscar en los Logs

Busca específicamente estos mensajes:

- ❌ `Killed` → El contenedor fue matado por falta de recursos
- ❌ `Out of memory` → Falta de memoria
- ❌ `Port already in use` → Conflicto de puertos
- ❌ `Cannot bind to port` → Puerto en uso
- ❌ `Error starting container` → Error al iniciar
- ❌ `Exit code 1` o `Exit code 137` → Error al ejecutar
- ❌ `Permission denied` → Problema de permisos
- ❌ `No such file or directory` → Archivo faltante

## 📝 Qué Hacer con los Logs

Una vez que tengas los logs:

1. **Copia las últimas 30-50 líneas**
2. **Busca los mensajes de error** (los que empiezan con "Error", "Killed", etc.)
3. **Compártelos** para que pueda identificar el problema exacto

## 🆘 Si los Logs Están Vacíos

Si no ves ningún log o están vacíos:

1. **Haz clic en "Implementar"** de nuevo
2. **Inmediatamente después**, ve a "Registros"
3. **Actualiza los logs** mientras se está desplegando
4. Deberías ver mensajes en tiempo real

## 💡 Alternativa Rápida

Si no puedes ver los logs fácilmente:

1. **Cambia el puerto** de webmail a `8081` o `3002`
2. **Aumenta la memoria** a `2048` MB
3. **Haz clic en "Implementar"** de nuevo
4. **Observa si el punto cambia a verde**

Pero lo ideal es ver los logs para identificar el problema exacto.

