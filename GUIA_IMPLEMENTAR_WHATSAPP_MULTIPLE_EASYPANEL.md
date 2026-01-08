# 📱 Guía: Implementar Múltiples WhatsApp en EasyPanel

## 🎯 Objetivo

Configurar 4 instancias de WhatsApp en EasyPanel para que el modal del dashboard pueda conectar hasta 4 números diferentes, cada uno con su propio QR y usando Flor IA.

## 📋 Requisitos Previos

- Acceso a EasyPanel
- Servidor de WhatsApp base funcionando
- Archivo `whatsapp-server.js` disponible

## 🔧 Paso 1: Crear 4 Servicios en EasyPanel

Necesitas crear **4 servicios separados** en EasyPanel, uno para cada instancia de WhatsApp:

### Servicio 1: WhatsApp Instancia 1
- **Nombre del servicio**: `whatsapp-1` o `whatsapp-instance-1`
- **Puerto**: `3001`
- **Variable de entorno**: `INSTANCE_NUMBER=1`
- **Variable de entorno**: `PORT=3001`

### Servicio 2: WhatsApp Instancia 2
- **Nombre del servicio**: `whatsapp-2` o `whatsapp-instance-2`
- **Puerto**: `3002`
- **Variable de entorno**: `INSTANCE_NUMBER=2`
- **Variable de entorno**: `PORT=3002`

### Servicio 3: WhatsApp Instancia 3
- **Nombre del servicio**: `whatsapp-3` o `whatsapp-instance-3`
- **Puerto**: `3003`
- **Variable de entorno**: `INSTANCE_NUMBER=3`
- **Variable de entorno**: `PORT=3003`

### Servicio 4: WhatsApp Instancia 4
- **Nombre del servicio**: `whatsapp-4` o `whatsapp-instance-4`
- **Puerto**: `3004`
- **Variable de entorno**: `INSTANCE_NUMBER=4`
- **Variable de entorno**: `PORT=3004`

## 📝 Paso 2: Configuración en EasyPanel

Para cada servicio, configura:

### Variables de Entorno Requeridas

```env
INSTANCE_NUMBER=1          # Cambiar según la instancia (1, 2, 3, 4)
PORT=3001                  # Cambiar según la instancia (3001, 3002, 3003, 3004)
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
GEMINI_API_KEY=tu_api_key_de_gemini  # Opcional, para IA
```

### Configuración de Puerto

- **Puerto interno**: El mismo que PORT (3001, 3002, 3003, 3004)
- **Puerto externo**: Puede ser el mismo o mapeado
- **Protocolo**: HTTP

### Comando de Inicio

```bash
node whatsapp-server.js
```

O si usas PM2:
```bash
pm2 start whatsapp-server.js --name "whatsapp-instance-1" --update-env
```

## 🔄 Paso 3: Verificar que los Servicios Estén Corriendo

1. En EasyPanel, verifica que los 4 servicios estén en **verde (Running)**
2. Revisa los logs de cada servicio para verificar que no hay errores
3. Cada servicio debe mostrar su propio QR cuando se inicia

## 🧪 Paso 4: Probar las Conexiones

1. Abre el dashboard: `https://crm.checkin24hs.com/`
2. Ve a **Configuración Flor** → **📱 WhatsApp**
3. Haz clic en **"Conectar Múltiples WhatsApp (hasta 4)"**
4. Deberías ver 4 slots (WhatsApp 1, WhatsApp 2, WhatsApp 3, WhatsApp 4)
5. Haz clic en **"Conectar"** en cada slot para generar el QR

## ⚙️ Paso 5: Configurar URL del Servidor en el Dashboard

En el modal de WhatsApp del dashboard, configura la URL base del servidor:

- **URL base**: `http://72.61.58.240` (o tu IP del servidor)
- El sistema automáticamente agregará los puertos: `:3001`, `:3002`, `:3003`, `:3004`

## 📊 Estructura de Servicios en EasyPanel

```
Proyecto: Checkin24hs
├── whatsapp-1 (Puerto 3001, INSTANCE_NUMBER=1)
├── whatsapp-2 (Puerto 3002, INSTANCE_NUMBER=2)
├── whatsapp-3 (Puerto 3003, INSTANCE_NUMBER=3)
└── whatsapp-4 (Puerto 3004, INSTANCE_NUMBER=4)
```

## 🔍 Verificación de Funcionamiento

### Verificar que cada instancia está corriendo:

```bash
# Desde la terminal de cada servicio en EasyPanel
curl http://localhost:3001/api/status  # Instancia 1
curl http://localhost:3002/api/status  # Instancia 2
curl http://localhost:3003/api/status  # Instancia 3
curl http://localhost:3004/api/status  # Instancia 4
```

Cada uno debe responder con su estado (conectado o QR disponible).

## ⚠️ Notas Importantes

1. **Cada instancia es independiente**: Cada una tiene su propia sesión de WhatsApp
2. **Cada número necesita su propio QR**: Escanea un QR diferente para cada instancia
3. **Flor IA funciona en todas**: Cada instancia usará Flor IA para responder automáticamente
4. **Recursos del servidor**: 4 instancias consumen más recursos, asegúrate de tener suficiente RAM/CPU

## 🆘 Solución de Problemas

### Si un servicio no inicia:
1. Revisa los logs en EasyPanel
2. Verifica que el puerto no esté en uso
3. Verifica las variables de entorno

### Si el QR no aparece:
1. Elimina la carpeta `.wwebjs_auth` desde el File Manager de EasyPanel
2. Reinicia el servicio
3. Revisa los logs para ver el QR

### Si no se puede conectar desde el dashboard:
1. Verifica que los puertos estén abiertos (3001-3004)
2. Verifica la URL del servidor en el dashboard
3. Revisa la consola del navegador (F12) para ver errores

## 📝 Checklist de Implementación

- [ ] Servicio 1 creado con INSTANCE_NUMBER=1 y PORT=3001
- [ ] Servicio 2 creado con INSTANCE_NUMBER=2 y PORT=3002
- [ ] Servicio 3 creado con INSTANCE_NUMBER=3 y PORT=3003
- [ ] Servicio 4 creado con INSTANCE_NUMBER=4 y PORT=3004
- [ ] Todos los servicios en verde (Running)
- [ ] Variables de entorno configuradas correctamente
- [ ] Puertos configurados y accesibles
- [ ] Dashboard configurado con la URL correcta del servidor
- [ ] Modal de WhatsApp muestra los 4 slots
- [ ] Cada instancia genera su propio QR

## 🎉 Una Vez Implementado

Cada número de WhatsApp conectado:
- ✅ Tendrá su propio QR para escanear
- ✅ Usará Flor IA para responder automáticamente
- ✅ Guardará chats e interacciones en Supabase
- ✅ Funcionará independientemente de las otras instancias

