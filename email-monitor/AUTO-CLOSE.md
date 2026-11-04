# Auto-Cierre de Reservas

## 📋 Descripción

Funcionalidad que detecta automáticamente cuando un hotel o proveedor confirma una cancelación o modificación de reserva por email, y actualiza el estado correspondiente en Supabase (tabla `public.reservations`).

Esto evita que Ana siga alertando sobre reservas que ya fueron confirmadas por el hotel.

## 🎯 Casos de Uso

### Estados que se cierran automáticamente:
- `Anulación pedida` → `Cancelada` (cuando el hotel confirma la anulación)
- `Modificación pedida` → `Confirmada` (cuando el hotel confirma la modificación)
  - **NUEVO:** Al confirmar una modificación, también actualiza los datos de la reserva:
    - **Fechas:** Si cambió el check-in o check-out, actualiza los campos `check_in` y `check_out`
    - **Tarifa:** Si cambió el precio, actualiza el campo `total_amount`
    - **Auditoría:** Guarda en `notes` los valores anteriores y nuevos (ej: `check_in 2026-11-14→2026-11-16; total_amount 1676.25→1800`)
    - **Criterio conservador:** Si no se pueden determinar los cambios con certeza, NO se auto-cierra y se marca como "requiere revisión manual"
- `En gestión` → `Cancelada` o `Confirmada` (según el caso)

### Ejemplos reales procesados:

**Ejemplo 1: Huilo Huilo**
- **Remitente:** paz.galvez@huilohuilo.com
- **Subject:** RE: ANULAR RESERVA Hotel Huilo-Huilo 598854662
- **Body:** "Procedemos a anular según lo solicitado. N° de cancelación: 600986202"
- **Resultado:** Reserva 598854662 cambia de `Anulación pedida` → `Cancelada`

**Ejemplo 2: Puyehue**
- **Remitente:** tnunez@hotelpuyehue.cl
- **Subject:** RE: ANULAR RESERVA Hotel Puyehue VH6QHS
- **Body:** "Reservas canceladas"
- **Resultado:** Reserva VH6QHS cambia de `Anulación pedida` → `Cancelada`

**Ejemplo 3: Tanica (múltiples códigos)**
- **Remitente:** jmonteverde@tanica.com
- **Subject:** RE: ANULAR RESERVA Tanica
- **Body:** "Dejaremos anulada la reserva. Reserva original VG52SH Reserva con descuento VX6KZM"
- **Resultado:** Ambas reservas cambian a `Cancelada`

**Ejemplo 4: Modificación de fechas (NUEVO)**
- **Remitente:** reservas@hotelpuyehue.cl
- **Subject:** RE: MODIFICAR RESERVA Hotel Puyehue V2K67A
- **Body:** "Hemos modificado la reserva. Nuevas fechas: check-in 2026-11-16, check-out 2026-11-20"
- **Resultado:** 
  - Reserva V2K67A cambia de `Modificación pedida` → `Confirmada`
  - Campo `check_in` actualizado: `2026-11-14` → `2026-11-16`
  - Campo `check_out` actualizado: `2026-11-18` → `2026-11-20`
  - Nota de auditoría agregada: `[03/11/2026] Auto-cerrado por email-monitor: Hotel Puyehue (reservas@hotelpuyehue.cl) confirmó; check_in 2026-11-14→2026-11-16; check_out 2026-11-18→2026-11-20`

**Ejemplo 5: Modificación de tarifa (NUEVO)**
- **Remitente:** reservas@corralco.com
- **Subject:** RE: MODIFICAR RESERVA Corralco VH6QHS
- **Body:** "Confirmada la modificación. El nuevo total es $1800"
- **Resultado:**
  - Reserva VH6QHS cambia de `Modificación pedida` → `Confirmada`
  - Campo `total_amount` actualizado: `1676.25` → `1800`
  - Nota de auditoría agregada: `[03/11/2026] Auto-cerrado por email-monitor: Corralco (reservas@corralco.com) confirmó; total_amount 1676.25→1800`

## 🔧 Configuración

### Variables de entorno (.env)

```bash
# Habilitar auto-cierre (0 = deshabilitado, 1 = habilitado)
AUTO_CLOSE_RESERVATIONS=0

# Modo dry-run (1 = solo simular, 0 = ejecutar real)
# Útil para probar antes de activar en producción
AUTO_CLOSE_DRY_RUN=1
```

### Flujo de habilitación recomendado:

#### 1. **Fase de prueba** (recomendado inicialmente)
```bash
AUTO_CLOSE_RESERVATIONS=1
AUTO_CLOSE_DRY_RUN=1
```
- Detecta y reporta en logs pero NO actualiza la base de datos
- Incluye en notificaciones WhatsApp: "🧪 [DRY-RUN] Reserva X se cerraría"
- Revisar logs durante 1-2 días para verificar que detecta correctamente

#### 2. **Activación en producción**
```bash
AUTO_CLOSE_RESERVATIONS=1
AUTO_CLOSE_DRY_RUN=0
```
- Actualiza automáticamente el estado en Supabase
- Incluye en notificaciones WhatsApp: "✅ Reserva X cerrada en dashboard"

#### 3. **Desactivar** (si se necesita)
```bash
AUTO_CLOSE_RESERVATIONS=0
```
- Vuelve al comportamiento original (sin auto-cierre)

## 🧪 Verificación

### Ejecutar tests
```bash
cd email-monitor
npm test
```

Los tests verifican:
- ✅ Extracción de códigos alfanuméricos (V2K67A, VH6QHS, VG52SH, VX6KZM)
- ✅ Extracción de códigos numéricos (598854662, 600986202)
- ✅ Detección de confirmaciones claras
- ✅ Rechazo cuando hotel no confirma o tiene penalidad
- ✅ Prevención de falsos positivos

### Revisar logs

En modo **dry-run**, el log mostrará:
```
📧 Procesando: RE: ANULAR RESERVA Hotel Puyehue VH6QHS
   De: Hotel Puyehue <reservas@hotelpuyehue.cl>
   ↩️  Es respuesta
   📍 Tipo: HOTEL (grupo)
   👤 Solicitado por: Mariano
   📝 Resumen: Hotel Puyehue: Confirmó anulación
   🔄 Auto-cierre: 1 reserva(s) procesada(s) (cancelacion)
   🧪 [AUTO-CLOSE DRY-RUN] Se cerraría: VH6QHS (Anulación pedida → Cancelada)
   📲 Destino: Grupo 120363...@g.us
   ✅ Notificado: 1 mensaje(s) enviado(s)
```

En modo **producción**, el log mostrará:
```
   🔄 Auto-cierre: 1 reserva(s) procesada(s) (cancelacion)
   ✅ Reserva VH6QHS cerrada: Anulación pedida → Cancelada
```

### Verificar en WhatsApp

Las notificaciones incluirán una sección adicional:

**Dry-run (anulación):**
```
📧 Nueva respuesta sobre reserva

📨 De: Hotel Puyehue
...
💬 Resumen:
Hotel Puyehue: Confirmó anulación

🧪 [DRY-RUN] Reserva(s) cerrada(s) en dashboard:
• VH6QHS: Anulación pedida → Cancelada
```

**Producción (anulación):**
```
📧 Nueva respuesta sobre reserva

📨 De: Hotel Puyehue
...
💬 Resumen:
Hotel Puyehue: Confirmó anulación

✅ Reserva(s) cerrada(s) en dashboard:
• VH6QHS: Anulación pedida → Cancelada
```

**Producción (modificación con cambios de datos - NUEVO):**
```
📧 Nueva respuesta sobre reserva

📨 De: Hotel Puyehue
...
💬 Resumen:
Hotel Puyehue: Confirmó modificación de fechas

✅ Reserva(s) cerrada(s) en dashboard:
• V2K67A: Modificación pedida → Confirmada (check_in 2026-11-14→2026-11-16, check_out 2026-11-18→2026-11-20, total_amount 1676.25→1800)
```

### Verificar en el Dashboard

Los cambios de tarifa y fechas son **visibles automáticamente** en el dashboard:

**Dashboard → Sección Reservas:**
- Las reservas con cambios de tarifa muestran un badge **ámbar "Tarifa modificada"** 🔶
  - Tooltip: muestra el monto anterior → nuevo (ej: "$1,676.25 → $1,800")
- Las reservas con cambios de fechas muestran un badge **ámbar "Fechas modificadas"** 📅
  - Tooltip: muestra las fechas anteriores → nuevas (ej: "Check-in: 14/11/2026 → 16/11/2026")
- Los badges aparecen junto al precio o fechas correspondientes

**Ejemplo visual:**
```
Código: V2K67A
...
Fechas: 
  Entrada: 16/11/2026
  Salida: 20/11/2026
  [📅 Fechas modificadas] ← Badge con tooltip

Total: $1,800
  [🔶 Tarifa modificada] ← Badge con tooltip
```

### Verificar en Supabase

Después de que el monitor procese un correo de confirmación:

1. Ir a Supabase → Table Editor → `reservations`
2. Buscar por `reservation_code` (ej: VH6QHS)
3. Verificar:
   - `status` cambió a `Cancelada` o `Confirmada`
   - `notes` tiene una línea de auditoría:
     ```
     [03/11/2026] Auto-cerrado por email-monitor: Hotel Puyehue (reservas@hotelpuyehue.cl) confirmó - N° cancelación: 600986202
     ```
     O para modificaciones con cambios de datos:
     ```
     [03/11/2026] Auto-cerrado por email-monitor: Hotel Puyehue (reservas@hotelpuyehue.cl) confirmó; check_in 2026-11-14→2026-11-16; check_out 2026-11-18→2026-11-20
     ```
   - `updated_at` se actualizó
   - **(NUEVO) Para modificaciones:** Verificar si los campos `check_in`, `check_out` y/o `total_amount` fueron actualizados según corresponda

## 🛡️ Casos NO Procesados (Safety)

El sistema **NO** cierra automáticamente cuando detecta:

### 1. Hotel no puede/no confirma
```
"Lamentablemente el hotel no confirmó la anulación"
"No es posible cancelar sin cargo"
"El hotel no acepta la modificación"
```

### 2. Hay penalidad o cargo
```
"Quedará anulada pero debe abonar una penalidad"
"Tiene cargo por cancelación del 50%"
"Deberá pagar una tarifa"
```

### 3. Remitente interno
- checkin24hs.com
- checkin24hs@gmail.com
- axelbisio@hotmail.com

### 4. No encuentra código de reserva
- Si el correo no menciona ningún código válido

### 5. No encuentra reserva abierta
- Si el código no existe en Supabase
- Si la reserva ya está en otro estado (no es `Anulación pedida`, `Modificación pedida` ni `En gestión`)

### 6. Modificación sin datos claros (NUEVO)
```
"Hemos procesado la modificación solicitada"
```
- Si el hotel confirma una modificación pero NO se pueden extraer las fechas nuevas ni la tarifa nueva del email
- En este caso, NO se auto-cierra y se marca como "requiere revisión manual"
- Se notifica al equipo por WhatsApp con la advertencia

## 📊 Auditoría

Cada cierre automático queda registrado en:

### 1. Campo `notes` de la reserva

**Para anulaciones:**
```
[03/11/2026] Auto-cerrado por email-monitor: Hotel Puyehue (reservas@hotelpuyehue.cl) confirmó - N° cancelación: 600986202
```

**Para modificaciones con cambios de datos:**
```
[03/11/2026] Auto-cerrado por email-monitor: Hotel Puyehue (reservas@hotelpuyehue.cl) confirmó; check_in 2026-11-14→2026-11-16; check_out 2026-11-18→2026-11-20; total_amount 1676.25→1800
```

### 2. Campo `updated_at`
Se actualiza con el timestamp del procesamiento

### 3. Tabla `email_monitor_notifications`
Se registra el correo procesado con `status='notified'`

### 4. Notificación WhatsApp
Incluye la información del cierre para visibilidad del equipo

## 🔍 Detección de Códigos

### Códigos alfanuméricos
- 1-2 letras mayúsculas + 4-6 caracteres alfanuméricos
- Debe contener al menos 1 dígito
- Ejemplos: `V2K67A`, `VH6QHS`, `VG52SH`, `VX6KZM`, `V3X98B`

### Códigos numéricos
- 8-9 dígitos
- Con contexto: después de palabras como "reserva", "código", "n°", etc.
- Sin contexto: al final del subject o después del nombre del hotel
- Ejemplos: `598854662`, `600986202`, `597003333`

### Búsqueda en thread completo
El sistema busca códigos en:
- Subject del correo
- Body del correo
- Mensajes citados (`> El ... escribió: ...`)
- Firmas

## 🔍 Detección de Cambios de Datos (Modificaciones)

Cuando el hotel confirma una **modificación**, el sistema intenta detectar automáticamente qué datos cambiaron:

### Extracción de fechas nuevas
Busca patrones como:
- ISO: `2026-11-16`
- DD/MM/YYYY: `16/11/2026`
- Contexto: "Check-in: ...", "nuevas fechas: ...", etc.

### Extracción de tarifa nueva
Busca patrones como:
- Con símbolo: `$1800`, `USD 1800`
- Sin símbolo con contexto: "total: 1800", "tarifa nueva: 1800"

### Criterio conservador
- Si NO se pueden extraer fechas ni tarifa del email → **NO auto-cierra**
- Si solo se extrae fecha o solo tarifa → actualiza solo ese dato
- Si los datos extraídos son ambiguos → **NO auto-cierra**
- El sistema marca como "requiere revisión manual" y notifica al equipo

## 📊 Visualización en el Dashboard

### Indicadores Visuales de Cambios

El dashboard detecta automáticamente cambios de tarifa y fechas **parseando el campo `notes`** (sin necesidad de cambiar el esquema de la base de datos).

**Badges mostrados:**

1. **Tarifa modificada** 🔶
   - Badge ámbar junto al precio
   - Tooltip: "$1,676.25 → $1,800"
   - Solo aparece si el campo `notes` contiene el patrón `total_amount X→Y`

2. **Fechas modificadas** 📅
   - Badge ámbar junto a las fechas
   - Tooltip: "Check-in: 14/11/2026 → 16/11/2026 | Check-out: 18/11/2026 → 20/11/2026"
   - Solo aparece si el campo `notes` contiene patrones `check_in X→Y` o `check_out X→Y`

### Implementación sin cambio de esquema

La solución actual NO requiere agregar columnas a la base de datos:
- Parsea el campo `notes` existente en tiempo de renderizado
- Performance adecuada para el volumen típico de reservas
- Sin impacto en la BD de producción

### Migración opcional (para optimización futura)

Si en el futuro se necesita filtrar/consultar reservas con cambios de forma más eficiente:
- Ver archivo `supabase-migrations/OPTIONAL_090_reservation_change_flags.sql`
- Agrega columnas `has_amount_change` y `has_date_change` (booleanas)
- **NO ejecutar** a menos que se decida explícitamente optimizar

## 🚨 Troubleshooting

### El auto-cierre no detecta un código
1. Verificar que el código esté en el formato correcto
2. Revisar logs del monitor (ver sección siguiente)
3. Ejecutar tests: `npm test` en `email-monitor/`

### Se cerró una reserva incorrectamente
1. La auditoría en `notes` muestra el email original
2. Desactivar temporalmente: `AUTO_CLOSE_RESERVATIONS=0`
3. Reportar el caso para agregar al test suite

### Quiero solo ver qué se cerraría sin ejecutar
```bash
AUTO_CLOSE_RESERVATIONS=1
AUTO_CLOSE_DRY_RUN=1
```

### Una modificación no actualizó los datos correctamente
1. Verificar en Supabase los campos `check_in`, `check_out` y `total_amount`
2. Revisar el campo `notes` para ver qué cambios se aplicaron
3. Si los datos del email eran ambiguos, el sistema NO auto-cierra (verificar logs)

## 🔧 Deployment y Logs

### El monitor corre por cron (cada 15 minutos)

El email-monitor se ejecuta automáticamente cada 15 minutos mediante **cron**, no systemd. Esto significa:

- **No requiere reinicio** al cambiar variables de entorno en `.env`
- Los cambios toman efecto en la próxima ejecución (máximo 15 minutos)
- Para verificar logs: 
  ```bash
  # Logs de cron (depende del sistema)
  sudo tail -f /var/log/syslog | grep CRON
  
  # O revisar el archivo de log del monitor si está configurado
  tail -f /path/to/email-monitor.log
  ```

### Ejecución manual para testing
```bash
cd email-monitor
node monitor.js --dry-run
```

## 📞 Soporte

Para dudas o problemas:
1. Revisar logs del monitor (ver sección Deployment)
2. Ejecutar tests: `npm test` en `email-monitor/`
3. Ejecutar en dry-run manual: `node monitor.js --dry-run`
4. Contactar a German o al equipo de desarrollo
