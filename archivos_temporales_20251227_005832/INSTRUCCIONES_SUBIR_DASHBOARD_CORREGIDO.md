# 📋 Instrucciones para Subir dashboard.html Corregido

## 🔍 Situación Actual

Estás en el servidor (`root@srv1152402`) y necesitas subir el archivo `dashboard.html` corregido desde tu máquina Windows local.

---

## 🚀 Opción 1: Desde tu Máquina Windows (PowerShell)

### Paso 1: Abre PowerShell en tu computadora Windows

### Paso 2: Ejecuta estos comandos:

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Subir dashboard.html
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html
```

**Nota:** Te pedirá la contraseña del servidor.

---

## 🚀 Opción 2: Desde el Servidor (si ya tienes el archivo ahí)

Si ya tienes el archivo en el servidor en otra ubicación, puedes copiarlo:

```bash
# Si el archivo está en /tmp/
cp /tmp/dashboard.html /root/checkin24hs/deploy/dashboard.html

# O desde donde esté
cp /ruta/al/archivo/dashboard.html /root/checkin24hs/deploy/dashboard.html
```

---

## 🚀 Opción 3: Usar WinSCP (Más Fácil)

1. **Abre WinSCP** en tu computadora Windows
2. **Conecta al servidor:**
   - Host: `72.61.58.240`
   - Usuario: `root`
   - Contraseña: (tu contraseña)
3. **Navega a:**
   - Local: `C:\Users\German\Downloads\Checkin24hs\deploy\`
   - Remoto: `/root/checkin24hs/deploy/`
4. **Arrastra** `dashboard.html` desde local a remoto

---

## 🔧 Después de Subir el Archivo

### Si hay un contenedor Docker:

```bash
# Encontrar contenedor
docker ps | grep dashboard

# Copiar al contenedor (reemplaza <contenedor> con el nombre real)
docker cp /root/checkin24hs/deploy/dashboard.html <contenedor>:/usr/share/nginx/html/dashboard.html

# Reiniciar contenedor
docker restart <contenedor>
```

### Si hay un servicio PM2:

```bash
# Reiniciar servicio
pm2 restart dashboard

# Ver logs
pm2 logs dashboard --lines 20
```

---

## ✅ Verificar que Funcionó

1. **Abre en el navegador:**
   - https://dashboard.checkin24hs.com/

2. **Limpia la caché:**
   - Presiona `Ctrl + Shift + R` (hard refresh)
   - O abre en modo incógnito

3. **Abre la consola (F12):**
   - Verifica que NO aparezcan errores de `searchUsers` o `showSection`

---

## 📝 Nota Importante

El comando que intentaste ejecutar:
```bash
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html
```

**Problemas:**
1. Estás en el servidor, no en tu máquina Windows
2. Usaste `\` (backslash) que es sintaxis de Windows, pero estás en Linux
3. Estás intentando copiar desde el servidor al mismo servidor

**Solución:** Ejecuta el comando `scp` desde tu máquina Windows, no desde el servidor.




