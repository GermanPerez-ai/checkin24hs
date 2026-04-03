# 📱 Cómo Abrir el Verificador de Servidores WhatsApp

## 🚀 Opción 1: Usar el Servidor Local (Recomendado - Sin errores de CORS)

### Con Python:
```bash
# En la terminal, ejecuta:
python servidor_local_simple.py

# O si tienes Python 3:
python3 servidor_local_simple.py
```

Luego abre en tu navegador:
```
http://localhost:8000/verificar_servidores_whatsapp.html
```

### Con Node.js (si tienes `npx`):
```bash
npx http-server -p 8000 --cors
```

Luego abre:
```
http://localhost:8000/verificar_servidores_whatsapp.html
```

---

## 🖱️ Opción 2: Abrir Directamente con Scripts

### Windows (PowerShell):
```powershell
.\abrir_verificador.ps1
```

### Windows (CMD):
```cmd
abrir_verificador.bat
```

### Manualmente:
1. Haz clic derecho en `verificar_servidores_whatsapp.html`
2. Selecciona "Abrir con" → Google Chrome

**⚠️ NOTA:** Si usas esta opción y ves errores de CORS en la consola del navegador, usa la Opción 1 (servidor local).

---

## 🔧 Opción 3: Arrastrar al Navegador

1. Abre Chrome
2. Arrastra el archivo `verificar_servidores_whatsapp.html` a la ventana de Chrome

---

## ❌ Si Ves Errores de CORS

Si ves mensajes como:
- "Access to fetch at 'https://api1.checkin24hs.com...' from origin 'null' has been blocked by CORS policy"
- "Failed to fetch"

**Solución:** Usa la Opción 1 (servidor local). Los archivos locales (`file://`) tienen restricciones de seguridad que impiden hacer peticiones a otros dominios.

---

## 🎯 Uso del Verificador

1. Haz clic en "🔍 Verificar Todos los Servidores"
2. Espera a que se completen las verificaciones (puede tomar 10-20 segundos)
3. Revisa los resultados:
   - ✅ Verde = Servidor online y funcionando
   - ❌ Rojo = Error de conexión o servidor offline
   - ⏳ Amarillo = Verificando

4. Revisa los detalles de cada endpoint:
   - **Raíz (/)** - Disponibilidad básica
   - **Status (/api/status)** - Estado de WhatsApp
   - **QR (/api/qr)** - Disponibilidad de código QR
   - **Health (/api/health)** - Health check (opcional)

---

## 📊 Qué Verifica

Para cada servidor (api1-4.checkin24hs.com):
- ✅ Conectividad HTTPS
- ✅ Endpoint `/api/status` - Estado de conexión
- ✅ Endpoint `/api/qr` - Código QR disponible
- ✅ Tiempo de respuesta
- ✅ Estado HTTP y contenido de respuesta

---

## 🛠️ Solución de Problemas

### El archivo no se abre:
- Asegúrate de que Chrome esté instalado
- Prueba hacer doble clic en el archivo `.bat` o `.ps1`
- Verifica que la ruta del archivo no tenga espacios especiales

### Errores de CORS:
- **SIEMPRE** usa un servidor local (Opción 1)
- Los navegadores bloquean peticiones desde `file://` por seguridad

### No se conecta a los servidores:
- Verifica tu conexión a internet
- Verifica que los servidores estén online
- Revisa la consola del navegador (F12) para más detalles

---

## 💡 Recomendación

**Usa siempre la Opción 1 (servidor local)** para evitar problemas de CORS y tener la mejor experiencia.
