# ⚙️ Configurar Recursos para WhatsApp-1

## ❌ Problema Actual

Todos los recursos están en `0` (ilimitados), lo que puede causar que el sistema no asigne recursos suficientes durante el build, resultando en "Killed".

## ✅ Solución: Establecer Límites Específicos

Aunque `0` significa "ilimitado", es mejor establecer límites específicos para garantizar que el servicio tenga recursos suficientes.

## 🎯 Configuración Recomendada

### Para el Servicio WhatsApp-1:

1. **Reserva de memoria (MB)**: `512` (512 MB)
2. **Límite de memoria (MB)**: `1024` (1 GB)
3. **Reserva de CPU (núcleos)**: `0.5` (medio núcleo)
4. **Límite de CPU (núcleos)**: `1` (un núcleo completo)

### Pasos para Configurar:

1. **En la sección "Recursos"**, completa los campos:
   - **Reserva de memoria (MB)**: `512`
   - **Límite de memoria (MB)**: `1024`
   - **Reserva de CPU (núcleos)**: `0.5`
   - **Límite de CPU (núcleos)**: `1`

2. **Haz clic en el botón verde "Guardar"** (parte inferior)

3. **Espera a que aparezca un mensaje de confirmación**

4. **Re-implementa el servicio**:
   - Ve a "Resumen"
   - Haz clic en el botón verde "Implementar"
   - Espera 2-3 minutos

## 🔍 Por Qué Esto Ayuda

- ✅ **Reserva de memoria**: Garantiza que el servicio tenga al menos 512 MB disponibles
- ✅ **Límite de memoria**: Evita que el servicio use más de 1 GB (previene OOM Killer)
- ✅ **Reserva de CPU**: Garantiza que el servicio tenga al menos medio núcleo disponible
- ✅ **Límite de CPU**: Evita que el servicio use más de un núcleo completo

## 📋 Checklist

- [ ] Establecer reserva de memoria: `512` MB
- [ ] Establecer límite de memoria: `1024` MB
- [ ] Establecer reserva de CPU: `0.5` núcleos
- [ ] Establecer límite de CPU: `1` núcleo
- [ ] Hacer clic en "Guardar"
- [ ] Re-implementar el servicio (botón "Implementar")
- [ ] Esperar 2-3 minutos
- [ ] Verificar que la implementación sea exitosa

## 🎯 Próximos Pasos

1. **Configura los recursos** como se indica arriba
2. **Guarda los cambios** (botón "Guardar")
3. **Re-implementa el servicio** (botón "Implementar")
4. **Espera 2-3 minutos** a que termine
5. **Comparte el resultado** (éxito o error)

Con estos límites específicos, el servicio debería tener recursos suficientes para completar el build sin ser "Killed".

