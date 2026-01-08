# 📍 Guía Visual: Dónde Configurar en EasyPanel

## 🎯 Estás en la Pantalla Correcta

Estás viendo la configuración del servicio `whatsapp-1`. Ahora necesitas configurar varias cosas en diferentes secciones.

---

## 📋 Paso 1: Configurar la Fuente (Source) - DONDE ESTÁS AHORA

### Opción A: Si tienes el código en GitHub

1. **Mantén la pestaña "Github" seleccionada** (ya la tienes)
2. **Completa los campos**:
   - **Propietario**: Tu usuario de GitHub (ej: `GermanPerez-ai`)
   - **Repositorio**: El nombre del repositorio (ej: `checkin24hs`)
   - **Rama**: `main` (o la rama que uses)
   - **Ruta de compilación**: `/` (deja el slash)
3. **Haz clic en "Guardar"** (botón verde abajo)

### Opción B: Si tienes el código localmente

1. **Haz clic en la pestaña "Subir"**
2. **Sube el archivo** `whatsapp-server.js` o la carpeta completa
3. **Haz clic en "Guardar"**

### Opción C: Si usas Git directo

1. **Haz clic en la pestaña "Git"**
2. **Ingresa la URL del repositorio**
3. **Haz clic en "Guardar"**

---

## 📋 Paso 2: Configurar Variables de Entorno

**IMPORTANTE**: Después de guardar la fuente, necesitas ir a otra sección.

1. **Busca en el menú lateral** (izquierda) o en la parte superior de la pantalla
2. **Busca una pestaña o sección llamada**:
   - "Variables de Entorno" o
   - "Environment Variables" o
   - "Variables" o
   - "Env"

3. **Haz clic en esa sección**

4. **Agrega estas variables** (haz clic en "+" o "Agregar Variable"):

#### Para whatsapp-1 (Instancia 1):
```
INSTANCE_NUMBER = 1
PORT = 3001
SUPABASE_URL = https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

5. **Guarda las variables**

---

## 📋 Paso 3: Configurar Puertos

1. **Busca la sección "Puertos"** o **"Ports"** en el menú
2. **Haz clic en esa sección**
3. **Configura**:
   - **Puerto Interno**: `3001`
   - **Puerto Externo**: `3001` (o déjalo automático)
   - **Protocolo**: `HTTP`
4. **Guarda**

---

## 📋 Paso 4: Configurar Comando de Inicio

1. **Busca la sección**:
   - "Comando de Inicio" o
   - "Start Command" o
   - "Build Command" o
   - "Run Command"

2. **Haz clic en esa sección**

3. **Ingresa**:
```bash
node whatsapp-server.js
```

4. **Guarda**

---

## 📋 Paso 5: Iniciar el Servicio

1. **Busca el botón "Iniciar"** o **"Start"** o **"Deploy"**
2. **Haz clic en él**
3. **Espera unos segundos**
4. **Verifica que el servicio esté en VERDE** (Running)

---

## 🗺️ Navegación en EasyPanel

Las secciones suelen estar en:

### Opción 1: Pestañas en la parte superior
```
[Fuente] [Variables] [Puertos] [Comando] [Logs] [Configuración]
```

### Opción 2: Menú lateral izquierdo
```
- Configuración
  - Fuente
  - Variables de Entorno
  - Puertos
  - Comando
```

### Opción 3: Menú desplegable
```
☰ Menú
  ├─ Fuente
  ├─ Variables
  ├─ Puertos
  └─ Comando
```

---

## 📝 Resumen: Dónde Configurar Cada Cosa

| Configuración | Dónde Está | Qué Ingresar |
|---------------|------------|--------------|
| **Fuente** | Pestaña "Github" (donde estás ahora) | Usuario, Repo, Rama |
| **Variables** | Sección "Variables de Entorno" | INSTANCE_NUMBER=1, PORT=3001, etc. |
| **Puertos** | Sección "Puertos" | Puerto interno: 3001 |
| **Comando** | Sección "Comando de Inicio" | `node whatsapp-server.js` |
| **Iniciar** | Botón "Iniciar" o "Start" | - |

---

## 🔍 Si No Encuentras las Secciones

1. **Busca un menú de 3 líneas** (☰) en la parte superior
2. **Busca pestañas** en la parte superior de la pantalla
3. **Desplázate hacia abajo** en la página actual
4. **Busca un botón "Configuración"** o "Settings"
5. **Revisa el menú lateral izquierdo** (donde está la lista de servicios)

---

## ✅ Checklist para whatsapp-1

- [ ] Fuente configurada (Github/Git/Subir)
- [ ] Variables de entorno agregadas (INSTANCE_NUMBER=1, PORT=3001, etc.)
- [ ] Puerto interno configurado (3001)
- [ ] Comando de inicio configurado (`node whatsapp-server.js`)
- [ ] Servicio iniciado (botón verde "Running")
- [ ] Sin errores en los logs

---

## 🚀 Después de Configurar whatsapp-1

Repite los mismos pasos para:
- `whatsapp-2` (INSTANCE_NUMBER=2, PORT=3002)
- `whatsapp-3` (INSTANCE_NUMBER=3, PORT=3003)
- `whatsapp-4` (INSTANCE_NUMBER=4, PORT=3004)

---

## 💡 Consejo

Si no encuentras alguna sección, **toma una captura de pantalla** de lo que ves y te ayudo a ubicar exactamente dónde está cada cosa en tu versión de EasyPanel.

