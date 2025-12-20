# ⚡ Resumen Rápido: Configurar WhatsApp en EasyPanel

## 📋 Valores para Copiar y Pegar

### 🔧 Para TODOS los Servicios (whatsapp, whatsapp2, whatsapp3, whatsapp4)

#### Source (Fuente):
```
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta: /whatsapp-server
```

#### Variables de Entorno (Comunes):
```
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

#### Comando de Inicio:
```
node whatsapp-server.js
```

#### Auto-Deploy:
```
✅ Habilitado
Rama: main
```

---

## 📊 Valores Específicos por Servicio

| Servicio | INSTANCE_NUMBER | PORT | Puerto Publicado | Puerto Destino |
|----------|----------------|------|------------------|----------------|
| **whatsapp** | `1` | `3001` | `3001` | `3001` |
| **whatsapp2** | `2` | `3002` | `3002` | `3002` |
| **whatsapp3** | `3` | `3003` | `3003` | `3003` |
| **whatsapp4** | `4` | `3004` | `3004` | `3004` |

---

## 🎯 Pasos Rápidos

1. ✅ Crear servicio → Nombre: `whatsapp` (o whatsapp2, 3, 4)
2. ✅ Source → GitHub → Configurar (ver arriba)
3. ✅ Variables → Agregar las 5 variables
4. ✅ Puertos → Agregar puerto (ver tabla arriba)
5. ✅ Build → Comando: `node whatsapp-server.js`
6. ✅ Auto-Deploy → Habilitar → Rama: `main`
7. ✅ Deploy → Esperar a que esté verde
8. ✅ Verificar logs → Debe decir "WhatsApp server iniciado en puerto XXXX"

---

## 🔗 Conectar desde Dashboard

1. Dashboard → Flor IA → General
2. URL del servidor: `http://72.61.58.240`
3. Clic en "Conectar Múltiples WhatsApp"
4. Para cada instancia: Clic en "Conectar" → Escanear QR

---

## ⚠️ Errores Comunes

- **"No se encuentra whatsapp-server.js"** → Ruta debe ser `/whatsapp-server`
- **"Puerto ya en uso"** → Verifica que no haya otro servicio usando el puerto
- **"Failed to fetch"** → Servicio no está corriendo (verifica que esté verde)

---

**Guía completa**: Ver `GUIA_PASO_A_PASO_WHATSAPP_EASYPANEL.md`

