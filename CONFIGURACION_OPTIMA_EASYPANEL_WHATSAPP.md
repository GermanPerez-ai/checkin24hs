# ⚙️ Configuración Óptima para WhatsApp en EasyPanel

## 🎯 Mejores Prácticas Implementadas

✅ **Rama principal**: `main` (estable y estándar)  
✅ **Auto-deploy**: Habilitado (se actualiza automáticamente)  
✅ **Ruta correcta**: `/whatsapp-server`  
✅ **Archivos sincronizados**: Todo actualizado en GitHub

---

## 📋 Configuración para Cada Servicio de WhatsApp

### 🔧 Servicio: `whatsapp` (Instancia 1)

#### 1. Source (Fuente) - ⚠️ IMPORTANTE
```
Tipo: GitHub
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta de compilación: /whatsapp-server
```

**⚠️ CRÍTICO**: La ruta debe ser `/whatsapp-server` (con barra inicial, sin barra final)

#### 2. Environment Variables (Variables de Entorno)
```
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

#### 3. Ports (Puertos)
```
Protocolo: TCP
Publicado: 3001
Destino: 3001
```

#### 4. Build (Compilación)
```
Comando de inicio: node whatsapp-server.js
```

#### 5. Auto Deploy (Despliegue Automático)
```
✅ Habilitado
Rama: main
```

---

### 🔧 Servicio: `whatsapp2` (Instancia 2)

#### 1. Source (Fuente)
```
Tipo: GitHub
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta de compilación: /whatsapp-server
```

#### 2. Environment Variables
```
INSTANCE_NUMBER=2
PORT=3002
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

#### 3. Ports
```
Protocolo: TCP
Publicado: 3002
Destino: 3002
```

#### 4. Build
```
Comando de inicio: node whatsapp-server.js
```

#### 5. Auto Deploy
```
✅ Habilitado
Rama: main
```

---

### 🔧 Servicio: `whatsapp3` (Instancia 3)

#### 1. Source (Fuente)
```
Tipo: GitHub
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta de compilación: /whatsapp-server
```

#### 2. Environment Variables
```
INSTANCE_NUMBER=3
PORT=3003
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

#### 3. Ports
```
Protocolo: TCP
Publicado: 3003
Destino: 3003
```

#### 4. Build
```
Comando de inicio: node whatsapp-server.js
```

#### 5. Auto Deploy
```
✅ Habilitado
Rama: main
```

---

### 🔧 Servicio: `whatsapp4` (Instancia 4)

#### 1. Source (Fuente)
```
Tipo: GitHub
Propietario: GermanPerez-ai
Repositorio: checkin24hs
Rama: main
Ruta de compilación: /whatsapp-server
```

#### 2. Environment Variables
```
INSTANCE_NUMBER=4
PORT=3004
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
```

#### 3. Ports
```
Protocolo: TCP
Publicado: 3004
Destino: 3004
```

#### 4. Build
```
Comando de inicio: node whatsapp-server.js
```

#### 5. Auto Deploy
```
✅ Habilitado
Rama: main
```

---

## 🚀 Ventajas de Esta Configuración

### ✅ Auto-Actualización
- Cada vez que hagas `git push` a `main`, EasyPanel detectará los cambios automáticamente
- No necesitas desplegar manualmente
- Siempre tendrás la última versión

### ✅ Estabilidad
- Usa la rama `main` (producción estable)
- No hay riesgo de cambios experimentales
- Fácil de hacer rollback si es necesario

### ✅ Performance
- Ruta optimizada: `/whatsapp-server`
- Variables de entorno correctas
- Puertos configurados correctamente

### ✅ Mantenibilidad
- Todo centralizado en GitHub
- Historial completo de cambios
- Fácil de replicar en otros servidores

---

## 📊 Resumen de Configuración

| Servicio | INSTANCE_NUMBER | PORT | Puerto Interno | Auto-Deploy |
|----------|----------------|------|----------------|-------------|
| whatsapp | 1 | 3001 | 3001 | ✅ main |
| whatsapp2 | 2 | 3002 | 3002 | ✅ main |
| whatsapp3 | 3 | 3003 | 3003 | ✅ main |
| whatsapp4 | 4 | 3004 | 3004 | ✅ main |

---

## 🔄 Flujo de Actualización Automática

1. **Haces cambios** en el código local
2. **Haces commit**: `git commit -m "Descripción"`
3. **Haces push**: `git push origin main`
4. **EasyPanel detecta** el cambio automáticamente
5. **EasyPanel despliega** la nueva versión
6. **Servicios se actualizan** automáticamente

**⏱️ Tiempo estimado**: 2-5 minutos desde el push hasta que esté desplegado

---

## ✅ Verificación Post-Configuración

Después de configurar cada servicio:

1. **Verifica que el servicio esté en verde** (Running)
2. **Revisa los logs** - Deberías ver:
   ```
   🚀 Iniciando servidor WhatsApp...
   ✅ Cliente de Supabase inicializado
   WhatsApp server iniciado en puerto 3001
   ```
3. **Prueba desde el dashboard**:
   - Ve a Flor IA → General
   - Configura URL: `http://72.61.58.240`
   - Abre modal de conexión
   - Haz clic en "Conectar" en cada instancia

---

## 🆘 Si Algo No Funciona

### ❌ Error: "No se encuentra whatsapp-server.js"

**Solución**:
- Verifica que la **Ruta de compilación** sea exactamente: `/whatsapp-server`
- NO debe ser: `/` o `/whatsapp-server/` o `whatsapp-server`

### ❌ Error: "Auto-deploy no funciona"

**Solución**:
1. Verifica que Auto-Deploy esté habilitado
2. Verifica que la rama sea `main`
3. Haz un push manual para forzar el despliegue

### ❌ Error: "Puerto ya en uso"

**Solución**:
1. Verifica qué servicio está usando el puerto
2. Detén ese servicio o cambia el puerto

---

## 📝 Notas Importantes

- ⚠️ **NUNCA** cambies la rama a `working-version` en producción
- ✅ **SIEMPRE** usa `main` para servicios en producción
- 🔄 **Auto-Deploy** debe estar habilitado para actualizaciones automáticas
- 📍 **Ruta de compilación** debe ser exactamente `/whatsapp-server`

---

**Última actualización**: Diciembre 2025  
**Rama configurada**: `main`  
**Estado**: ✅ Sincronizado y listo para usar

