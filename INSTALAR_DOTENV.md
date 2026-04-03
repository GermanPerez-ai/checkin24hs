# 📦 Instrucciones para Instalar dotenv

## 🔍 Verificación

Primero, verifica si ya tienes `dotenv` instalado:

1. Busca la carpeta `node_modules` en tu proyecto
2. Si existe `node_modules\dotenv`, ya está instalado

---

## 📋 Opción 1: Instalar con npm (Recomendado)

### Requisitos previos:
- Node.js instalado
- npm disponible en el PATH

### Pasos:

1. **Abre PowerShell o CMD como Administrador**

2. **Navega al directorio del proyecto:**
   ```bash
   cd C:\Users\German\Downloads\Checkin24hs
   ```

3. **Instala dotenv:**
   ```bash
   npm install dotenv
   ```

4. **Verifica la instalación:**
   ```bash
   npm list dotenv
   ```

---

## 📋 Opción 2: Si npm no está en el PATH

### Opción 2A: Usar la ruta completa de npm

1. **Busca dónde está instalado Node.js:**
   - Generalmente en: `C:\Program Files\nodejs\`
   - O en: `C:\Users\TuUsuario\AppData\Roaming\npm\`

2. **Usa la ruta completa:**
   ```bash
   cd C:\Users\German\Downloads\Checkin24hs
   "C:\Program Files\nodejs\npm.cmd" install dotenv
   ```

### Opción 2B: Agregar Node.js al PATH

1. Busca dónde está instalado Node.js (generalmente `C:\Program Files\nodejs\`)
2. Agrega esa ruta al PATH del sistema
3. Reinicia PowerShell/CMD
4. Ejecuta `npm install dotenv`

---

## 📋 Opción 3: Verificar package.json

Si `dotenv` ya está en `package.json` (que ya lo agregamos), puedes instalarlo con:

```bash
npm install
```

Esto instalará TODAS las dependencias listadas en `package.json`, incluyendo `dotenv`.

---

## 📋 Opción 4: Instalación Manual (Último recurso)

Si ninguna de las opciones anteriores funciona:

1. Descarga `dotenv` manualmente desde npm: https://www.npmjs.com/package/dotenv
2. O simplemente deja el código como está - `dotenv` ya está en `package.json`
3. Cuando subas a GitHub y lo despliegues en el servidor, ejecuta `npm install` en el servidor

---

## ✅ Verificación de Instalación

Después de instalar:

1. **Verifica que existe la carpeta:**
   ```
   C:\Users\German\Downloads\Checkin24hs\node_modules\dotenv
   ```

2. **Prueba el servidor:**
   ```bash
   node server.js
   ```
   
   Si no da error de "Cannot find module 'dotenv'", está bien.

---

## 🔧 Si el servidor funciona sin instalar dotenv

**¡Eso está bien!** 

El código ya está preparado. Si el servidor inicia sin errores, significa que:
- O bien ya tienes `dotenv` instalado
- O bien Node.js lo encontró de otra forma

En ese caso, solo necesitas crear el archivo `.env` con tu API Key.

---

## 📝 Nota Importante

**NO es crítico instalar `dotenv` AHORA mismo si:**
- El servidor ya funciona sin errores
- Solo necesitas crear el archivo `.env`

Puedes instalar `dotenv` más tarde, o cuando subas el código al servidor (donde sí será necesario ejecutar `npm install`).
