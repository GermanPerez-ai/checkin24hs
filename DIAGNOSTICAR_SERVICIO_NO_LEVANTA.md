# 🔍 Diagnosticar: Servicio No Levanta (No se Pone en Verde)

## ⏱️ Tiempos Normales

- **Build con Dockerfile**: 5-10 minutos (primera vez puede tardar más)
- **Inicio del servicio**: 30-60 segundos después del build
- **Total**: Puede tardar hasta 10-15 minutos en la primera implementación

---

## 🔍 Qué Verificar Mientras Esperas

### 1. Ver los Logs en Tiempo Real

1. **Ve a EasyPanel** → Servicio `whatsapp`
2. **Haz clic en "Logs"** o **"Registros"**
3. **Observa los mensajes** que aparecen

**Logs que deberías ver (si está bien):**
```
Building Docker image...
Step 1/X : FROM node:18-slim
Step 2/X : RUN apt-get update...
...
Successfully built [image-id]
Starting container...
✅ Servidor iniciado en puerto 3001
📱 Instancia WhatsApp: 1
🌐 Servidor escuchando en 0.0.0.0:3001
```

**Logs que indican problemas:**
```
❌ Error: Cannot find module...
❌ Error: Port already in use
❌ Error: EADDRINUSE
❌ Error: Failed to start
```

---

### 2. Verificar Estado del Build

1. **Ve a "Implementaciones"** o **"Deployments"**
2. **Busca la implementación más reciente**
3. **Verifica el estado**:
   - 🟡 **Building**: Aún está construyendo (normal, espera)
   - 🟢 **Running**: Ya está corriendo (debería estar verde)
   - 🔴 **Failed**: Falló (revisa los logs)
   - ⚪ **Stopped**: Se detuvo (revisa los logs)

---

### 3. Verificar Recursos del Servidor

1. **Ve al resumen del servicio**
2. **Verifica el uso de recursos**:
   - **CPU**: Debería estar > 0% si está corriendo
   - **Memoria**: Debería estar > 0 B si está corriendo
   - **Si todo está en 0**: El servicio no está corriendo

---

## 🚨 Problemas Comunes y Soluciones

### Problema 1: Build Tarda Mucho

**Síntomas:**
- El build lleva más de 15 minutos
- Los logs muestran que está en "Building Docker image..."

**Solución:**
- Es normal en la primera vez (descarga imágenes base)
- Espera hasta 20 minutos
- Si pasa de 20 minutos, puede haber un problema de red o recursos

---

### Problema 2: Error en el Build

**Síntomas:**
- Los logs muestran errores como:
  - `Error: Cannot find module 'express'`
  - `Error: npm install failed`
  - `Error: COPY failed`

**Solución:**
1. **Verifica que el Dockerfile esté correcto** en GitHub
2. **Verifica que `package.json` exista** en `whatsapp-server/`
3. **Verifica la ruta de compilación**: Debe ser `/whatsapp-server`

---

### Problema 3: Error al Iniciar el Servicio

**Síntomas:**
- El build terminó exitosamente
- Pero el servicio no inicia
- Los logs muestran: `Error: Port already in use` o `EADDRINUSE`

**Solución:**
1. **Verifica que el puerto 3001 no esté en uso**:
   - Ve a otros servicios y verifica que ninguno use el puerto 3001
2. **Verifica las variables de entorno**:
   - `PORT=3001` debe estar configurado
3. **Reinicia el servicio** después de corregir

---

### Problema 4: Error de Variables de Entorno

**Síntomas:**
- Los logs muestran: `Error: SUPABASE_URL is required`
- O errores relacionados con variables faltantes

**Solución:**
1. **Ve a "Entorno"** o **"Environment"**
2. **Verifica que todas las variables estén configuradas**:
   ```
   PORT=3001
   INSTANCE_NUMBER=1
   SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
   SUPABASE_ANON_KEY=...
   GEMINI_API_KEY=...
   BASE_URL=https://whatsapp.checkin24hs.com
   ```
3. **Guarda y reinicia** el servicio

---

### Problema 5: El Servicio se Inicia pero se Detiene Inmediatamente

**Síntomas:**
- Los logs muestran que inició correctamente
- Pero luego se detiene
- El estado cambia de verde a gris rápidamente

**Solución:**
1. **Revisa los logs completos** (no solo los últimos)
2. **Busca errores después del inicio**:
   - Errores de conexión a Supabase
   - Errores de autenticación
   - Errores de dependencias faltantes
3. **Verifica que el comando de inicio sea correcto**:
   ```
   node whatsapp-server-baileys.js
   ```

---

## ✅ Checklist de Verificación

Mientras esperas, verifica:

- [ ] Los logs muestran que el build está progresando
- [ ] No hay errores en los logs
- [ ] Las variables de entorno están configuradas
- [ ] El puerto 3001 no está en uso por otro servicio
- [ ] El Dockerfile existe en GitHub en `whatsapp-server/Dockerfile`
- [ ] La ruta de compilación es `/whatsapp-server`
- [ ] El método de build es "Dockerfile" (no Nixpacks)

---

## 🎯 Pasos Siguientes

### Si Después de 10-15 Minutos No Levanta:

1. **Revisa los logs completos** (haz scroll hacia arriba)
2. **Copia el último error** que aparezca
3. **Verifica el estado de la implementación** en "Implementaciones"
4. **Si hay un error específico**, compártelo y te ayudo a solucionarlo

---

## 💡 Consejos

- **Primera implementación**: Puede tardar hasta 15-20 minutos (normal)
- **Implementaciones siguientes**: Deberían tardar 2-5 minutos
- **Si tarda mucho**: Revisa los logs, no esperes indefinidamente
- **Si hay errores**: Copia el mensaje de error completo para diagnosticar

---

## 📝 Qué Hacer Ahora

1. ✅ **Espera 2-5 minutos más** (si acabas de hacer el deploy)
2. ✅ **Revisa los logs** en tiempo real
3. ✅ **Verifica el estado** en "Implementaciones"
4. ✅ **Si hay errores**, cópialos y compártelos
