# 🔧 Aplicar Cambios de WhatsApp desde SSH

## 🎯 Objetivo

Aplicar los cambios que solucionan el problema de conflictos de sesión entre múltiples instancias de WhatsApp.

## 📋 Pasos a Ejecutar

### Paso 1: Conectarse por SSH

```bash
ssh root@72.61.58.240
```

### Paso 2: Ir al Directorio del Proyecto

```bash
cd ~/checkin24hs/whatsapp-server
```

### Paso 3: Verificar el Estado Actual

```bash
# Ver servicios corriendo
pm2 list

# Ver logs de whatsapp-1 para verificar el problema
pm2 logs whatsapp-1 --lines 20
```

### Paso 4: Hacer Backup del Archivo Actual

```bash
# Crear backup por si acaso
cp whatsapp-server.js whatsapp-server.js.backup.$(date +%Y%m%d_%H%M%S)
```

### Paso 5: Actualizar el Código

**Opción A: Si usas Git**

```bash
# Verificar cambios pendientes
git status

# Si hay cambios locales, guardarlos
git stash

# Actualizar desde GitHub
git pull origin main
```

**Opción B: Si NO usas Git (actualización manual)**

Necesitarás editar el archivo `whatsapp-server.js` manualmente. Los cambios necesarios son:

1. **Agregar función de limpieza de locks** (después de la línea 203)
2. **Cambiar el directorio de sesión** (línea 207)
3. **Mejorar manejo de errores** (al final del archivo)

### Paso 6: Verificar que los Cambios se Aplicaron

```bash
# Verificar que el archivo tiene los cambios
grep -n "sessionDataPath" whatsapp-server.js
grep -n "cleanChromeLocks" whatsapp-server.js
```

Deberías ver líneas como:
- `const sessionDataPath = \`.wwebjs_auth_${CONFIG.INSTANCE_NUMBER}\`;`
- `function cleanChromeLocks(dataPath) {`

### Paso 7: Detener los Servicios

```bash
# Detener todos los servicios de WhatsApp
pm2 stop all
```

### Paso 8: Limpiar Locks Antiguos (Opcional pero Recomendado)

```bash
# Eliminar directorios de sesión antiguos si existen
rm -rf .wwebjs_auth
rm -rf .wwebjs_auth_1
rm -rf .wwebjs_auth_2
rm -rf .wwebjs_auth_3
rm -rf .wwebjs_auth_4

# Verificar que se eliminaron
ls -la | grep wwebjs
```

### Paso 9: Reiniciar los Servicios

```bash
# Reiniciar todos los servicios
pm2 restart all

# O reiniciar individualmente
pm2 restart whatsapp-1
pm2 restart whatsapp-2
pm2 restart whatsapp-3
pm2 restart whatsapp-4
```

### Paso 10: Verificar que Funcionen Correctamente

```bash
# Ver estado de todos los servicios
pm2 list

# Ver logs de whatsapp-1 (deberías ver el nuevo mensaje)
pm2 logs whatsapp-1 --lines 30

# Verificar que cada instancia use su propio directorio
ls -la | grep wwebjs
```

**Deberías ver:**
- ✅ `.wwebjs_auth_1` (para instancia 1)
- ✅ `.wwebjs_auth_2` (para instancia 2)
- ✅ `.wwebjs_auth_3` (para instancia 3)
- ✅ `.wwebjs_auth_4` (para instancia 4)

### Paso 11: Verificar Logs

```bash
# Ver logs de cada instancia
pm2 logs whatsapp-1 --lines 20 | grep "directorio de sesión"
pm2 logs whatsapp-2 --lines 20 | grep "directorio de sesión"
pm2 logs whatsapp-3 --lines 20 | grep "directorio de sesión"
pm2 logs whatsapp-4 --lines 20 | grep "directorio de sesión"
```

**Deberías ver mensajes como:**
```
📁 Usando directorio de sesión: .wwebjs_auth_1 (Instancia 1)
📁 Usando directorio de sesión: .wwebjs_auth_2 (Instancia 2)
```

## ✅ Verificación Final

### Verificar que No Hay Errores de SingletonLock

```bash
# Verificar logs de errores
pm2 logs whatsapp-1 --err --lines 50 | grep -i "singleton\|lock\|failed"
```

**No deberías ver:**
- ❌ `Failed to create SingletonLock`
- ❌ `File exists`

### Verificar Estado de los Servicios

```bash
pm2 status
```

**Todos deberían estar:**
- ✅ `online` (no `errored` o `stopped`)
- ✅ Con CPU y memoria > 0

## 🆘 Si Algo Sale Mal

### Restaurar Backup

```bash
# Ver backups disponibles
ls -la *.backup*

# Restaurar el último backup
cp whatsapp-server.js.backup.* whatsapp-server.js

# Reiniciar servicios
pm2 restart all
```

### Ver Logs de Error

```bash
# Ver todos los errores
pm2 logs --err --lines 100

# Ver errores de una instancia específica
pm2 logs whatsapp-1 --err --lines 50
```

## 📝 Resumen de Cambios Aplicados

Los cambios que se aplicaron solucionan:

1. ✅ **Directorio de sesión único por instancia**: Cada instancia usa `.wwebjs_auth_1`, `.wwebjs_auth_2`, etc.
2. ✅ **Limpieza automática de locks**: Se eliminan locks de Chrome antes de iniciar
3. ✅ **Manejo seguro de errores**: No falla si el cliente es null al destruir

## 🎉 Resultado Esperado

Después de aplicar estos cambios:

- ✅ Cada instancia de WhatsApp usa su propio directorio de sesión
- ✅ No hay conflictos de `SingletonLock`
- ✅ Los servicios se inician correctamente
- ✅ Cada instancia puede generar su propio QR independientemente

