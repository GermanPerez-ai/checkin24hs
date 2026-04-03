# 🔍 Cómo Encontrar la Terminal en Easypanel

## Ubicaciones Comunes de la Terminal

### Opción 1: En el Panel Principal del Servicio
1. Ve a tu **proyecto/aplicación** en Easypanel
2. Haz clic en el **servicio de WhatsApp**
3. Busca estas pestañas en la parte superior:
   - **"Terminal"** o **"Shell"** o **"Console"**
   - **"Exec"** o **"Execute"**
   - **"Command"** o **"Run Command"**

### Opción 2: En el Menú Lateral
1. En el panel izquierdo, busca:
   - **"Terminal"**
   - **"Shell"**
   - **"Console"**
   - **"Execute"**

### Opción 3: En Configuración Avanzada
1. Ve a **"Settings"** o **"Configuración"**
2. Busca **"Advanced"** o **"Avanzado"**
3. Puede haber una opción de **"Terminal"** o **"Shell Access"**

### Opción 4: Botón de Acción
1. Busca un botón con icono de **terminal** o **"</>"** o **">_"**
2. Puede estar en la barra de herramientas superior

## Si NO Encuentras la Terminal

### Alternativa 1: File Manager
1. Busca **"Files"** o **"File Manager"** o **"Storage"**
2. Navega hasta encontrar la carpeta `.wwebjs_auth`
3. Elimínala desde ahí
4. Reinicia el servicio

### Alternativa 2: Variables de Entorno / Configuración
1. Ve a **"Environment"** o **"Variables"** o **"Config"**
2. Busca opciones de **"Restart"** o **"Reset"**
3. Puede haber una opción para limpiar datos

### Alternativa 3: Recrear el Servicio
1. Ve a **"Settings"** del servicio
2. Busca **"Delete"** o **"Remove"** (⚠️ CUIDADO)
3. Recrea el servicio (esto creará una sesión nueva)

### Alternativa 4: Usar SSH Directo
Si tienes acceso SSH al servidor:
```bash
ssh usuario@tu-servidor
# Luego ejecutar los comandos de limpieza
```

## Pasos Visuales Sugeridos

1. **Abre Easypanel** → Ve a tu proyecto
2. **Haz clic en el servicio de WhatsApp** (puede llamarse "whatsapp", "whatsapp-server", etc.)
3. **Mira las pestañas superiores:**
   ```
   [Overview] [Logs] [Terminal] [Settings] [Files]
   ```
4. **Si ves "Terminal"** → Haz clic ahí
5. **Si NO ves "Terminal"** → Busca "Files" o "Logs"

## Preguntas para Identificar tu Panel

¿Qué pestañas/opciones ves cuando abres tu servicio de WhatsApp en Easypanel?

- ¿Ves "Logs"?
- ¿Ves "Settings"?
- ¿Ves "Files" o "Storage"?
- ¿Ves algún botón con icono de terminal?
- ¿Hay un menú de tres puntos "..." con más opciones?

## Solución Rápida SIN Terminal

Si no encuentras la terminal, puedes:

1. **Reiniciar el servicio** (esto a veces limpia locks automáticamente):
   - Ve a "Services" → Busca tu servicio → "Restart"

2. **Ver los logs** para entender el error:
   - Ve a "Logs" → Copia el error completo

3. **Contactar soporte de Easypanel** para que eliminen la carpeta

## Comando para Copiar y Pegar (Cuando Encuentres la Terminal)

```bash
rm -rf .wwebjs_auth && echo "✅ Sesión eliminada" && echo "Ahora reinicia el servicio desde Easypanel"
```

