# 🔧 Solución: Error `/bin/sh: node: not found`

## 🎯 Problema

Aparecen errores `/bin/sh: node: not found` en los logs, pero el build fue exitoso.

## ✅ Solución: Verificar Comandos en EasyPanel

### Paso 1: Ir a la Pestaña "Entorno" o "Variables"

1. En EasyPanel, ve al servicio `dashboard`
2. Haz clic en la pestaña **"Entorno"** o **"Environment"** o **"Variables de Entorno"**

### Paso 2: Buscar Comandos de Inicio

Busca estos campos (pueden estar en diferentes secciones):

1. **"Comando de inicio"** o **"Start Command"**
2. **"Comando de build"** o **"Build Command"**
3. **"Comando"** o **"Command"**
4. **"Entrypoint"**

### Paso 3: Eliminar Comandos con Node

Si encuentras algún campo con comandos que incluyan:
- `node`
- `npm`
- `npx`
- `yarn`

**Elimínalos completamente** o déjalos vacíos.

### Paso 4: Verificar Pestaña "Compilación"

1. Ve a la pestaña **"Fuente"** o **"Source"**
2. Desplázate a la sección **"Compilación"** o **"Build"**
3. Verifica que NO haya:
   - **"Comando de build"** con `npm` o `node`
   - **"Comando de instalación"** con `npm install`
   - **"Comando de inicio"** con `node`

### Paso 5: Guardar y Reiniciar

1. Guarda todos los cambios
2. Reinicia el servicio:
   - Haz clic en el icono de **"Stop"** (cuadrado)
   - Espera 5 segundos
   - Haz clic en **"Implementar"** o **"Deploy"** de nuevo

---

## 🔍 Verificación Rápida

### ¿El Dashboard Funciona A Pesar del Error?

1. Abre: `https://dashboard.checkin24hs.com/`
2. Si el dashboard **carga correctamente**, los errores de Node pueden ser:
   - De un script que se ejecuta pero falla silenciosamente
   - De un comando post-deploy que no es crítico
   - Puedes ignorarlos si el servicio funciona

### Si el Dashboard NO Funciona

1. Verifica que el servicio esté en **verde**
2. Revisa los logs completos (no solo los errores de Node)
3. Busca otros errores que puedan estar causando el problema

---

## 📋 Configuración Correcta para Nginx

Cuando usas un Dockerfile con `nginx:alpine`:

✅ **CORRECTO:**
- Build Path: `/deploy`
- Archivo: `Dockerfile`
- Tipo: `Dockerfile`
- Comando de inicio: **VACÍO** (el Dockerfile ya lo define)
- Comando de build: **VACÍO** (el Dockerfile ya lo define)

❌ **INCORRECTO:**
- Comando de inicio: `node server.js` ❌
- Comando de build: `npm install` ❌
- Cualquier comando con `node`, `npm`, `npx` ❌

---

## 🎯 Próximos Pasos

1. Verifica si hay comandos configurados en EasyPanel
2. Elimínalos si los encuentras
3. Reinicia el servicio
4. Verifica si el dashboard funciona a pesar de los errores

¿El dashboard está funcionando o sigue sin cargar?
