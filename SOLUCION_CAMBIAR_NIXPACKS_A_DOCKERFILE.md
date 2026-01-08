# 🔧 Solución: Cambiar de Nixpacks a Dockerfile en EasyPanel

## 🚨 Problema Detectado

EasyPanel está usando **Nixpacks** en lugar de **Dockerfile**. Por eso el Dockerfile no se está usando y faltan las dependencias de Chromium.

---

## ✅ Solución: Cambiar a Dockerfile

### Paso 1: Cambiar el Método de Compilación

1. **En la sección "Compilación"** (donde estás ahora)
2. **Haz clic en el radio button "Dockerfile"** (actualmente está seleccionado "Nixpacks")
3. **Verifica** que ahora esté seleccionado "Dockerfile"

### Paso 2: Configurar la Ruta del Dockerfile (Si Aparece)

Si después de seleccionar "Dockerfile" aparece un campo para la ruta:

1. **Ruta del Dockerfile**: `whatsapp-server/Dockerfile`
   - O si solo busca en la raíz, deja vacío (moveremos el Dockerfile después)

### Paso 3: Guardar y Desplegar

1. **Haz clic en "Guardar"** (botón verde)
2. **Espera** a que se guarden los cambios
3. **Haz clic en "Deploy"** o **"Implementar"**
4. **Espera 3-5 minutos** mientras se construye con Dockerfile

---

## ✅ Solución Alternativa: Usar Nixpacks con Paquetes APT

Si prefieres seguir usando Nixpacks (o no puedes cambiar a Dockerfile):

### Paso 1: Agregar Paquetes APT

En el campo **"Paquetes APT"**, agrega:

```
chromium chromium-sandbox libnss3 libnss3-dev libnss3-tools libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libdbus-1-3 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 libpango-1.0-0 libcairo2 libxshmfence1
```

### Paso 2: Agregar Comando de Instalación (Opcional)

En el campo **"Comando de instalación"**, puedes agregar:

```bash
apt-get update && apt-get install -y chromium chromium-sandbox libnss3 libnss3-dev
```

### Paso 3: Verificar Variables de Entorno

Asegúrate de que estas variables estén configuradas:

```
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
CHROME_BIN=/usr/bin/chromium
```

### Paso 4: Guardar y Desplegar

1. **Haz clic en "Guardar"**
2. **Haz clic en "Deploy"** o **"Implementar"**
3. **Espera** a que termine la construcción

---

## 🎯 Recomendación

**Usa la Solución 1 (Cambiar a Dockerfile)** porque:
- ✅ El Dockerfile ya está configurado con todas las dependencias
- ✅ Es más confiable y predecible
- ✅ No necesitas agregar paquetes manualmente

---

## 📋 Checklist Después de Cambiar

Después de cambiar a Dockerfile y hacer Deploy, verifica los logs:

✅ **Correcto**:
```
🚀 Iniciando servidor WhatsApp...
✅ Dependencias cargadas
✅ Cliente de Supabase inicializado
📡 Servidor corriendo en puerto 3001
✅ Base de conocimiento cargada
✅ WhatsApp listo para conectar
```

❌ **Incorrecto** (si ves esto, algo salió mal):
```
Error: libnss3.so: cannot open shared object file
```

---

## 🆘 Si el Error Persiste

Si después de cambiar a Dockerfile sigue apareciendo el error:

1. **Verifica** que el Dockerfile esté en GitHub en `whatsapp-server/Dockerfile`
2. **Verifica** que la rama sea `main`
3. **Verifica** que la ruta de compilación en Source sea `/whatsapp-server`
4. **Espera** 1-2 minutos y vuelve a hacer "Deploy"

---

## 📖 Referencias

- [SOLUCION_EASYPANEL_NO_USA_DOCKERFILE.md](./SOLUCION_EASYPANEL_NO_USA_DOCKERFILE.md) - Guía completa sobre Dockerfile
- [FORZAR_RECONSTRUCCION_CHROMIUM.md](./FORZAR_RECONSTRUCCION_CHROMIUM.md) - Forzar reconstrucción

