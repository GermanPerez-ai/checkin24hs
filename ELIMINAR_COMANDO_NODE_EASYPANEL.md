# 🔧 Eliminar Comando Node.js en EasyPanel

## 🎯 Problema Encontrado

En la sección **"Implementar"** (Deploy), el campo **"Comando"** tiene configurado:
```
node server.js
```

Este comando intenta ejecutar Node.js, pero el contenedor `nginx:alpine` **NO tiene Node.js instalado**, por eso aparece el error `/bin/sh: node: not found`.

## ✅ Solución: Eliminar el Comando

### Paso 1: Ir a la Sección "Implementar"

1. En EasyPanel, ve al servicio `dashboard`
2. En el menú lateral izquierdo, busca la sección **"Implementar"** o **"Deploy"**
3. O desplázate hacia abajo en la página actual hasta encontrar la sección **"Implementar"**

### Paso 2: Encontrar el Campo "Comando"

1. En la sección **"Implementar"**, busca el campo **"Comando"** o **"Command"**
2. Actualmente debería decir: `node server.js`

### Paso 3: Eliminar el Comando

1. **Selecciona todo el texto** en el campo "Comando"
2. **Bórralo completamente** (déjalo vacío)
3. O escribe: `nginx -g "daemon off;"` (aunque el Dockerfile ya lo define)

### Paso 4: Guardar

1. Haz clic en el botón verde **"Guardar"** o **"Save"** en la sección "Implementar"
2. Espera a que aparezca un mensaje de confirmación

### Paso 5: Reiniciar el Servicio

1. Haz clic en el icono de **"Stop"** (cuadrado) para detener el servicio
2. Espera 5 segundos
3. Haz clic en **"Implementar"** o **"Deploy"** para reiniciar

---

## 📋 Configuración Correcta

**ANTES (Incorrecto):**
- Comando: `node server.js` ❌

**DESPUÉS (Correcto):**
- Comando: **(vacío)** ✅
- O: `nginx -g "daemon off;"` ✅

**¿Por qué vacío?**
Porque el Dockerfile ya define el comando correcto:
```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

EasyPanel usará automáticamente este comando del Dockerfile.

---

## ✅ Verificación

Después de eliminar el comando y reiniciar:

1. Los errores `/bin/sh: node: not found` deberían desaparecer
2. El servicio debería estar en **verde**
3. El dashboard debería cargar en `https://dashboard.checkin24hs.com/`

---

¡Elimina el comando `node server.js` y el problema debería resolverse!
