# 🔧 Solución: Cambiar Rama de working-version a main

## 🚨 Problema Detectado

El dashboard está configurado para usar la rama **`working-version`**, pero el código nuevo está en la rama **`main`**.

---

## ✅ Solución: Cambiar la Rama

### Paso 1: Cambiar la Rama en EasyPanel

1. **En la sección "Fuente"** que estás viendo ahora
2. **Busca el campo "Rama"** (Branch)
3. **Cambia el valor** de `working-version` a `main`
4. **Haz clic en "Guardar"** (botón verde)

### Paso 2: Desplegar

1. **Después de guardar**, busca el botón **"Deploy"** o **"Implementar"**
2. **Haz clic en "Deploy"**
3. **Espera 2-3 minutos** mientras se actualiza

### Paso 3: Refrescar el Dashboard

1. **Abre el dashboard**: `https://dashboard.checkin24hs.com`
2. **Refresca forzado**: `Ctrl + F5` (Windows) o `Cmd + Shift + R` (Mac)
3. **O abre en modo incógnito**: `Ctrl + Shift + N`

---

## ✅ Verificación

Después de cambiar a `main` y hacer Deploy, el dashboard debe mostrar:

✅ **Nueva versión (correcta)**:
- Botón verde: **"Conectar Múltiples WhatsApp (hasta 4)"** con icono 📱
- Al hacer clic, se abre un modal con 4 instancias

❌ **Versión antigua (incorrecta)**:
- Botón verde: "+ Agregar conexión a WhatsApp"

---

## 📋 Configuración Correcta

Después del cambio, la configuración debe quedar así:

```
Source: GitHub
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main  ← ¡DEBE SER main, NO working-version!
Ruta de compilación: /
```

---

## 🎯 Resumen

1. ✅ Cambia "Rama" de `working-version` a `main`
2. ✅ Guarda
3. ✅ Haz "Deploy"
4. ✅ Espera 2-3 minutos
5. ✅ Refresca el dashboard (Ctrl+F5)

¡Eso es todo! 🎉

