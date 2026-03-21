# 📱 WhatsApp Server con Baileys - Checkin24hs

Servidor de WhatsApp usando Baileys para integrar con Flor IA.

## ⚠️ Una sola fuente de código (importante)

El archivo que **sí se edita y despliega** es:

**`whatsapp-server/whatsapp-server-baileys.js`**

- **Docker / EasyPanel** (`Dockerfile.whatsapp`) copia desde `whatsapp-server/`.
- Esta carpeta (`whatsapp-server-baileys/`) **ya no duplica** ese `.js`: PM2 y `npm start` apuntan al archivo canónico.
- Sesiones Baileys (`auth_info_baileys_*`) viven en **`whatsapp-server/`** (ruta absoluta vía `__dirname` en el script).

## ✨ Características

- ✅ **Sin Docker** - Funciona directamente con Node.js
- ✅ **Sin Chrome** - No necesita Puppeteer
- ✅ **Más rápido** - Inicia en segundos
- ✅ **Más ligero** - Usa menos memoria
- ✅ **4 instancias** - Soporte para múltiples WhatsApp
- ✅ **Flor IA** - Integración completa con Gemini
- ✅ **Supabase** - Guarda todos los mensajes

## 🚀 Instalación Rápida

```bash
# Dependencias del proceso (el script vive en ../whatsapp-server/)
cd ../whatsapp-server
npm install
cd ../whatsapp-server-baileys

# Opcional: npm install aquí solo si usás herramientas locales; el runtime carga módulos desde whatsapp-server

# Configurar variables de entorno (opcional)
export GEMINI_API_KEY="tu-gemini-key"
export SUPABASE_URL="tu-supabase-url"
export SUPABASE_ANON_KEY="tu-supabase-key"

# Iniciar con PM2
npm install -g pm2
mkdir -p logs
pm2 start ecosystem.config.js
pm2 save
```

## 📱 Conectar WhatsApp

1. Abre en navegador: `http://TU_SERVIDOR:3001`
2. Escanea el QR con WhatsApp
3. Repite para puertos 3002, 3003, 3004

## 🔧 API Endpoints

- `GET /api/qr` - Obtener QR code
- `GET /api/status` - Estado de conexión
- `POST /api/send` - Enviar mensaje

## 📚 Documentación

Ver `GUIA_IMPLEMENTAR_BAILEYS.md` para más detalles.

## 🆘 Soporte

Para problemas, ver los logs:
```bash
pm2 logs whatsapp-1
```

