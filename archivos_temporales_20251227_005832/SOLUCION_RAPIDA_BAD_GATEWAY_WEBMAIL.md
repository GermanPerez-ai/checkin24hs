# 🔧 Solución Rápida: Bad Gateway Webmail

## 🚨 Problema Actual

El webmail muestra **Bad Gateway (502)** nuevamente.

## ✅ Solución Inmediata (3 Pasos)

### Paso 1: Verificar Estado en EasyPanel

1. **Abre EasyPanel**
2. Ve a: **Proyecto "checkin24hs"** → **Servicio "webmail"**
3. **Observa el punto** junto a "webmail":
   - ✅ **VERDE** = Servicio corriendo
   - ❌ **ROJO** = Servicio detenido

---

### Paso 2: Si el Punto está ROJO

**El servicio se detuvo. Necesitas reiniciarlo:**

1. Ve a **"Recursos"** (menú lateral)
2. Verifica que:
   - **Memoria**: Al menos 512 MB (mejor 1024 MB)
   - **CPU**: Al menos 0.5 (mejor 1.0)
3. Si están en 0, **cámbialos** y **guarda**
4. Haz clic en el botón verde **"Implementar"**
5. Espera **1-2 minutos**
6. El punto debe cambiar a **VERDE**

---

### Paso 3: Si el Punto está VERDE pero sigue 502

**El puerto está mal configurado:**

1. Ve a **"Dominios"** (menú lateral)
2. Busca: `webmail.checkin24hs.com`
3. Haz clic en el dominio para editarlo
4. **VERIFICA el PUERTO**:
   - ✅ Debe ser **80** (puerto interno)
   - ❌ NO debe ser **8080** (ese es el externo)
5. Si es 8080, **cámbialo a 80**
6. **Guarda** los cambios
7. Espera **10-15 segundos**
8. Actualiza la página del webmail (**F5**)

---

## 🔍 Diagnóstico Rápido

### Verificar en EasyPanel:

1. **Estado del servicio**: ¿VERDE o ROJO?
2. **Recursos**: ¿Están en 0 o tienen valores?
3. **Puerto en Dominios**: ¿Es 80 o 8080?
4. **Logs**: ¿Qué dicen los últimos mensajes?

---

## 🎯 Solución Más Común

**99% de los casos de Bad Gateway se deben a:**

1. **Servicio detenido** (punto rojo)
   → Solución: Configurar recursos y hacer clic en "Implementar"

2. **Puerto incorrecto** (8080 en lugar de 80)
   → Solución: Cambiar puerto a 80 en "Dominios"

---

## 📋 Checklist Rápido

- [ ] Punto en EasyPanel: ¿VERDE o ROJO?
- [ ] Recursos: ¿Memoria > 0?
- [ ] Puerto en Dominios: ¿Es 80?
- [ ] ¿Hiciste clic en "Implementar"?

---

## 🚀 Pasos Exactos (Copia y Pega)

1. **EasyPanel** → **checkin24hs** → **webmail**
2. **Recursos** → Memoria: 1024 MB → **Guardar**
3. **Dominios** → webmail.checkin24hs.com → Puerto: **80** → **Guardar**
4. **Implementar** (botón verde)
5. Esperar 1-2 minutos
6. Verificar que el punto esté **VERDE**
7. Acceder a: `https://webmail.checkin24hs.com`

---

## ⚠️ Nota Importante

**El puerto en "Dominios" debe ser 80 (puerto INTERNO), NO 8080.**

EasyPanel mapea automáticamente:
- Puerto externo: 8080
- Puerto interno: 80
- En "Dominios" usas el **interno (80)**

---

## 🆘 Si Sigue Sin Funcionar

1. Ve a **"Registros"** en EasyPanel
2. Haz clic en **"Actualizar registros"**
3. Copia los últimos **20-30 líneas**
4. Busca errores como:
   - "Killed"
   - "Out of memory"
   - "Port already in use"
   - "502"

Con esa información podremos identificar el problema exacto.



