# 📤 Instrucciones para Subir WhatsApp a GitHub

## 🎯 Objetivo

Subir el servidor de WhatsApp (`whatsapp-server/`) a GitHub para que EasyPanel pueda descargarlo automáticamente.

## ✅ Verificación Previa

### Archivos que DEBEN estar en GitHub:

- ✅ `whatsapp-server/whatsapp-server.js` - Servidor principal
- ✅ `whatsapp-server/package.json` - Dependencias
- ✅ `whatsapp-server/Dockerfile` - Configuración Docker
- ✅ `whatsapp-server/README.md` - Documentación

### Archivos que NO deben subirse (están en .gitignore):

- ❌ `whatsapp-server/.wwebjs_auth/` - Sesiones de WhatsApp (se crean en el servidor)
- ❌ `whatsapp-server/node_modules/` - Dependencias (se instalan en el servidor)
- ❌ `whatsapp-server/logs/` - Logs del servidor
- ❌ `whatsapp-server/config.json` - Configuración local (si existe)

## 🚀 Método 1: Usar el Script Automático (Recomendado)

### En Windows (PowerShell):

```powershell
.\subir_whatsapp_github.ps1
```

### En Linux/Mac (Bash):

```bash
chmod +x subir_whatsapp_github.sh
./subir_whatsapp_github.sh
```

El script:
1. ✅ Verifica que los archivos existan
2. ✅ Verifica el estado de Git
3. ✅ Te pregunta si quieres agregar los archivos
4. ✅ Te permite crear un commit
5. ✅ Te permite subir a GitHub

## 🚀 Método 2: Manual (Paso a Paso)

### Paso 1: Verificar Estado

```bash
git status whatsapp-server/
```

### Paso 2: Agregar Archivos

```bash
# Agregar todos los archivos de whatsapp-server (excepto los ignorados)
git add whatsapp-server/

# Verificar qué se va a agregar
git status
```

### Paso 3: Crear Commit

```bash
git commit -m "Agregar servidor WhatsApp con integración Flor IA y Supabase"
```

### Paso 4: Subir a GitHub

```bash
git push origin main
```

## 🔍 Verificar que se Subió Correctamente

1. **Ve a tu repositorio en GitHub:**
   ```
   https://github.com/GermanPerez-ai/checkin24hs
   ```

2. **Navega a la carpeta:**
   ```
   https://github.com/GermanPerez-ai/checkin24hs/tree/main/whatsapp-server
   ```

3. **Verifica que veas:**
   - ✅ `whatsapp-server.js`
   - ✅ `package.json`
   - ✅ `Dockerfile`
   - ✅ `README.md`

## ⚙️ Configurar en EasyPanel

Una vez que los archivos estén en GitHub:

### Para cada servicio (whatsapp, whatsapp2, whatsapp3, whatsapp4):

1. **Ve a EasyPanel** → Tu proyecto → Servicio de WhatsApp

2. **Sección "Source" (Fuente):**
   - **Tipo**: GitHub
   - **Propietario**: `GermanPerez-ai` (o tu usuario)
   - **Repositorio**: `checkin24hs`
   - **Rama**: `main`
   - **Ruta de compilación**: `/whatsapp-server` ⚠️ **IMPORTANTE**

3. **Sección "Environment Variables" (Variables de Entorno):**
   ```
   INSTANCE_NUMBER=1
   PORT=3001
   SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
   ```

4. **Sección "Ports" (Puertos):**
   - **Protocolo**: TCP
   - **Publicado**: `3001` (o 3002, 3003, 3004 según la instancia)
   - **Destino**: `3001` (o 3002, 3003, 3004)

5. **Sección "Build" (Compilación):**
   - **Comando de inicio**: `node whatsapp-server.js`

6. **Desplegar:**
   - Haz clic en **"Deploy"** o **"Implementar"**
   - Espera a que el servicio se ponga en verde

## 🆘 Solución de Problemas

### ❌ Error: "No se encontró whatsapp-server.js"

**Causa**: La ruta de compilación está incorrecta.

**Solución**:
- Verifica que la **Ruta de compilación** sea: `/whatsapp-server`
- NO debe ser: `/` o `/whatsapp-server/` (sin barra final)

### ❌ Error: "Cannot find module 'whatsapp-web.js'"

**Causa**: Las dependencias no se instalaron.

**Solución**:
1. En EasyPanel, ve a la sección **"Build"**
2. Agrega un **comando de build**:
   ```bash
   npm install
   ```
3. Guarda y vuelve a desplegar

### ❌ Error: "Archivo no encontrado en GitHub"

**Causa**: Los archivos no se subieron correctamente.

**Solución**:
1. Verifica en GitHub que los archivos estén presentes
2. Verifica que estés en la rama correcta (`main`)
3. Verifica que la ruta en EasyPanel sea correcta

### ❌ Error: "Puerto ya en uso"

**Causa**: Otro servicio está usando el puerto.

**Solución**:
1. Verifica qué servicios están corriendo
2. Detén el servicio que está usando el puerto
3. O cambia el puerto del servicio de WhatsApp

## ✅ Checklist Final

Antes de considerar que todo está listo:

- [ ] Archivos subidos a GitHub
- [ ] Verificados en GitHub (puedes verlos en el navegador)
- [ ] Configurado en EasyPanel (Source, Variables, Puertos, Build)
- [ ] Servicio desplegado y en verde
- [ ] Logs muestran "WhatsApp server iniciado en puerto XXXX"
- [ ] Puedes acceder a `/api/status` desde el dashboard

## 📞 Próximos Pasos

Una vez que el servicio esté corriendo:

1. **Ve al Dashboard** → Flor IA → General
2. **Configura la URL del servidor**: `http://72.61.58.240`
3. **Abre el modal** de conexión múltiple
4. **Conecta cada instancia** escaneando los códigos QR

---

**Última actualización**: Diciembre 2025

