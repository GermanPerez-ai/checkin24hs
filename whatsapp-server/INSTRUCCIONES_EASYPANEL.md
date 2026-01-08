# 🎛️ Instrucciones para Limpiar Sesión de WhatsApp en Easypanel

## Método 1: Usando el Terminal de Easypanel (Recomendado)

### Paso 1: Acceder al Terminal
1. Ve a tu panel de Easypanel
2. Selecciona tu proyecto/aplicación de WhatsApp
3. Busca la pestaña **"Terminal"** o **"Shell"**
4. Haz clic para abrir el terminal

### Paso 2: Ejecutar Comandos de Limpieza

En el terminal de Easypanel, ejecuta:

```bash
# Ir al directorio del servidor (si es necesario)
cd /app  # o la ruta donde está tu servidor

# Eliminar la sesión bloqueada
rm -rf .wwebjs_auth

# O si está en una ruta específica
rm -rf /app/.wwebjs_auth
```

### Paso 3: Reiniciar el Servicio
1. Ve a la sección **"Services"** o **"Servicios"**
2. Encuentra tu servicio de WhatsApp
3. Haz clic en **"Restart"** o **"Reiniciar"**

### Paso 4: Ver Logs
1. Ve a la pestaña **"Logs"**
2. Deberías ver el código QR aparecer en los logs

## Método 2: Usando File Manager (Si está disponible)

### Paso 1: Acceder al File Manager
1. En Easypanel, busca la opción **"Files"** o **"File Manager"**
2. Navega a la carpeta de tu aplicación de WhatsApp

### Paso 2: Eliminar la Carpeta
1. Busca la carpeta `.wwebjs_auth`
2. Elimínala (botón derecho > Delete o arrastrar a la papelera)

### Paso 3: Reiniciar
1. Ve a **"Services"** > **"Restart"**

## Método 3: Usando Variables de Entorno o Configuración

Si Easypanel tiene opciones de configuración:

1. Ve a **"Settings"** o **"Environment"**
2. Busca opciones relacionadas con **"Restart"** o **"Reset"**
3. Reinicia el servicio

## Método 4: Recrear el Servicio (Último Recurso)

Si nada funciona:

1. Ve a **"Settings"** de tu servicio
2. Busca **"Delete"** o **"Remove"**
3. **⚠️ CUIDADO:** Esto eliminará todo, pero puedes recrearlo
4. Crea un nuevo servicio con la misma configuración
5. La sesión se creará nueva y mostrará el QR

## Verificación

Después de reiniciar, en los **Logs** deberías ver:

```
📱 Escanea el código QR con WhatsApp:
WhatsApp > Dispositivos vinculados > Vincular dispositivo
```

## Comandos Útiles para el Terminal de Easypanel

```bash
# Ver procesos corriendo
ps aux | grep node

# Ver estructura de directorios
ls -la

# Buscar la carpeta de sesión
find . -name ".wwebjs_auth" -type d

# Ver logs en tiempo real (si tienes acceso)
tail -f logs/*.log

# Verificar que el servidor está corriendo
netstat -tulpn | grep 3001
```

## Notas Importantes

- ⚠️ **Eliminar `.wwebjs_auth`** hará que necesites escanear el QR nuevamente
- ✅ La sesión se guarda dentro del contenedor/volumen de Easypanel
- 🔄 Reiniciar el servicio aplica los cambios
- 📱 El QR aparecerá en los logs del servicio

## Si el Terminal no está Disponible

Si Easypanel no tiene terminal, puedes:

1. **Usar SSH** (si tienes acceso):
   ```bash
   ssh usuario@tu-servidor
   # Luego seguir los pasos del Método 1
   ```

2. **Contactar soporte** de Easypanel para que eliminen la carpeta

3. **Recrear el servicio** completamente

