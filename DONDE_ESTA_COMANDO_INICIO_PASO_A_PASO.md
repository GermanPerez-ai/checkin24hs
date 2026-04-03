# 🔍 Dónde Está el "Comando de Inicio" en EasyPanel

## ⚠️ IMPORTANTE: Si Usas Dockerfile

Si tu configuración es:
- **Tipo de compilación**: `Dockerfile` ✅
- **Archivo Dockerfile**: `Dockerfile` ✅

Entonces **NO necesitas** configurar un "Comando de inicio" en EasyPanel, porque el Dockerfile ya lo define con:
```dockerfile
CMD ["node", "server.js"]
```

EasyPanel usará automáticamente el comando del Dockerfile.

---

## 📍 Dónde Buscar el Campo "Comando de Inicio"

### Opción 1: En la Sección "Compilación" (Build) - MÁS COMÚN

1. Ve al servicio `checkin24hs-dashboard`
2. Ve a la pestaña **"Fuente"** o **"Source"** (donde estás ahora)
3. Desplázate hacia abajo hasta la sección **"Compilación"** (Build)
4. Después de seleccionar **"Dockerfile"**, busca:
   - Un campo llamado **"Comando"** o **"Command"**
   - O un campo llamado **"Comando de inicio"** o **"Start Command"**
   - O un campo llamado **"Entrypoint"**

### Opción 2: Pestaña "Variables de Entorno"

1. Ve al servicio `checkin24hs-dashboard`
2. Busca la pestaña **"Variables de Entorno"** o **"Environment"**
3. Puede haber un campo separado para el comando de inicio

### Opción 3: Pestaña "Configuración" o "Settings"

1. Ve al servicio `checkin24hs-dashboard`
2. Busca la pestaña **"Configuración"** o **"Settings"**
3. Busca un campo llamado **"Comando de inicio"**

### Opción 4: Menú Lateral o Desplegable

1. Busca un menú de 3 líneas (☰) en la parte superior
2. O busca pestañas en la parte superior: `[Fuente] [Variables] [Puertos] [Comando] [Logs]`
3. Haz clic en la pestaña **"Comando"** si existe

---

## ✅ Si NO Encuentras el Campo

**Esto es NORMAL si usas Dockerfile**. El comando ya está definido en el Dockerfile y EasyPanel lo usará automáticamente.

### Verificar que el Dockerfile Tiene el Comando

Tu `Dockerfile` debe tener esta línea al final:
```dockerfile
CMD ["node", "server.js"]
```

Si la tiene, **NO necesitas** configurar nada más en EasyPanel.

---

## 🔍 Cómo Verificar qué Comando se Está Usando

Ejecuta este comando en SSH para ver qué comando está usando el contenedor:

```bash
echo "🔍 Verificando comando de inicio..." && CONTAINER_ID=$(docker ps | grep checkin24hs_checkin24hs-dashboard | awk '{print $1}' | head -1) && echo "ID: $CONTAINER_ID" && echo "" && echo "Comando (CMD):" && docker inspect $CONTAINER_ID --format '{{.Config.Cmd}}' && echo "" && echo "Entrypoint:" && docker inspect $CONTAINER_ID --format '{{.Config.Entrypoint}}'
```

**Resultado esperado:**
- `Cmd`: `[node server.js]` o `[/bin/sh -c node server.js]`
- `Entrypoint`: puede estar vacío `[]` o ser `[/bin/sh -c]`

---

## 📝 Resumen

1. **Si usas Dockerfile** → El comando ya está en el Dockerfile, NO necesitas configurarlo en EasyPanel
2. **Si NO usas Dockerfile** → Busca el campo "Comando de inicio" en:
   - Sección "Compilación" (Build)
   - Pestaña "Variables de Entorno"
   - Pestaña "Configuración"
   - Menú lateral o pestañas superiores

---

## 🎯 Para tu Caso Específico

Como estás usando:
- **Tipo de compilación**: `Dockerfile` ✅
- **Archivo Dockerfile**: `Dockerfile` ✅

Y tu Dockerfile tiene:
```dockerfile
CMD ["node", "server.js"]
```

**NO necesitas buscar ni configurar el "Comando de inicio" en EasyPanel**. El Dockerfile ya lo define y EasyPanel lo usará automáticamente.

