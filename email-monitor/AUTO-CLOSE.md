# Auto-Cierre de Reservas

## 📋 Descripción

Funcionalidad que detecta automáticamente cuando un hotel o proveedor confirma una cancelación o modificación de reserva por email, y actualiza el estado correspondiente en Supabase (tabla `public.reservations`).

Esto evita que Ana siga alertando sobre reservas que ya fueron confirmadas por el hotel.

## 🎯 Casos de Uso

### Estados que se cierran automáticamente:
- `Anulación pedida` → `Cancelada` (cuando el hotel confirma la anulación)
- `Modificación pedida` → `Confirmada` (cuando el hotel confirma la modificación)
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

**Dry-run:**
```
📧 Nueva respuesta sobre reserva

📨 De: Hotel Puyehue
...
💬 Resumen:
Hotel Puyehue: Confirmó anulación

🧪 [DRY-RUN] Reserva(s) cerrada(s) en dashboard:
• VH6QHS: Anulación pedida → Cancelada
```

**Producción:**
```
📧 Nueva respuesta sobre reserva

📨 De: Hotel Puyehue
...
💬 Resumen:
Hotel Puyehue: Confirmó anulación

✅ Reserva(s) cerrada(s) en dashboard:
• VH6QHS: Anulación pedida → Cancelada
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
   - `updated_at` se actualizó

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

## 📊 Auditoría

Cada cierre automático queda registrado en:

### 1. Campo `notes` de la reserva
```
[03/11/2026] Auto-cerrado por email-monitor: Hotel Puyehue (reservas@hotelpuyehue.cl) confirmó - N° cancelación: 600986202
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

## 🚨 Troubleshooting

### El auto-cierre no detecta un código
1. Verificar que el código esté en el formato correcto
2. Revisar logs: `journalctl -u email-monitor -f`
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

## 📞 Soporte

Para dudas o problemas:
1. Revisar logs del monitor
2. Ejecutar tests: `npm test`
3. Contactar a German o al equipo de desarrollo
