# ⚙️ Agregar Comando de Inicio para WhatsApp

## 📍 Dónde Configurar el Comando

### Opción 1: En la Sección "Build" o "Compilación" (MÁS COMÚN)

1. **Ve a EasyPanel** → Servicio `whatsapp`
2. **Ve a "Fuente"** o **"Source"**
3. **Desplázate hasta la sección "Build"** o **"Compilación"**
4. **Busca un campo llamado**:
   - **"Comando"** o **"Command"**
   - **"Comando de inicio"** o **"Start Command"**
   - **"Run Command"**
   - **"Entrypoint"**

5. **Ingresa el comando**:
   ```
   node whatsapp-server-baileys.js
   ```

6. **Guarda** los cambios

---

### Opción 2: Pestaña Separada "Comando"

1. **Ve a EasyPanel** → Servicio `whatsapp`
2. **Busca una pestaña llamada**:
   - **"Comando"**
   - **"Command"**
   - **"Run"**

3. **Ingresa el comando**:
   ```
   node whatsapp-server-baileys.js
   ```

4. **Guarda** los cambios

---

### Opción 3: En Variables de Entorno (Si Existe)

Algunas versiones de EasyPanel tienen un campo especial en Variables de Entorno:

1. **Ve a "Entorno"** o **"Environment"**
2. **Busca un campo**:
   - **"COMMAND"**
   - **"START_COMMAND"**
   - **"CMD"**

3. **Ingresa**:
   ```
   node whatsapp-server-baileys.js
   ```

---

## ⚠️ IMPORTANTE: Si Usas Dockerfile

**Si ya configuraste Dockerfile**, el comando **YA está definido** en el Dockerfile:

```dockerfile
CMD ["node", "whatsapp-server-baileys.js"]
```

**En este caso:**
- ✅ El Dockerfile ya tiene el comando
- ✅ EasyPanel debería usarlo automáticamente
- ⚠️ **PERO** a veces EasyPanel necesita que lo configures también en la interfaz

**Recomendación**: Configúralo en ambos lugares:
1. ✅ En el Dockerfile (ya está)
2. ✅ En EasyPanel (en la sección Build o Comando)

---

## ✅ Comando Correcto

El comando que debes usar es:

```bash
node whatsapp-server-baileys.js
```

**NO uses:**
- ❌ `node whatsapp-server.js` (archivo incorrecto)
- ❌ `npm start` (puede no funcionar)
- ❌ `node server.js` (archivo incorrecto)

---

## 🔍 Cómo Verificar que Está Correcto

Después de configurar y hacer deploy, revisa los logs. Deberías ver:

```
✅ Servidor iniciado en puerto 3001
📱 Instancia WhatsApp: 1
🌐 Servidor escuchando en 0.0.0.0:3001
```

**Si ves errores como:**
- ❌ `Cannot find module 'whatsapp-server-baileys.js'`
- ❌ `Error: Cannot find module`
- ❌ `File not found`

**Entonces:**
1. Verifica que la **ruta de compilación** sea `/whatsapp-server`
2. Verifica que el archivo exista en GitHub en `whatsapp-server/whatsapp-server-baileys.js`

---

## 📝 Resumen Rápido

1. **Ve a EasyPanel** → Servicio `whatsapp`
2. **Busca la sección "Build"** o **"Comando"**
3. **Ingresa**: `node whatsapp-server-baileys.js`
4. **Guarda** y **haz deploy** nuevamente

---

## 🎯 Ubicaciones Posibles del Campo

El campo puede estar en:
- ✅ Sección "Build" o "Compilación" (dentro de "Fuente")
- ✅ Pestaña separada "Comando" o "Command"
- ✅ Sección "Variables de Entorno" (campo especial)
- ✅ Sección "Configuración" o "Settings"

**Si no lo encuentras**, busca en todas las pestañas del servicio.
