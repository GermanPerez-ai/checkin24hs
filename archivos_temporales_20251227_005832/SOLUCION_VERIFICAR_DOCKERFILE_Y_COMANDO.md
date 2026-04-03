# 🔧 Verificar Dockerfile y Comando de Inicio

## 🚨 Problema

El servicio sigue ejecutando `react-scripts start` (modo desarrollo) en lugar de usar el Dockerfile.

## ✅ Verificaciones Necesarias

### 1. Verificar que Esté Usando Dockerfile

1. **Ve a** → **Servicios** → `checkin24hs-dashboard` → **Fuente**
2. **Busca la sección "Compilación"** o la pestaña correspondiente
3. **Verifica** que esté seleccionado **"Dockerfile"** (no Nixpacks)
4. Si está en Nixpacks, **cámbialo a Dockerfile** y guarda

### 2. Verificar Comando de Inicio

1. **Ve a** → **Servicios** → `checkin24hs-dashboard` → **Implementar** o **Avanzado**
2. **Busca un campo "Comando"** o **"Start Command"** o **"Comando de inicio"**
3. **Si hay un comando configurado**, debe ser:
   - `node server.js`
   - O estar vacío (para usar el CMD del Dockerfile)
4. **Si dice** `npm start` o `react-scripts start`, **bórralo** o cámbialo a `node server.js`

### 3. Verificar que el Dockerfile Esté en GitHub

El Dockerfile debe estar en: `checkin24hs-admin/Dockerfile` en la rama `working-version`.

## 🔧 Solución: Configurar Comando de Inicio

Si el campo "Comando" existe y tiene `npm start`:

1. **Borra** el comando (déjalo vacío) para que use el CMD del Dockerfile
2. **O cámbialo a**: `node server.js`
3. **Guarda** los cambios
4. **Implementa** de nuevo

---

**Verifica:**
1. ¿Está seleccionado "Dockerfile" en la compilación?
2. ¿Hay un campo "Comando" o "Start Command" configurado? ¿Qué dice?

Con esa información te digo exactamente qué cambiar.

