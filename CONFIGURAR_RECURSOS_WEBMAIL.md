# 🔧 Configurar Recursos para Webmail

## 📸 Problema Identificado

Los recursos están en **0** (ilimitados), lo que puede causar que el sistema mate el contenedor por falta de límites definidos.

## ✅ Solución: Configurar Límites Apropiados

### Configuración Recomendada

En la sección "Recursos", configura estos valores:

1. **Reserva de memoria (MB)**: `512`
   - Esta es la memoria garantizada para el contenedor

2. **Límite de memoria (MB)**: `1024`
   - Este es el máximo que puede usar (1 GB es suficiente para Roundcube)

3. **Reserva de CPU (núcleos)**: `0.5`
   - Medio núcleo garantizado

4. **Límite de CPU (núcleos)**: `1.0`
   - Un núcleo completo como máximo

### Pasos Exactos

1. En el campo **"Reserva de memoria (MB)"**, escribe: `512`
2. En el campo **"Límite de memoria (MB)"**, escribe: `1024`
3. En el campo **"Reserva de CPU (núcleos)"**, escribe: `0.5`
4. En el campo **"Límite de CPU (núcleos)"**, escribe: `1.0`
5. Haz clic en el botón verde **"Guardar"**

## 🎯 Por Qué Estos Valores

- **512 MB de reserva**: Garantiza que el contenedor tenga memoria suficiente para iniciar
- **1024 MB de límite**: Evita que use demasiada memoria y mate otros servicios
- **0.5 CPU de reserva**: Garantiza recursos de CPU mínimos
- **1.0 CPU de límite**: Permite usar un núcleo completo cuando sea necesario

## 📋 Próximos Pasos Después de Configurar Recursos

1. ✅ **Guarda los recursos** (como se indicó arriba)
2. ✅ **Ve a "Dominios"** y verifica que el puerto sea 8080 (NO 80)
3. ✅ **Ve a "Entorno"** y verifica las variables de entorno
4. ✅ **Haz clic en "Implementar"** (botón verde)
5. ✅ **Espera 1-2 minutos** y observa los logs

## 🔍 Si Aún Se Mata el Contenedor

Si después de configurar los recursos el contenedor sigue matándose:

1. **Aumenta el límite de memoria** a `2048` (2 GB)
2. **Verifica los logs** en "Registros" para ver el error específico
3. **Verifica que no haya conflicto de puertos** con roundcube

## 💡 Nota Importante

Aunque el sistema dice "0 para recursos ilimitados", en la práctica:
- Los contenedores sin límites pueden ser matados por el sistema operativo
- Es mejor definir límites apropiados
- Los valores recomendados son suficientes para Roundcube

