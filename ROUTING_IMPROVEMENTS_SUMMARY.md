# 📋 Resumen: Mejoras de Ruteo y Filtrado - Email Monitor

## ✅ Implementaciones Completadas

### 1. 🎯 Ruteo Automático por Tipo de Remitente

**HOTELES** → Grupo WhatsApp (WHATSAPP_GROUP_ID):
- Ejemplos: huilohuilo.com, puyehue.cl, termashuife.cl, jahuel.cl, etc.
- Todas las confirmaciones, cancelaciones, cambios de fecha de hoteles

**PROVEEDORES/AGENCIAS** → Números Individuales (WHATSAPP_PROVIDER_NUMBERS):
- Configurables: tanica.com, ratehawk.com, emergingtravel.com (PROVIDER_DOMAINS)
- Se envía a: 5492944210725,5492944579759 (por defecto, configurable)

**INTERNOS** → No se notifican:
- checkin24hs.com, checkin24hs@gmail.com, axelbisio@hotmail.com
- Configurable en INTERNAL_SENDERS

**Clasificación**: Si el dominio NO está en PROVIDER_DOMAINS → es HOTEL (va al grupo)

### 2. 🚫 Exclusión de Remitentes Internos

- Nueva variable: `INTERNAL_SENDERS`
- Soporta dominios completos (`checkin24hs.com`) y emails específicos (`axelbisio@hotmail.com`)
- Nuevo status: `internal` (se cuenta pero no se notifica)

### 3. ✅ Corrección del Contador Dry-Run

**Antes**: Siempre mostraba "Dry-run: 0"
**Ahora**: Muestra correctamente "🧪 Dry-run (se enviarían): 17" (o el número real)

### 4. 🧹 Limpieza de Placeholders de Imágenes

Remueve automáticamente:
- `[cid:image001@...]`
- `[image:...]`
- `[https://example.com/image.jpg]`

### 5. 🤫 Silenciado de Logs IMAP

- `logger: false` en ImapFlow
- Output mucho más limpio, solo errores importantes

### 6. 🏷️ Flag --mark-existing

```bash
node monitor.js --mark-existing
# o
node monitor.js --seed
```

**Qué hace**:
- Busca TODOS los correos en el rango configurado (IMAP_SINCE_DAYS)
- Los marca como `marked_existing` en Supabase
- NO envía ninguna notificación
- Evita flood de notificaciones viejas en la primera ejecución real

**Cuándo usarlo**: UNA VEZ antes del primer deploy a producción

### 7. 📊 Mostrar Destino en Dry-Run

Ahora muestra para cada correo:
```
   📍 Tipo: HOTEL (grupo)
   📲 Destino: Grupo 120363123456789012@g.us
```

O para proveedores:
```
   📍 Tipo: PROVEEDOR (individual)
   📲 Destino: 2 número(s) proveedor: 5492944210725, 5492944579759
```

## 📦 Nuevas Variables de Entorno

Actualizar `.env` con:

```bash
# Números WhatsApp para proveedores (solo dígitos, separados por comas)
WHATSAPP_PROVIDER_NUMBERS=5492944210725,5492944579759

# Dominios de proveedores/agencias (van a números individuales)
PROVIDER_DOMAINS=tanica.com,ratehawk.com,emergingtravel.com

# Dominios de hoteles (opcional - para clasificación explícita)
HOTEL_DOMAINS=

# Remitentes internos (NO se notifican)
INTERNAL_SENDERS=checkin24hs.com,checkin24hs@gmail.com,axelbisio@hotmail.com
```

## 🚀 Comandos para Actualizar en el Servidor

### Opción A: Actualizar solo email-monitor (recomendado)

```bash
# 1. Ir a la carpeta del proyecto
cd /ruta/completa/checkin24hs

# 2. Traer los cambios
git fetch origin

# 3. Actualizar SOLO la carpeta email-monitor desde el branch
git checkout origin/cursor/email-monitor-whatsapp-notifications-5c6e -- email-monitor

# 4. Verificar archivos actualizados
ls -la email-monitor/*.js

# 5. Instalar dependencias (por si acaso)
cd email-monitor
npm install
```

### Opción B: Actualizar todo el branch

```bash
# 1. Ir a la carpeta del proyecto
cd /ruta/completa/checkin24hs

# 2. Fetch y checkout del branch
git fetch origin
git checkout cursor/email-monitor-whatsapp-notifications-5c6e
git pull origin cursor/email-monitor-whatsapp-notifications-5c6e

# 3. Instalar dependencias
cd email-monitor
npm install
```

## 🧪 Secuencia de Pruebas Recomendada

### 1. Actualizar el .env

```bash
cd email-monitor
nano .env
```

Agregar/actualizar las nuevas variables:
- WHATSAPP_PROVIDER_NUMBERS
- PROVIDER_DOMAINS
- INTERNAL_SENDERS

### 2. Ejecutar Dry-Run

```bash
node monitor.js --dry-run
```

**Verificar**:
- ✅ Número correcto de correos detectados (~17 según tu prueba)
- ✅ Clasificación correcta (HOTEL vs PROVEEDOR)
- ✅ Destinos correctos (grupo vs números individuales)
- ✅ Internos excluidos correctamente
- ✅ Contador "🧪 Dry-run (se enviarían): 17" correcto

### 3. Marcar Correos Existentes

**IMPORTANTE**: Hacer esto UNA SOLA VEZ antes de producción

```bash
node monitor.js --mark-existing
```

**Verificar**:
- ✅ Muestra "🏷️  Modo MARK-EXISTING activado"
- ✅ Procesa todos los correos
- ✅ Muestra "🏷️  Marcados como existentes: N"
- ✅ NO envía notificaciones

**Resultado esperado**: Los ~17 correos se marcan en Supabase como `marked_existing`

### 4. Primera Ejecución Real

```bash
node monitor.js
```

**Verificar**:
- ✅ No procesa correos viejos (ya están marcados)
- ✅ Solo procesa correos nuevos que lleguen después del --mark-existing
- ✅ Envía a los destinos correctos según tipo

### 5. Verificar en Supabase

```sql
SELECT 
    status,
    COUNT(*) as count
FROM email_monitor_notifications
GROUP BY status
ORDER BY count DESC;

-- Debería mostrar:
-- marked_existing: ~17 (o más, los del --mark-existing)
-- notified: 0 (en la primera ejecución real)
```

## 📊 Output Esperado

### Dry-Run Output:
```
🧪 Modo DRY-RUN activado: no se enviarán notificaciones

📋 Configuración:
   IMAP: reservas@checkin24hs.com@imap.hostinger.com
   Buzón: INBOX
   Desde: hace 7 días
   WhatsApp Grupo (hoteles): 120363123456789012@g.us
   WhatsApp Números (proveedores): 5492944210725, 5492944579759
   Proveedores conocidos: tanica.com, ratehawk.com, emergingtravel.com
   Remitentes internos (excluidos): checkin24hs.com, checkin24hs@gmail.com, axelbisio@hotmail.com

📬 Encontrados 70 correos

📧 Procesando: Re: Reserva Hotel Puyehue
   De: Hotel Puyehue <reservas@puyehue.cl>
   ↩️  Es respuesta
   📍 Tipo: HOTEL (grupo)
   📝 Resumen: Hotel Puyehue: Confirmó modificación
   📲 Destino: Grupo 120363123456789012@g.us
   🧪 [DRY-RUN] No se envía...

📧 Procesando: Re: Booking confirmation
   De: Tanica <noreply@tanica.com>
   ↩️  Es respuesta
   📍 Tipo: PROVEEDOR (individual)
   📝 Resumen: Tanica: Confirmación de reserva
   📲 Destino: 2 número(s) proveedor: 5492944210725, 5492944579759
   🧪 [DRY-RUN] No se envía...

============================================================
📊 RESUMEN
============================================================
Total procesados: 70
🧪 Dry-run (se enviarían): 17
🔍 Filtrados: 53
🏢 Internos (excluidos): 0
♻️  Duplicados: 0
❌ Errores: 0
============================================================
```

### Mark-Existing Output:
```
🏷️  Modo MARK-EXISTING activado: se marcarán correos sin enviar

📬 Encontrados 70 correos

📧 Procesando: Re: Reserva Hotel Puyehue
   ...
   ✅ Marcado como existente (no se envía)

============================================================
📊 RESUMEN
============================================================
Total procesados: 70
🏷️  Marcados como existentes: 17
🔍 Filtrados: 53
🏢 Internos (excluidos): 0
♻️  Duplicados: 0
❌ Errores: 0
============================================================
```

## ✅ Tests

Todos los tests siguen pasando:
```bash
npm test
# ✅ 7/7 tests de filtrado
# ✅ 8/8 tests de parser
```

## 🔧 Troubleshooting

### "WHATSAPP_PROVIDER_NUMBERS no configurado"
Agregar la variable al .env:
```bash
WHATSAPP_PROVIDER_NUMBERS=5492944210725,5492944579759
```

### "Correos de proveedores van al grupo"
Verificar PROVIDER_DOMAINS incluya el dominio:
```bash
PROVIDER_DOMAINS=tanica.com,ratehawk.com,emergingtravel.com,nuevoproveedor.com
```

### "Correos internos se notifican"
Agregar a INTERNAL_SENDERS:
```bash
INTERNAL_SENDERS=checkin24hs.com,checkin24hs@gmail.com,axelbisio@hotmail.com,otro@example.com
```

### "Dry-run muestra 0 aunque hay correos"
Ya está corregido en esta versión. Actualizar el código.

## 📝 Archivos Modificados

- `email-monitor/.env.example` - Nuevas variables documentadas
- `email-monitor/monitor.js` - Toda la lógica de routing, filtering, flags
- `email-monitor/README.md` - Documentación actualizada

## 🎯 Estado

✅ Código pusheado al branch `cursor/email-monitor-whatsapp-notifications-5c6e`
✅ Todos los tests pasando
✅ Sintaxis validada con `node -c`
✅ Listo para pull y prueba en producción

**NO hacer merge todavía** - probar primero en producción con la secuencia de pruebas.
