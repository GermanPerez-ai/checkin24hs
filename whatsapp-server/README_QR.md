# 📱 Configuración Rápida de QR para WhatsApp

## 🚀 Inicio Rápido

### Windows (PowerShell)

```powershell
cd whatsapp-server
.\configurar-qr.ps1
```

### Linux/Mac (Node.js)

```bash
cd whatsapp-server
npm run qr
# o
node configurar-qr.js
```

---

## 📋 Comandos Rápidos

### Ver Estado de una Instancia

**PowerShell:**
```powershell
.\configurar-qr.ps1 -Action status -Instance 1
```

**Node.js:**
```bash
node configurar-qr.js
# Opción 1: Ver estado de conexión
```

### Obtener QR Code

**PowerShell:**
```powershell
.\configurar-qr.ps1 -Action qr -Instance 1
```

**Node.js:**
```bash
node configurar-qr.js
# Opción 2: Obtener código QR
```

### Guardar QR como Imagen

**PowerShell:**
```powershell
.\configurar-qr.ps1 -Action save -Instance 1
```

**Node.js:**
```bash
node configurar-qr.js
# Opción 3: Guardar QR como imagen
```

### Verificar Todas las Instancias

**PowerShell:**
```powershell
.\configurar-qr.ps1 -Action check
```

**Node.js:**
```bash
node configurar-qr.js
# Opción 4: Verificar todas las instancias
```

### Limpiar Sesión

**PowerShell:**
```powershell
.\configurar-qr.ps1 -Action clean -Instance 1
```

**Node.js:**
```bash
node configurar-qr.js
# Opción 5: Limpiar sesión y generar nuevo QR
```

---

## 🌐 Configurar URL del Servidor

### Por Defecto
- Local: `http://localhost`
- Servidor: `http://TU_IP` o `http://tu-dominio.com`

### Cambiar URL

**PowerShell:**
```powershell
.\configurar-qr.ps1 -Action menu
# Opción 6: Configurar URL del servidor
```

**Node.js:**
```bash
node configurar-qr.js
# Opción 6: Configurar URL del servidor
```

La URL se guarda en `.qr-config.json` y se usa automáticamente.

---

## 🔗 Endpoints de API

### Obtener Estado
```bash
GET http://TU_SERVIDOR:3001/api/status
```

### Obtener QR
```bash
GET http://TU_SERVIDOR:3001/api/qr
```

### Ver Panel Web
```
http://TU_SERVIDOR:3001
```

---

## 📚 Más Información

- **Guía Completa**: [GUIA_CONFIGURACION_QR.md](./GUIA_CONFIGURACION_QR.md)
- **README Principal**: [README.md](./README.md)

---

**💡 Tip:** Usa el menú interactivo para explorar todas las opciones disponibles.
