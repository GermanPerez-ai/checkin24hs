# 🔍 Dónde Está el "Comando de Inicio" en EasyPanel

## 📍 Ubicación del Campo "Comando de Inicio"

El campo **"Comando de inicio"** (Start Command) en EasyPanel puede estar en diferentes lugares dependiendo de la versión:

### Opción 1: Pestaña "Variables de Entorno" o "Environment"
1. Ve al servicio `checkin24hs-dashboard`
2. Busca la pestaña **"Variables de Entorno"** o **"Environment"**
3. Busca un campo llamado:
   - **"Comando de inicio"**
   - **"Start Command"**
   - **"Command"**
   - **"Entrypoint"**

### Opción 2: Pestaña "Configuración" o "Settings"
1. Ve al servicio `checkin24hs-dashboard`
2. Busca la pestaña **"Configuración"** o **"Settings"**
3. Busca un campo llamado **"Comando de inicio"** o **"Start Command"**

### Opción 3: En la Sección "Compilación" (Build)
1. Ve al servicio `checkin24hs-dashboard`
2. Ve a la pestaña **"Fuente"** o **"Source"**
3. En la sección **"Compilación"** (Build), después de seleccionar **"Dockerfile"**
4. Puede haber un campo adicional para el comando de inicio

### Opción 4: Si Usa Dockerfile
**IMPORTANTE**: Si estás usando **Dockerfile** (como deberías), el comando de inicio está definido en el `Dockerfile` mismo con la línea:
```dockerfile
CMD ["node", "server.js"]
```

En este caso, **NO necesitas configurar un comando de inicio adicional** en EasyPanel, porque el Dockerfile ya lo define.

## ✅ Verificación

### Si el Dockerfile tiene CMD:
```dockerfile
CMD ["node", "server.js"]
```

Entonces **NO necesitas** configurar nada más en EasyPanel. El Dockerfile ya especifica cómo iniciar el servicio.

### Si NO hay CMD en el Dockerfile:
Entonces necesitas buscar el campo "Comando de inicio" en EasyPanel y poner:
```
node server.js
```

## 🔍 Cómo Verificar si el Comando Está Correcto

Ejecuta este comando en SSH para ver qué comando está usando el contenedor:

```bash
echo "🔍 Verificando comando de inicio..." && CONTAINER_ID=$(docker ps | grep checkin24hs_checkin24hs-dashboard | awk '{print $1}' | head -1) && docker inspect $CONTAINER_ID --format '{{.Config.Cmd}}' && echo "" && echo "Entrypoint:" && docker inspect $CONTAINER_ID --format '{{.Config.Entrypoint}}'
```

**Resultado esperado:**
- `Cmd`: `[node server.js]` o similar
- `Entrypoint`: puede estar vacío o ser `[]`

## 📝 Nota Importante

Si tu `Dockerfile` tiene:
```dockerfile
CMD ["node", "server.js"]
```

Entonces **NO necesitas** configurar un "Comando de inicio" en EasyPanel. El Dockerfile ya lo define y EasyPanel lo usará automáticamente.

