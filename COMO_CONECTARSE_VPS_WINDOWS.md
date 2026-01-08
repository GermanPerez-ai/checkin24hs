# 🔌 Cómo Conectarse al VPS desde Windows

## 📋 Requisitos

Antes de conectarte, necesitas:
- ✅ **IP del VPS** (ejemplo: `123.45.67.89`)
- ✅ **Usuario** (generalmente `root` o el que te dio el proveedor)
- ✅ **Contraseña** o **SSH Key**

## 🎯 Opción 1: Usar PowerShell (Recomendado)

### Paso 1: Abrir PowerShell

1. **Presiona** `Windows + X`
2. **Haz clic en** "Windows PowerShell" o "Terminal"
3. O busca "PowerShell" en el menú inicio

### Paso 2: Conectarte

Escribe este comando (reemplaza con tus datos):

```bash
ssh root@TU_IP
```

**Ejemplo**:
```bash
ssh root@123.45.67.89
```

### Paso 3: Aceptar la Conexión

La primera vez te preguntará:
```
The authenticity of host '123.45.67.89' can't be established.
Are you sure you want to continue connecting (yes/no)?
```

Escribe: `yes` y presiona Enter

### Paso 4: Ingresar Contraseña

Te pedirá la contraseña:
```
root@123.45.67.89's password:
```

**Escribe tu contraseña** (no verás lo que escribes, es normal)
Presiona Enter

### ✅ Si Funciona

Deberías ver algo como:
```
Welcome to Ubuntu 22.04 LTS
root@servidor:~#
```

¡Estás conectado!

## 🎯 Opción 2: Usar PuTTY (Alternativa)

Si PowerShell no funciona:

### Paso 1: Descargar PuTTY

1. Ve a: https://www.putty.org/
2. Descarga PuTTY
3. Instálalo

### Paso 2: Configurar PuTTY

1. **Abre PuTTY**
2. **Host Name**: Escribe la IP de tu VPS
3. **Port**: `22` (debe estar así)
4. **Connection type**: SSH (debe estar seleccionado)
5. **Haz clic en "Open"**

### Paso 3: Conectar

1. Te pedirá aceptar la conexión → **"Yes"**
2. Te pedirá usuario → Escribe `root` (o tu usuario)
3. Te pedirá contraseña → Escribe tu contraseña

## 🎯 Opción 3: Usar CMD (Command Prompt)

### Paso 1: Abrir CMD

1. Presiona `Windows + R`
2. Escribe: `cmd`
3. Presiona Enter

### Paso 2: Conectarte

```bash
ssh root@TU_IP
```

Sigue los mismos pasos que en PowerShell

## 🔑 Si Usas SSH Key (Sin Contraseña)

Si tu proveedor te dio un archivo `.pem` o `.key`:

### En PowerShell:

```bash
ssh -i ruta/al/archivo.pem root@TU_IP
```

**Ejemplo**:
```bash
ssh -i C:\Users\German\Downloads\mi-vps-key.pem root@123.45.67.89
```

## ❌ Problemas Comunes

### Error: "ssh: command not found"

**Solución**: Windows 10/11 tiene SSH incluido, pero si no funciona:
1. Ve a **Configuración** → **Aplicaciones** → **Características opcionales**
2. Busca **"Cliente OpenSSH"**
3. Instálalo si no está instalado

### Error: "Connection refused"

**Posibles causas**:
- ❌ El VPS no está encendido
- ❌ El puerto 22 está bloqueado
- ❌ La IP es incorrecta

**Solución**: Verifica con tu proveedor de VPS

### Error: "Permission denied"

**Posibles causas**:
- ❌ Contraseña incorrecta
- ❌ Usuario incorrecto

**Solución**: Verifica usuario y contraseña con tu proveedor

### No Veo la Contraseña al Escribir

**Es normal**: Por seguridad, las contraseñas no se muestran al escribir en SSH
- Escribe la contraseña normalmente
- Presiona Enter
- Si es incorrecta, te pedirá de nuevo

## 📋 Checklist

Antes de conectarte, verifica:

- [ ] Tienes la **IP del VPS**
- [ ] Tienes el **usuario** (generalmente `root`)
- [ ] Tienes la **contraseña** o **SSH Key**
- [ ] El **VPS está encendido** (verifica en el panel de tu proveedor)
- [ ] Tienes **acceso a Internet**

## 🎯 Próximos Pasos

Una vez conectado:

1. **Dime "listo"** o **"conectado"**
2. Te daré los **comandos para instalar todo**
3. Te guiaré **paso a paso**

## 💡 Información que Necesito

Para ayudarte mejor, dime:

1. **¿Qué proveedor de VPS usas?** (DigitalOcean, Vultr, Hetzner, etc.)
2. **¿Tienes la IP del VPS?**
3. **¿Tienes usuario y contraseña?**
4. **¿Puedes acceder al panel de tu proveedor?**

¡Dime cuando estés listo para conectarte o si tienes algún problema!

