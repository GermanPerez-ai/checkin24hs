# 📍 Cómo Configurar la Ruta de whatsapp-server.js en EasyPanel

## ✅ El Archivo Existe

El archivo está en: `whatsapp-server/whatsapp-server.js`

## 🔧 Opción 1: Configurar la Ruta de Compilación (RECOMENDADO)

En EasyPanel, en la sección **"Fuente"**:

1. **Ruta de compilación**: Cambia de `/` a `/whatsapp-server`
2. Esto le dice a EasyPanel que busque el código en la carpeta `whatsapp-server`

3. **Comando de inicio**: En la sección **"Compilación"**, en **"Comando de inicio"**, pon:
   ```
   node whatsapp-server.js
   ```

## 🔧 Opción 2: Mover el Archivo a la Raíz (ALTERNATIVA)

Si prefieres tener el archivo en la raíz del repositorio:

1. **Copia** `whatsapp-server/whatsapp-server.js` a la raíz del repositorio
2. **Sube** el cambio a GitHub
3. En EasyPanel, deja la **Ruta de compilación** como `/`
4. **Comando de inicio**: `node whatsapp-server.js`

## 🔧 Opción 3: Usar la Ruta Completa en el Comando

Si dejas la ruta de compilación como `/`, puedes usar la ruta completa en el comando:

1. **Ruta de compilación**: `/` (raíz)
2. **Comando de inicio**: 
   ```
   cd whatsapp-server && node whatsapp-server.js
   ```

## ✅ Recomendación

**Usa la Opción 1** (cambiar la ruta de compilación a `/whatsapp-server`):

1. Ve a **"Fuente"** en EasyPanel
2. Cambia **"Ruta de compilación"** de `/` a `/whatsapp-server`
3. Haz clic en **"Guardar"**
4. Ve a **"Compilación"**
5. En **"Comando de inicio"**, pon: `node whatsapp-server.js`
6. Haz clic en **"Guardar"**
7. Implementa el servicio

## 📋 Verificar que Funcione

Después de implementar, verifica en los logs que veas:
- ✅ "Servidor corriendo en puerto 3001"
- ✅ "Inicializando WhatsApp..."
- ❌ NO deberías ver "Cannot find module" o "File not found"

## 🆘 Si No Funciona

Si después de cambiar la ruta sigue sin funcionar:

1. Verifica que el archivo esté en GitHub en la carpeta `whatsapp-server`
2. Verifica que la rama sea `main`
3. Revisa los logs para ver el error exacto
4. Prueba la Opción 3 (usar `cd whatsapp-server && node whatsapp-server.js`)

