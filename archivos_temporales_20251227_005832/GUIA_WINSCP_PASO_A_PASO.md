# 📤 Guía Paso a Paso: Subir Scripts con WinSCP

## ✅ Paso 1: Descargar WinSCP (si no lo tienes)

1. **Abre tu navegador** y ve a: https://winscp.net/eng/download.php
2. **Haz clic en "Download"** (botón verde)
3. **Ejecuta el instalador** que descargaste
4. **Sigue el asistente de instalación** (acepta los valores por defecto)
5. **Abre WinSCP** desde el menú de inicio

---

## ✅ Paso 2: Conectarte al Servidor

1. **En la pantalla de login de WinSCP**, verás estos campos:

   ```
   Protocolo: [SFTP ▼]
   Nombre de host: [72.61.58.240]
   Puerto: [22]
   Nombre de usuario: [root]
   Contraseña: [********]
   ```

2. **Llena los campos:**
   - **Protocolo**: Deja `SFTP` (o selecciona `SCP` si prefieres)
   - **Nombre de host**: `72.61.58.240`
   - **Puerto**: `22` (debería estar por defecto)
   - **Nombre de usuario**: `root`
   - **Contraseña**: Ingresa tu contraseña del servidor

3. **Haz clic en "Iniciar sesión"** (botón en la parte inferior)

4. **Si aparece una ventana de "Advertencia de clave de host":**
   - Haz clic en **"Sí"** o **"Aceptar"**
   - Esto es normal la primera vez que te conectas

5. **Espera a que se conecte** (verás una barra de progreso)

---

## ✅ Paso 3: Navegar a las Carpetas Correctas

### Panel Izquierdo (Tu Computadora):

1. **En el panel izquierdo**, verás tu sistema de archivos local
2. **Navega a la carpeta** donde están los scripts:
   - Haz clic en `C:` → `Users` → `German` → `Downloads` → `Checkin24hs`
   - O escribe en la barra de direcciones: `C:\Users\German\Downloads\Checkin24hs`
3. **Deberías ver estos archivos:**
   - `actualizar_webmail_traefik.sh`
   - `actualizar_dashboard_traefik.sh`

### Panel Derecho (Servidor):

1. **En el panel derecho**, verás el sistema de archivos del servidor
2. **Navega a `/root/`:**
   - Haz clic en la barra de direcciones superior
   - Escribe: `/root/`
   - Presiona `Enter`
3. **Deberías ver** la carpeta vacía o con algunos archivos

---

## ✅ Paso 4: Subir los Archivos

### Método 1: Arrastrar y Soltar (Más Fácil)

1. **En el panel izquierdo**, selecciona los dos archivos:
   - `actualizar_webmail_traefik.sh`
   - `actualizar_dashboard_traefik.sh`
   
   **Para seleccionar ambos:**
   - Haz clic en el primero
   - Mantén presionada la tecla `Ctrl`
   - Haz clic en el segundo
   - Suelta `Ctrl`

2. **Arrastra los archivos seleccionados** desde el panel izquierdo al panel derecho (a la carpeta `/root/`)

3. **Suelta el mouse** cuando estés sobre el panel derecho

4. **Espera a que termine la transferencia** (verás una barra de progreso)

### Método 2: Clic Derecho (Alternativa)

1. **En el panel izquierdo**, haz clic derecho en `actualizar_webmail_traefik.sh`
2. **Selecciona "Cargar"** o **"Upload"**
3. **Confirma** que va a `/root/`
4. **Repite** para `actualizar_dashboard_traefik.sh`

---

## ✅ Paso 5: Verificar que los Archivos Están en el Servidor

1. **En el panel derecho** (servidor), deberías ver:
   - `actualizar_webmail_traefik.sh`
   - `actualizar_dashboard_traefik.sh`

2. **Si no los ves**, actualiza la vista:
   - Haz clic derecho en el panel derecho
   - Selecciona "Actualizar" o presiona `F5`

---

## ✅ Paso 6: Hacer los Archivos Ejecutables

### Opción A: Desde la Interfaz de WinSCP

1. **En el panel derecho** (servidor), haz clic derecho en `actualizar_webmail_traefik.sh`

2. **Selecciona "Propiedades"** o **"Properties"** (última opción del menú)

3. **En la ventana de propiedades:**
   - Busca la sección **"Permisos"** o **"Permissions"**
   - Marca la casilla **"Ejecutable"** o **"Executable"** (puede estar como `x` en los permisos)
   - O marca las casillas: **"Ejecutar"** para Propietario, Grupo y Otros
   - Haz clic en **"OK"**

4. **Repite el proceso** para `actualizar_dashboard_traefik.sh`

### Opción B: Desde la Terminal (Más Confiable)

1. **Abre la terminal en WinSCP:**
   - Haz clic en el botón **"Terminal"** en la barra superior (icono de terminal/consola)
   - O ve al menú: **Comandos** → **Abrir terminal**
   - O presiona `Ctrl+P`

2. **En la terminal que se abre**, ejecuta:
   ```bash
   chmod +x /root/actualizar_webmail_traefik.sh
   chmod +x /root/actualizar_dashboard_traefik.sh
   ```

3. **Deberías ver** que los comandos se ejecutan sin errores

---

## ✅ Paso 7: Verificar que los Scripts Son Ejecutables

1. **En la terminal de WinSCP**, ejecuta:
   ```bash
   ls -la /root/actualizar_*.sh
   ```

2. **Deberías ver algo como:**
   ```
   -rwxr-xr-x 1 root root 1234 Dec 20 12:00 actualizar_dashboard_traefik.sh
   -rwxr-xr-x 1 root root 1234 Dec 20 12:00 actualizar_webmail_traefik.sh
   ```

3. **La `x` en `rwxr-xr-x`** indica que son ejecutables ✅

---

## ✅ Paso 8: Probar los Scripts

1. **En la terminal de WinSCP**, ejecuta:
   ```bash
   /root/actualizar_webmail_traefik.sh
   ```

2. **Deberías ver** un mensaje como:
   ```
   🔍 Obteniendo IP actual del contenedor webmail...
   ✅ IP actual del webmail: 10.11.132.XX
   📦 Backup creado: /etc/easypanel/traefik/config/main.yaml.backup.XXXXXX
   🔧 Actualizando configuración de Traefik...
   ✅ Verificando configuración actualizada...
   ...
   ✅ ¡Configuración actualizada!
   ```

3. **Si ves errores**, comparte el mensaje de error

---

## ✅ Paso 9: Probar el Dashboard (Opcional)

1. **En la terminal**, ejecuta:
   ```bash
   /root/actualizar_dashboard_traefik.sh
   ```

2. **Verifica** que funciona correctamente

---

## 🎉 ¡Listo!

Ahora tienes los scripts instalados en el servidor. Cada vez que reinicies el servicio `webmail` o `dashboard`:

1. **Ejecuta el script correspondiente** en la terminal:
   ```bash
   /root/actualizar_webmail_traefik.sh
   # O
   /root/actualizar_dashboard_traefik.sh
   ```

2. **Espera 10-15 segundos**

3. **Prueba** el servicio en tu navegador

---

## 🆘 Solución de Problemas

### Problema: No puedo conectarme al servidor
- **Solución**: Verifica que tengas la IP correcta (`72.61.58.240`) y la contraseña correcta

### Problema: No veo la carpeta `/root/`
- **Solución**: Escribe `/root/` en la barra de direcciones del panel derecho y presiona `Enter`

### Problema: Los archivos no se suben
- **Solución**: Verifica que tengas permisos de escritura en `/root/`. Si no, intenta subirlos a `/tmp/` y luego muévelos con la terminal

### Problema: No puedo hacer los archivos ejecutables desde la interfaz
- **Solución**: Usa la terminal (Opción B del Paso 6) con el comando `chmod +x`

### Problema: El script no se ejecuta
- **Solución**: Verifica que tenga permisos de ejecución: `ls -la /root/actualizar_*.sh` y deberías ver `x` en los permisos

---

## 📝 Resumen de Comandos Útiles

```bash
# Verificar que los archivos están ahí
ls -la /root/actualizar_*.sh

# Hacer ejecutables (si no lo hiciste antes)
chmod +x /root/actualizar_webmail_traefik.sh
chmod +x /root/actualizar_dashboard_traefik.sh

# Probar el script de webmail
/root/actualizar_webmail_traefik.sh

# Probar el script de dashboard
/root/actualizar_dashboard_traefik.sh
```

