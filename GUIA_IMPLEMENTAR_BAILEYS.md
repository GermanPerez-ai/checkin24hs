# 🚀 Guía: Implementar Baileys para WhatsApp

## ✅ Ventajas de Baileys

- ✅ **No requiere Chrome/Puppeteer** - Funciona en cualquier servidor
- ✅ **Más ligero** - Usa menos memoria
- ✅ **Más rápido** - Inicia en segundos
- ✅ **Más estable** - Menos problemas de conexión
- ✅ **Sin Docker** - Funciona directamente con Node.js

---

## 📋 Paso 1: Instalar Dependencias

```bash
cd whatsapp-server-baileys
npm install
```

---

## 📋 Paso 2: Configurar Variables de Entorno

Crea un archivo `.env` o configura las variables:

```bash
# Puerto del servidor (3001, 3002, 3003, 3004 para cada instancia)
PORT=3001

# Número de instancia (1, 2, 3, 4)
INSTANCE_NUMBER=1

# Gemini API Key para Flor IA
GEMINI_API_KEY=tu-gemini-api-key

# Supabase (opcional)
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=tu-supabase-key
```

---

## 📋 Paso 3: Iniciar el Servidor

```bash
# Instancia 1 (puerto 3001)
INSTANCE_NUMBER=1 PORT=3001 node whatsapp-server-baileys.js

# Instancia 2 (puerto 3002)
INSTANCE_NUMBER=2 PORT=3002 node whatsapp-server-baileys.js

# Instancia 3 (puerto 3003)
INSTANCE_NUMBER=3 PORT=3003 node whatsapp-server-baileys.js

# Instancia 4 (puerto 3004)
INSTANCE_NUMBER=4 PORT=3004 node whatsapp-server-baileys.js
```

---

## 📋 Paso 4: Usar PM2 para Múltiples Instancias

### Instalar PM2:

```bash
npm install -g pm2
```

### Crear archivo de configuración PM2:

```json
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'whatsapp-1',
      script: './whatsapp-server-baileys.js',
      env: {
        INSTANCE_NUMBER: '1',
        PORT: '3001'
      }
    },
    {
      name: 'whatsapp-2',
      script: './whatsapp-server-baileys.js',
      env: {
        INSTANCE_NUMBER: '2',
        PORT: '3002'
      }
    },
    {
      name: 'whatsapp-3',
      script: './whatsapp-server-baileys.js',
      env: {
        INSTANCE_NUMBER: '3',
        PORT: '3003'
      }
    },
    {
      name: 'whatsapp-4',
      script: './whatsapp-server-baileys.js',
      env: {
        INSTANCE_NUMBER: '4',
        PORT: '3004'
      }
    }
  ]
};
```

### Iniciar todas las instancias:

```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

---

## 📱 Paso 5: Conectar WhatsApp

1. **Abrir navegador**: `http://TU_SERVIDOR:3001`
2. **Ver QR Code** en la página
3. **Abrir WhatsApp** en tu teléfono
4. **Escanear QR**
5. **Repetir** para las otras instancias (puertos 3002, 3003, 3004)

---

## 🔧 API Endpoints

### Obtener QR Code:
```bash
GET http://localhost:3001/api/qr
```

### Obtener Estado:
```bash
GET http://localhost:3001/api/status
```

### Enviar Mensaje:
```bash
POST http://localhost:3001/api/send
Content-Type: application/json

{
  "number": "5491112345678",
  "text": "Hola desde Flor!"
}
```

---

## ✅ Verificar que Funciona

```bash
# Ver logs
pm2 logs whatsapp-1

# Ver estado
pm2 status

# Ver información de una instancia
pm2 info whatsapp-1
```

---

## 🎯 Próximos Pasos

1. ✅ Instalar dependencias
2. ✅ Configurar variables de entorno
3. ✅ Iniciar servidores (4 instancias)
4. ✅ Conectar WhatsApp escaneando QR
5. ⏳ Actualizar dashboard para usar estos servidores

---

## 🆘 Solución de Problemas

### Error: "Cannot find module '@whiskeysockets/baileys'"
```bash
npm install
```

### Error: "Port already in use"
```bash
# Cambiar el puerto en la variable de entorno
PORT=3005 node whatsapp-server-baileys.js
```

### QR no aparece
```bash
# Verificar logs
pm2 logs whatsapp-1

# Reiniciar
pm2 restart whatsapp-1
```

---

## 📚 Documentación

- **Baileys GitHub**: https://github.com/WhiskeySockets/Baileys
- **Ejemplos**: https://github.com/WhiskeySockets/Baileys/tree/master/Example

