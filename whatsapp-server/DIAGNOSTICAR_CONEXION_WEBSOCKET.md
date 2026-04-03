# 🔍 Diagnosticar Problema "Connecting to websocket..."

## ⚠️ Síntoma
El servidor se queda en el estado "Connecting to websocket..." y no avanza.

## 🔍 Posibles Causas

1. **Esperando generación de QR code** (normal si es primera vez)
2. **Problema de conexión a WhatsApp Web**
3. **Sesión antigua corrupta**
4. **Timeout en la conexión**
5. **Error no visible en los logs**

---

## ✅ Soluciones Paso a Paso

### Paso 1: Ver Logs Completos

En EasyPanel → Servicios → `whatsapp` → **Logs**:

1. **Desplázate hacia arriba** para ver TODOS los mensajes desde el inicio
2. Busca estos mensajes importantes:
   - `🚀 Iniciando servidor WhatsApp con Baileys...`
   - `✅ Servidor iniciado en puerto 3001`
   - `✅ Cliente de Supabase inicializado`
   - `📱 QR Code recibido` (si es primera vez)
   - Cualquier mensaje de error (❌)

### Paso 2: Verificar Estado del Servicio

En EasyPanel:
- ¿El servicio está en estado **"Running"** (verde)?
- ¿O está en **"Restarting"** o **"Stopped"**?

### Paso 3: Esperar Más Tiempo

A veces la conexión puede tardar:
- **Primera vez**: Hasta 2-3 minutos para generar QR
- **Con sesión guardada**: Hasta 1-2 minutos para autenticar

### Paso 4: Reiniciar el Servicio

Si lleva más de 5 minutos sin avanzar:

1. En EasyPanel → Servicios → `whatsapp`
2. Haz clic en **"Restart"**
3. Espera 1-2 minutos
4. Revisa los logs nuevamente

### Paso 5: Limpiar Sesión (Si es necesario)

Si el problema persiste, puede ser una sesión corrupta:

1. En EasyPanel → Servicios → `whatsapp` → **Mount Points**
2. Verifica que el volumen `whatsapp-session` esté montado en `/app/auth_info_baileys_1`
3. Si quieres empezar de cero:
   - Detén el servicio
   - Elimina el volumen (o sus contenidos)
   - Reinicia el servicio
   - Se generará un nuevo QR code

---

## 🔍 Verificar desde el Servidor (Opcional)

Si tienes acceso SSH al servidor:

```bash
# Ver contenedores Docker
docker ps | grep whatsapp

# Ver logs del contenedor (últimas 100 líneas)
docker logs <nombre_contenedor> --tail 100

# Ver logs en tiempo real
docker logs <nombre_contenedor> -f
```

---

## ✅ Qué Deberías Ver en los Logs

### Escenario 1: Primera Conexión (Sin Sesión)
```
🚀 Iniciando servidor WhatsApp con Baileys...
✅ Cliente de Supabase inicializado
✅ Servidor iniciado en puerto 3001
📱 Instancia WhatsApp: 1
Connecting to websocket...
📱 QR Code recibido (longitud: XXX caracteres)
✅ QR Code imagen generada exitosamente
```

### Escenario 2: Reconexión (Con Sesión Guardada)
```
🚀 Iniciando servidor WhatsApp con Baileys...
✅ Cliente de Supabase inicializado
✅ Servidor iniciado en puerto 3001
Connecting to websocket...
✅ WhatsApp conectado exitosamente para instancia 1
📱 Teléfono conectado: [número]
```

### Escenario 3: Error
```
Connecting to websocket...
❌ Error: [descripción del error]
```

---

## 🆘 Si Nada Funciona

1. **Verifica variables de entorno** en EasyPanel:
   - `INSTANCE_NUMBER=1`
   - `PORT=3001`
   - `SUPABASE_URL` y `SUPABASE_ANON_KEY` correctos

2. **Verifica el puerto**:
   - Puerto 3001 debe estar configurado y accesible

3. **Revisa recursos del servidor**:
   - ¿Hay suficiente memoria?
   - ¿El servidor no está sobrecargado?

4. **Contacta soporte** si el problema persiste después de intentar todo lo anterior

---

## 📊 Resumen

- ✅ "Connecting to websocket..." es **normal** al iniciar
- ⏳ Debe avanzar en **1-3 minutos** máximo
- 🔄 Si no avanza, **reinicia el servicio**
- 🔍 Revisa **todos los logs** (no solo los últimos)
