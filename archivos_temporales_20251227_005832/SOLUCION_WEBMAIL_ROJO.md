# 🔴 Solución: Webmail en Rojo (Detenido)

## 🚨 Estado Actual

El servicio **webmail** está:
- ❌ **Punto rojo** (detenido/error)
- 📊 **Recursos en 0%** (no está corriendo)
- 🔴 **Servicio no activo**

## 🔍 Paso 1: Ver los Logs (MUY IMPORTANTE)

1. En la sección **"Registros"** (abajo de la pantalla)
2. Haz clic en el icono de **refresh** (flecha circular) o en **"Actualizar registros"**
3. **Revisa los últimos mensajes** en el área negra
4. Busca errores específicos como:
   - `Killed`
   - `Out of memory`
   - `Port already in use`
   - `Cannot bind to port`
   - `Error starting container`

**Copia los últimos 20-30 líneas de logs** para identificar el problema exacto.

## 🎯 Soluciones Comunes

### Solución 1: Si el Error es "Killed" o "Out of memory"

**Problema**: Falta de memoria

**Solución**:
1. Ve a **"Recursos"** en el menú lateral
2. Configura:
   - **Reserva de memoria**: `512` MB
   - **Límite de memoria**: `1024` MB
   - **Reserva de CPU**: `0.5`
   - **Límite de CPU**: `1.0`
3. **Guarda** los cambios
4. Haz clic en **"Implementar"** de nuevo

### Solución 2: Si el Error es "Port already in use"

**Problema**: Conflicto de puertos

**Solución**:
1. Ve a **"Dominios"** en el menú lateral
2. Verifica el puerto configurado
3. Si es `80`, cámbialo a `8080`
4. **Guarda** los cambios
5. Haz clic en **"Implementar"** de nuevo

### Solución 3: Si el Error es "Cannot bind to port"

**Problema**: El puerto está siendo usado por otro servicio

**Solución**:
1. Verifica qué otros servicios están usando el puerto
2. Cambia el puerto de webmail a uno diferente (ej: `8081`, `8082`)
3. **Guarda** los cambios
4. Haz clic en **"Implementar"** de nuevo

### Solución 4: Si No Hay Logs o Están Vacíos

**Problema**: El contenedor no está iniciando

**Solución**:
1. Haz clic en el botón de **play** (▶️) para intentar iniciar manualmente
2. Espera 10-15 segundos
3. Actualiza los logs
4. Si sigue sin funcionar, ve a "Recursos" y aumenta la memoria a `2048` MB

## 📋 Checklist de Verificación

Antes de intentar implementar de nuevo, verifica:

- [ ] **Recursos configurados**: Memoria 512/1024 MB, CPU 0.5/1.0
- [ ] **Dominio configurado**: Puerto 8080 (NO 80)
- [ ] **Variables de entorno**: Todas configuradas
- [ ] **Logs revisados**: Identificado el error específico

## 🚀 Pasos para Reiniciar

1. ✅ **Revisa los logs** y identifica el error
2. ✅ **Corrige el problema** según la solución correspondiente
3. ✅ **Guarda todos los cambios**
4. ✅ **Haz clic en "Implementar"** (botón verde)
5. ✅ **Espera 1-2 minutos**
6. ✅ **Observa los logs** para ver el progreso

## 🆘 Si Nada Funciona

1. **Haz clic en el botón de stop** (cuadrado) para asegurarte de que está detenido
2. **Espera 5 segundos**
3. **Haz clic en "Implementar"** de nuevo
4. **O haz clic en el botón de play** (▶️) para iniciar manualmente

## 💡 Información Necesaria

Para ayudarte mejor, necesito saber:

1. **¿Qué dice en los logs?** (últimas 20-30 líneas)
2. **¿Qué recursos tienes configurados?** (memoria y CPU)
3. **¿Qué puerto tiene configurado el dominio?** (80 o 8080)

Con esa información podré darte la solución exacta.

