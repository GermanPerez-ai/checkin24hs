# 🔧 Solucionar Error de Nixpacks

## ❌ Error Actual

```
error: undefined variable 'npm-9_x'
```

**Causa**: Nixpacks está intentando instalar `npm-9_x` como paquete Nix, pero no existe. `npm` viene incluido con Node.js.

---

## ✅ Solución: Eliminar Paquetes Nix Problemáticos

### Paso 1: Ir a Compilación

1. **Ve a EasyPanel** → **Servicios** → **`whatsapp`**
2. **Ve a "Fuente"** → **"Compilación"**

### Paso 2: Limpiar Paquetes Nix

En el campo **"Paquetes Nix"**, **déjalo VACÍO** o elimina cualquier contenido.

**NO debe tener**: `nodejs_22 npm-9_x` ni nada similar.

### Paso 3: Verificar Paquetes APT

En el campo **"Paquetes APT"**, debe tener:

```
chromium chromium-sandbox
```

### Paso 4: Verificar Comando de Instalación

En **"Comando de instalación"**, debe estar:

```bash
npm install && npx puppeteer browsers install chrome
```

### Paso 5: Guardar y Reconstruir

1. **Guarda** los cambios
2. **Ve a "Implementaciones"**
3. **Haz clic en "Implementar"**
4. **Espera 5-10 minutos**

---

## 📋 Configuración Correcta Final

### En "Compilación":
- **Paquetes Nix**: **VACÍO** (dejar en blanco)
- **Paquetes APT**: `chromium chromium-sandbox`
- **Comando de instalación**: `npm install && npx puppeteer browsers install chrome`

### En "Entorno":
- `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false`
- `CHROMIUM_FLAGS=--no-sandbox --disable-setuid-sandbox`

---

## 🔍 Explicación

- **Node.js y npm** vienen incluidos automáticamente con Nixpacks cuando detecta un `package.json`
- **No necesitas** especificar `nodejs_22` o `npm-9_x` en paquetes Nix
- **Solo necesitas** los paquetes APT para Chromium

---

**¿Puedes eliminar el contenido del campo "Paquetes Nix" y dejar solo los paquetes APT? Después de reconstruir, ¿qué ves en los logs?**









