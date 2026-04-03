# 🚀 Guía Paso a Paso: Actualizar Servidor con WhatsApp

## 📍 Paso 1: Conectarse al Servidor

Abre tu terminal/SSH y ejecuta:

```bash
ssh root@srv1152402
```

**¿Qué esperar?**
- Te pedirá tu contraseña (si no tienes SSH key configurada)
- Verás el prompt: `root@srv1152402:~#`

**✅ Cuando veas el prompt del servidor, avísame y continuamos con el Paso 2**

---

## 📍 Paso 2: Ir al Directorio del Proyecto

Una vez conectado, ejecuta:

```bash
cd ~/checkin24hs
```

**Verifica que estás en el lugar correcto:**
```bash
pwd
```

**Deberías ver:** `/root/checkin24hs`

**✅ Cuando estés en el directorio correcto, avísame y continuamos**

---

## 📍 Paso 3: Verificar Estado Actual de Git

Antes de actualizar, veamos qué tenemos:

```bash
git status
```

**¿Qué esperar?**
- Puede decir "Your branch is up to date" o mostrar cambios pendientes
- Esto es normal

**✅ Avísame qué muestra y continuamos**

---

## 📍 Paso 4: Actualizar desde GitHub

Ahora vamos a traer los cambios:

```bash
git pull origin main
```

**¿Qué esperar?**
- Puede pedirte credenciales (username y token)
- O puede actualizar directamente si ya tienes credenciales guardadas
- Verás mensajes como "Updating..." o "Already up to date"

**✅ Avísame qué resultado obtienes**

---

## 📍 Paso 5: Verificar que el Script Existe

Verifica que el script de actualización está presente:

```bash
ls -lh ACTUALIZAR_ARCHIVO_SERVIDOR.sh
```

**¿Qué esperar?**
- Deberías ver el archivo con permisos (ej: `-rwxr-xr-x`)

**✅ Avísame si el archivo existe**

---

## 📍 Paso 6: Hacer el Script Ejecutable

```bash
chmod +x ACTUALIZAR_ARCHIVO_SERVIDOR.sh
```

**¿Qué esperar?**
- No debería mostrar ningún mensaje (éxito silencioso)

**✅ Avísame cuando lo hayas ejecutado**

---

## 📍 Paso 7: Ejecutar el Script de Actualización

Este es el paso importante:

```bash
./ACTUALIZAR_ARCHIVO_SERVIDOR.sh
```

**¿Qué esperar?**
- El script descargará `dashboard.html` desde GitHub
- Creará un backup
- Detectará el contenedor automáticamente
- Copiará el archivo
- Verificará el build number
- Te preguntará si quieres reiniciar el contenedor

**✅ Avísame qué mensajes ves y qué pregunta te hace al final**

---

## 📍 Paso 8: Reiniciar el Contenedor (Recomendado)

Cuando el script pregunte:
```
¿Deseas reiniciar el contenedor ahora? (y/n):
```

**Responde:** `y` y presiona Enter

**¿Qué esperar?**
- El contenedor se reiniciará
- Verás mensajes sobre el reinicio

**✅ Avísame cuando termine el reinicio**

---

## 📍 Paso 9: Verificar la Actualización

Verifica que el build number sea #38:

```bash
grep "DASHBOARD_BUILD_NUMBER" dashboard.html | head -1
```

**¿Qué esperar?**
- Deberías ver algo como: `window.DASHBOARD_BUILD_NUMBER = 38;`

**✅ Avísame qué número ves**

---

## 📍 Paso 10: Probar en el Navegador

1. Abre tu navegador
2. Ve a: `https://checkin24hs.com`
3. Busca la sección de WhatsApp
4. Configura la URL del servidor: `https://checkin24hs.com`
5. Intenta conectar una instancia

**✅ Avísame si ves el QR code o si hay algún error**

---

## 🆘 Si Algo Sale Mal

Si en cualquier paso hay un error:

1. **Copia el mensaje de error completo**
2. **Avísame en qué paso estabas**
3. **No continúes hasta que te diga qué hacer**

---

## ✅ Checklist Final

- [ ] Conectado al servidor
- [ ] En el directorio ~/checkin24hs
- [ ] Git pull completado
- [ ] Script ejecutado exitosamente
- [ ] Contenedor reiniciado
- [ ] Build number verificado (#38)
- [ ] Dashboard accesible en el navegador
- [ ] Sección WhatsApp visible
- [ ] QR code aparece al conectar
