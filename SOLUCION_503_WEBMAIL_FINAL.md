# 🔧 Solución Final: Error 503 en Webmail

## 🎯 Problema Identificado

El error **503 (Service Unavailable)** significa que:
- ✅ **Nginx está funcionando** (por eso responde)
- ✅ **El dominio está configurado** (webmail.checkin24hs.com)
- ❌ **El contenedor de Roundcube NO está corriendo** (por eso el 503)

## 🔍 Diagnóstico

El servicio **webmail** está en **rojo** en EasyPanel, lo que confirma que el contenedor está detenido.

## ✅ Solución Paso a Paso

### Paso 1: Verificar y Configurar Recursos

1. En EasyPanel, ve a **"Recursos"** (menú lateral)
2. Verifica estos valores:
   - **Reserva de memoria**: `512` MB (NO 0)
   - **Límite de memoria**: `1024` MB (NO 0)
   - **Reserva de CPU**: `0.5` (NO 0)
   - **Límite de CPU**: `1.0` (NO 0)
3. Si están en 0, **cámbialos** a los valores indicados
4. **Guarda** los cambios

### Paso 2: Verificar Configuración del Dominio

1. Ve a **"Dominios"** (menú lateral)
2. Verifica que:
   - **Host**: `webmail.checkin24hs.com`
   - **Puerto**: `8080` (NO 80)
   - **Protocolo**: `HTTP`
3. Si el puerto es 80, **cámbialo a 8080**
4. **Guarda** los cambios

### Paso 3: Ver los Logs para Identificar el Problema

1. En la sección **"Registros"**, haz clic en **"Actualizar registros"**
2. Revisa los últimos mensajes
3. Busca errores específicos:
   - `Killed` → Problema de memoria
   - `Port already in use` → Conflicto de puertos
   - `Cannot bind` → Puerto en uso
   - `Out of memory` → Falta de memoria

### Paso 4: Intentar Iniciar el Servicio

**Opción A: Usar el Botón Implementar**
1. Haz clic en el botón verde **"Implementar"**
2. Espera 1-2 minutos
3. Observa los logs para ver el progreso

**Opción B: Usar el Botón Play**
1. Haz clic en el botón de **play** (▶️)
2. Espera 10-15 segundos
3. Actualiza los logs
4. Verifica si el punto cambia de rojo a verde

### Paso 5: Verificar el Estado

Después de intentar iniciar:
1. **Observa el punto** junto a "webmail" en la lista
   - ✅ **Verde** = Funcionando
   - ❌ **Rojo** = Detenido/Error
2. **Observa los recursos**:
   - Si muestran valores > 0, el servicio está corriendo
   - Si siguen en 0, el servicio no está corriendo
3. **Intenta acceder** a `https://webmail.checkin24hs.com`
   - Si funciona, verás la página de login de Roundcube
   - Si sigue 503, el servicio aún no está corriendo

## 🛠️ Soluciones Específicas por Error

### Si el Log Muestra "Killed"

**Causa**: Falta de memoria

**Solución**:
1. Ve a **"Recursos"**
2. Aumenta la memoria:
   - **Límite de memoria**: `2048` MB (2 GB)
3. **Guarda** y **Implementa** de nuevo

### Si el Log Muestra "Port already in use"

**Causa**: Conflicto de puertos

**Solución**:
1. Ve a **"Dominios"**
2. Cambia el puerto a `8081` o `8082`
3. **Guarda** y **Implementa** de nuevo

### Si el Log Muestra "Cannot bind to port"

**Causa**: El puerto está siendo usado por otro servicio

**Solución**:
1. Verifica qué servicio está usando el puerto
2. Cambia el puerto de webmail a uno diferente
3. **Guarda** y **Implementa** de nuevo

## 📋 Checklist Completo

Antes de implementar, verifica:

- [ ] **Recursos**: Memoria 512/1024 MB, CPU 0.5/1.0 (NO 0)
- [ ] **Dominio**: Puerto 8080 (NO 80)
- [ ] **Variables de entorno**: Todas configuradas
- [ ] **Logs revisados**: Error identificado

## 🚀 Orden de Acción

1. ✅ **Configura Recursos** (si están en 0)
2. ✅ **Configura Dominio** (puerto 8080)
3. ✅ **Haz clic en "Implementar"**
4. ✅ **Espera 1-2 minutos**
5. ✅ **Observa los logs**
6. ✅ **Verifica el punto** (debe cambiar a verde)
7. ✅ **Intenta acceder** a webmail.checkin24hs.com

## 🆘 Si Sigue en Rojo Después de Implementar

1. **Ve a "Registros"** y copia los últimos 50-100 líneas
2. **Busca específicamente**:
   - "Killed"
   - "Out of memory"
   - "Port"
   - "Error"
3. **Comparte los logs** para identificar el problema exacto

## 💡 Nota Importante

El error 503 en el navegador confirma que:
- ✅ La configuración de Nginx está correcta
- ✅ El dominio está funcionando
- ❌ Solo falta que el contenedor de Roundcube esté corriendo

Una vez que el servicio esté en **verde** en EasyPanel, el error 503 desaparecerá.

