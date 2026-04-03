# 🔑 Encontrar Contraseña Root en EasyPanel

## 🎯 Métodos para Acceder al Servidor

### Opción 1: Ver Contraseña en EasyPanel (Si está disponible)

1. **Ve a EasyPanel** → Panel principal
2. **Busca la sección "Servidores"** o **"Servers"**
3. **Haz clic en tu servidor** (IP: `72.61.58.240`)
4. **Busca pestañas como**:
   - **"Configuración"** o **"Settings"**
   - **"Seguridad"** o **"Security"**
   - **"SSH"** o **"Acceso"**
5. **Busca campos como**:
   - **"Contraseña Root"** o **"Root Password"**
   - **"SSH Password"**
   - **"Show Password"** (botón para revelar)

---

### Opción 2: Resetear Contraseña desde EasyPanel

1. **Ve a EasyPanel** → **"Servidores"** o **"Servers"**
2. **Selecciona tu servidor** (`72.61.58.240`)
3. **Busca opciones como**:
   - **"Reset Password"** o **"Resetear Contraseña"**
   - **"Change Root Password"**
   - **"Regenerar Contraseña"**
4. **Haz clic y copia la nueva contraseña** (se muestra una vez)

---

### Opción 3: Usar Clave SSH (Si está configurada)

Si EasyPanel tiene una clave SSH configurada:

1. **Ve a EasyPanel** → **"Servidores"** → Tu servidor
2. **Busca "SSH Keys"** o **"Claves SSH"**
3. **Descarga la clave privada** (si está disponible)
4. **Úsala con SCP**:
   ```powershell
   scp -i C:\ruta\a\clave_privada -r whatsapp-server root@72.61.58.240:/root/checkin24hs/
   ```

---

### Opción 4: Acceder por Consola Web de EasyPanel

Muchos paneles tienen una **consola web** o **terminal integrado**:

1. **Ve a EasyPanel** → **"Servidores"** → Tu servidor
2. **Busca botones como**:
   - **"Terminal"** o **"Console"**
   - **"Web SSH"** o **"SSH Terminal"**
   - **"Acceso Directo"**
3. **Abre la consola** (se conecta automáticamente)
4. **Desde ahí puedes ejecutar comandos** sin necesidad de contraseña

---

### Opción 5: Usar Git (Sin Necesidad de SSH)

**La forma más fácil**: Usar Git directamente desde tu máquina:

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Verificar cambios
git status

# Agregar cambios
git add whatsapp-server/

# Commit
git commit -m "Actualizar whatsapp-server para nueva configuración simple"

# Push (esto NO requiere contraseña del servidor)
git push origin main
```

Luego, **desde la consola web de EasyPanel** (que no requiere contraseña):

```bash
cd /root/checkin24hs
git pull origin main
cd whatsapp-server
docker build -t whatsapp-server:latest .
```

---

## 🔍 Dónde Buscar en EasyPanel

### Ubicaciones Comunes:

1. **Panel Principal** → **"Servidores"** → Tu servidor → **"Configuración"**
2. **Panel Principal** → **"Servidores"** → Tu servidor → **"Seguridad"**
3. **Panel Principal** → **"Servidores"** → Tu servidor → **"SSH"**
4. **Panel Principal** → **"Servidores"** → Tu servidor → **"Acceso"**
5. **Panel Principal** → **"Servidores"** → Tu servidor → **"Detalles"** → Scroll down

---

## 🎯 Recomendación: Usar Consola Web + Git

**El método más fácil**:

1. **Desde tu máquina**: `git add`, `git commit`, `git push` (sin contraseña)
2. **Desde consola web de EasyPanel**: `git pull` y `docker build` (sin contraseña SSH)

---

## 📝 Pasos Detallados: Consola Web EasyPanel

1. **Abre EasyPanel** en tu navegador
2. **Ve a "Servidores"** o **"Servers"**
3. **Haz clic en tu servidor** (`72.61.58.240`)
4. **Busca el botón "Terminal"**, **"Console"**, o **"Web SSH"**
5. **Haz clic** → Se abre una terminal en el navegador
6. **Ejecuta comandos directamente**:
   ```bash
   cd /root/checkin24hs
   git pull origin main
   cd whatsapp-server
   docker build -t whatsapp-server:latest .
   ```

---

## ✅ Alternativa: Contactar Soporte de Hostinger

Si tu servidor es de Hostinger y EasyPanel no muestra la contraseña:

1. **Ve al panel de Hostinger** (no EasyPanel)
2. **Busca "VPS"** o **"Servidores"**
3. **Selecciona tu servidor**
4. **Busca "Contraseña Root"** o **"Reset Password"**

---

## 🚀 Solución Rápida: Git + Consola Web

**No necesitas la contraseña SSH si usas**:

1. **Git desde tu máquina** (push)
2. **Consola web de EasyPanel** (pull y build)

¿Tienes acceso a la consola web de EasyPanel?
