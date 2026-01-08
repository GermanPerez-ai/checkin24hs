# 🔧 Solución: Hostname No Se Resuelve

## ❌ Problema

```
ssh: Could not resolve hostname srv1152402: Host desconocido.
```

Windows no puede resolver el hostname `srv1152402`.

---

## ✅ Solución 1: Usar la IP Directamente (Más Rápido)

En lugar de usar `srv1152402`, usa la **IP del servidor**.

### Paso 1: Obtener la IP del servidor

**Opción A: Desde EasyPanel**
1. Ve a EasyPanel
2. Busca información del servidor
3. Anota la IP pública

**Opción B: Si ya la conoces**
- La IP que usaste antes para conectarte al servidor

### Paso 2: Usar la IP en los comandos

**Reemplaza `srv1152402` con la IP:**

```powershell
# Ejemplo con IP (reemplaza con tu IP real)
scp dashboard.html root@72.61.58.240:/tmp/dashboard.html
ssh root@72.61.58.240
```

---

## ✅ Solución 2: Configurar Hostname en Windows

Si prefieres usar el hostname, agrégalo al archivo `hosts` de Windows.

### Paso 1: Abrir el archivo hosts como Administrador

1. **Abre PowerShell como Administrador:**
   - Click derecho en PowerShell
   - "Ejecutar como administrador"

2. **Abre el archivo hosts:**
   ```powershell
   notepad C:\Windows\System32\drivers\etc\hosts
   ```

### Paso 2: Agregar la entrada

**Agrega esta línea al final del archivo:**
```
72.61.58.240    srv1152402
```

**Reemplaza `72.61.58.240` con la IP real de tu servidor.**

### Paso 3: Guardar y probar

1. **Guarda el archivo** (Ctrl+S)
2. **Cierra Notepad**
3. **Prueba el comando:**
   ```powershell
   ssh root@srv1152402
   ```

---

## ✅ Solución 3: Usar WinSCP (Más Fácil)

Si `scp` no funciona, usa WinSCP:

1. **Descarga WinSCP:** https://winscp.net/
2. **Instala y abre WinSCP**
3. **Conecta al servidor:**
   - **Host:** `72.61.58.240` (o tu IP)
   - **Usuario:** `root`
   - **Contraseña:** (la de tu servidor)
   - **Protocolo:** SFTP
4. **Arrastra `dashboard.html`** a `/tmp/` en el servidor
5. **Luego conecta por SSH** y ejecuta el script

---

## 🔍 Cómo Encontrar la IP del Servidor

### Desde EasyPanel:

1. Ve a EasyPanel
2. Busca "Servidores" o "Servers"
3. Busca tu servidor `srv1152402`
4. Anota la IP pública

### Desde el servidor (si ya tienes acceso):

Si ya tienes acceso al servidor por otra vía, ejecuta:
```bash
hostname -I
# O
ip addr show
```

---

## 📝 Comandos Corregidos

**Una vez que tengas la IP, usa estos comandos:**

```powershell
# 1. Subir archivo (reemplaza con tu IP)
scp dashboard.html root@TU_IP_AQUI:/tmp/dashboard.html

# 2. Conectarse (reemplaza con tu IP)
ssh root@TU_IP_AQUI
```

**Ejemplo con IP:**
```powershell
scp dashboard.html root@72.61.58.240:/tmp/dashboard.html
ssh root@72.61.58.240
```

---

## 💡 Recomendación

**Usa la Solución 1 (IP directa)** - es la más rápida y no requiere configuración adicional.

Si necesitas ayuda para encontrar la IP, comparte:
- ¿Tienes acceso a EasyPanel?
- ¿Recuerdas la IP que usaste antes?
- ¿Tienes algún documento con la información del servidor?

