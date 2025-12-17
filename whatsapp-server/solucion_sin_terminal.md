# 🚀 Solución SIN Terminal - Easypanel

Si no encuentras la terminal en Easypanel, aquí hay alternativas:

## Método 1: Reiniciar el Servicio (Más Fácil)

1. Ve a **Easypanel** → Tu proyecto
2. Haz clic en tu **servicio de WhatsApp**
3. Busca el botón **"Restart"** o **"Reiniciar"**
4. Haz clic en reiniciar
5. Ve a **"Logs"** para ver si aparece el QR

**Nota:** A veces reiniciar limpia los locks automáticamente.

## Método 2: File Manager

1. En Easypanel, busca **"Files"** o **"Storage"** o **"Volumes"**
2. Navega hasta encontrar tu aplicación
3. Busca la carpeta `.wwebjs_auth`
4. Elimínala
5. Reinicia el servicio

## Método 3: Recrear el Servicio (Último Recurso)

⚠️ **Esto eliminará todo, pero es efectivo:**

1. Ve a **Settings** de tu servicio
2. Busca **"Delete"** o **"Remove Service"**
3. Elimina el servicio
4. Crea uno nuevo con la misma configuración
5. La sesión será nueva y mostrará el QR

## Método 4: Contactar Soporte

Si nada funciona:
1. Contacta al soporte de Easypanel
2. Pídeles que eliminen la carpeta `.wwebjs_auth` de tu servicio
3. O que reinicien el servicio con limpieza de locks

## Método 5: Usar SSH (Si Tienes Acceso)

Si tienes acceso SSH al servidor donde está Easypanel:

```bash
# Conectarte
ssh usuario@tu-servidor

# Encontrar el contenedor
docker ps | grep whatsapp

# Eliminar la sesión
docker exec NOMBRE_CONTENEDOR rm -rf .wwebjs_auth

# Reiniciar
docker restart NOMBRE_CONTENEDOR
```

## Verificación

Después de cualquier método, ve a **"Logs"** en Easypanel y deberías ver:

```
📱 Escanea el código QR con WhatsApp:
```

## ¿Qué Método Prefieres Intentar?

1. **Reiniciar el servicio** (más fácil, prueba primero)
2. **File Manager** (si lo encuentras)
3. **Recrear servicio** (si nada más funciona)
4. **SSH** (si tienes acceso)

