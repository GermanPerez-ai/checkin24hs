# 🔧 Solución: SCP Permission Denied

## 🚨 Problema

```
Permission denied (publickey,password).
Connection closed
```

**Causa**: Problema de autenticación con SCP.

---

## ✅ Soluciones

### Opción 1: Usar Clave SSH (Recomendado)

Si tienes una clave SSH configurada:

```powershell
# Especificar la clave SSH
scp -i C:\ruta\a\tu\clave_privada -r whatsapp-server root@72.61.58.240:/root/checkin24hs/
```

---

### Opción 2: Usar Git en el Servidor (Más Fácil)

En lugar de subir por SCP, puedes:

1. **Hacer commit y push desde tu máquina**:
   ```powershell
   cd C:\Users\German\Downloads\Checkin24hs
   git add whatsapp-server/
   git commit -m "Actualizar whatsapp-server"
   git push origin main
   ```

2. **En el servidor, hacer pull**:
   ```bash
   ssh root@72.61.58.240
   cd /root/checkin24hs
   git pull origin main
   ```

---

### Opción 3: Usar WinSCP o FileZilla (GUI)

Si prefieres una interfaz gráfica:

1. **Descarga WinSCP** o **FileZilla**
2. **Conéctate al servidor**:
   - Host: `72.61.58.240`
   - Usuario: `root`
   - Contraseña: (la que uses normalmente)
3. **Arrastra la carpeta** `whatsapp-server` al servidor

---

### Opción 4: Usar PowerShell con Credenciales

```powershell
# Crear objeto de credenciales
$cred = Get-Credential

# Usar SCP con credenciales (si tu versión lo soporta)
# O usar SSH con credenciales
```

---

### Opción 5: Subir Archivos por EasyPanel (Si Tiene Opción)

Algunas versiones de EasyPanel permiten subir archivos directamente:

1. **Ve a EasyPanel** → Servicio `whatsapp`
2. **Ve a "Fuente"** → Busca opción **"Subir"** o **"Upload"**
3. **Sube los archivos** directamente

---

## 🎯 Recomendación: Usar Git (Opción 2)

**La más fácil y confiable**:

### Paso 1: Desde tu máquina (PowerShell)

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Verificar cambios
git status

# Agregar cambios
git add whatsapp-server/

# Commit
git commit -m "Actualizar whatsapp-server para nueva configuración simple"

# Push
git push origin main
```

### Paso 2: En el servidor (SSH)

```bash
ssh root@72.61.58.240

cd /root/checkin24hs
git pull origin main

# Verificar que se actualizó
cd whatsapp-server
ls -la
```

### Paso 3: Construir imagen Docker

```bash
cd /root/checkin24hs/whatsapp-server
docker build -t whatsapp-server:latest .
```

---

## 🔍 Verificar Autenticación SSH

Si quieres seguir usando SCP, verifica:

1. **¿Tienes clave SSH configurada?**
   ```powershell
   # Verificar si tienes claves SSH
   ls ~/.ssh/
   ```

2. **¿Conoces la contraseña del servidor?**
   - Asegúrate de usar la contraseña correcta
   - Puede que necesites usar `-o PreferredAuthentications=password`

---

## ✅ Solución Rápida: Usar Git

**La forma más fácil** es usar Git (como haces con dashboard y cotizador):

1. **Commit y push desde tu máquina**
2. **Pull en el servidor**
3. **Construir imagen Docker en el servidor**

Esto evita problemas de autenticación con SCP.

---

## 🚀 Pasos Rápidos con Git

### En tu máquina:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
git add whatsapp-server/
git commit -m "Actualizar whatsapp-server"
git push origin main
```

### En el servidor:

```bash
ssh root@72.61.58.240
cd /root/checkin24hs
git pull origin main
cd whatsapp-server
docker build -t whatsapp-server:latest .
```

---

¿Prefieres usar Git (más fácil) o solucionar el problema de SCP?
