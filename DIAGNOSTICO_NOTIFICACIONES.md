# 📋 Diagnóstico: Sistemas de Notificaciones

## 🎯 Sistemas Identificados

Hay **3 sistemas independientes** de notificaciones:

### 1. **ANA** (Ana Copilot)
- **Ubicación**: `ana/` + `whatsapp-server/ana-copilot-bridge.js`
- **Servicio Docker**: `checkin24hs_ana` (ana.checkin24hs.com)
- **Puerto**: 8080
- **Función**: 
  - Recibe mensajes de WhatsApp de números ejecutivos (542944210725, 5492944579759)
  - Envía a `https://ana.checkin24hs.com/api/copilot/inbound`
  - Jobs automáticos vía cron (flash matutino, fricción Flor, QA semanal, etc.)

### 2. **EMAIL MONITOR** 
- **Ubicación**: `email-monitor/monitor.js`
- **Función**:
  - Monitorea buzón reservas@checkin24hs.com vía IMAP
  - Filtra emails de hoteles y proveedores
  - Notifica al equipo vía WhatsApp (grupo o números individuales)
  - Estado: Configurado vía cron (merged en PR #1)

### 3. **NO STOP** 
- **Estado**: ❓ **NO ENCONTRADO en el código**
- Posibles ubicaciones/nombres:
  - ¿Servicio de monitoreo continuo no documentado?
  - ¿Referencia a otro sistema externo?
  - ¿Nombre interno para algún servicio?

---

## 🔍 Diagnóstico por Sistema

### 1. ANA Copilot

#### Verificar Estado del Servicio

```bash
# 1. Verificar si el contenedor está corriendo
docker ps | grep ana

# 2. Ver logs recientes
docker service logs checkin24hs_ana --tail 100

# 3. Verificar health del servicio
curl -s https://ana.checkin24hs.com/health || echo "No responde"

# 4. Verificar cron jobs están configurados
crontab -l | grep ana
```

#### Verificar Configuración

```bash
# Variables de entorno críticas
docker service inspect checkin24hs_ana --format '{{json .Spec.TaskTemplate.ContainerSpec.Env}}' | jq | grep -E "ANA_JOBS_SECRET|GEMINI_API_KEY|SUPABASE"
```

#### Posibles Problemas

1. **Servicio caído**:
   ```bash
   docker service ps checkin24hs_ana
   # Si muestra "Failed" o no hay réplica running
   ```

2. **Jobs cron no configurados**:
   ```bash
   crontab -l | grep "ana.checkin24hs.com"
   # Si no hay salida, los jobs no están configurados
   ```

3. **Secreto ANA_JOBS_SECRET incorrecto**:
   - Los cron jobs llaman a `/api/jobs/*` con header `X-Ana-Jobs-Secret`
   - Si el secreto no coincide, devuelve 401/403

4. **GEMINI_API_KEY inválida o sin cuota**:
   - Ana usa Gemini para procesar mensajes
   - Sin API key válida, falla el procesamiento

#### Solución si está caído

```bash
# Redesplegar servicio Ana
cd /root/checkin24hs
docker compose -f docker-compose.ana.yml up -d --build

# Verificar que levantó
docker ps | grep ana

# Configurar cron jobs (si no existen)
# Editar con: crontab -e
# Copiar contenido de: ana/crontab.example
# Reemplazar SECRET por el valor de ANA_JOBS_SECRET
```

---

### 2. Email Monitor

#### Verificar Estado

```bash
# 1. Verificar si está en cron
crontab -l | grep "email-monitor"

# 2. Ver logs recientes
tail -100 /var/log/email-monitor.log

# 3. Test manual (dry-run)
cd /root/checkin24hs/email-monitor
node monitor.js --dry-run

# 4. Verificar última ejecución
ls -lah /root/checkin24hs/email-monitor/*.log
```

#### Configuración Esperada (PR #1)

Cron job debería ejecutarse cada X minutos:
```cron
*/10 * * * * cd /root/checkin24hs/email-monitor && node monitor.js >> /var/log/email-monitor.log 2>&1
```

#### Posibles Problemas

1. **Cron job no configurado**:
   ```bash
   crontab -l | grep email-monitor
   # Si no hay salida, no está configurado
   ```

2. **Variables de entorno faltantes**:
   ```bash
   cd /root/checkin24hs/email-monitor
   cat .env | grep -E "IMAP_|WHATSAPP_|SUPABASE_"
   # Verificar que IMAP_USER, IMAP_PASS, WHATSAPP_API_KEY existen
   ```

3. **IMAP credenciales inválidas**:
   ```bash
   cd /root/checkin24hs/email-monitor
   node monitor.js --dry-run
   # Si falla con "IMAP authentication failed"
   ```

4. **WhatsApp API no responde**:
   ```bash
   # Verificar que el endpoint de WhatsApp funciona
   curl -H "x-api-key: XXXX" https://whatsapp.checkin24hs.com/api/status
   ```

#### Solución si no funciona

```bash
# 1. Verificar configuración
cd /root/checkin24hs/email-monitor
cat .env

# 2. Test manual
node monitor.js --dry-run

# 3. Si el test funciona, configurar cron
crontab -e
# Agregar línea:
*/10 * * * * cd /root/checkin24hs/email-monitor && node monitor.js >> /var/log/email-monitor.log 2>&1

# 4. Verificar que cron está activo
crontab -l | grep email-monitor

# 5. Forzar ejecución inmediata
cd /root/checkin24hs/email-monitor && node monitor.js
```

---

### 3. NO STOP

#### Estado: NO ENCONTRADO

No hay referencias en el código a "No Stop", "nostop", o "no-stop".

**Posibilidades**:

1. **Nombre interno/informal**:
   - Puede referirse a algún servicio que NO debe detenerse (always-on)
   - Ejemplo: Ana Copilot jobs que corren 24/7

2. **Servicio externo no documentado**:
   - Sistema de monitoreo de terceros (ej. UptimeRobot, StatusCake)
   - Alertas de infraestructura

3. **Confusión de nombres**:
   - ¿Se refiere a las notificaciones del email-monitor (que debe correr sin parar)?
   - ¿Se refiere a los cron jobs de Ana (que corren continuamente)?

#### Acción Requerida

**Preguntas para el usuario**:

1. ¿"No Stop" es el nombre de un servicio específico o se refiere a que las notificaciones deben ser continuas?

2. ¿Dónde esperarías ver las notificaciones de "No Stop"?
   - ¿WhatsApp?
   - ¿Email?
   - ¿Panel de Ana?
   - ¿Otro canal?

3. ¿Qué tipo de eventos debería notificar "No Stop"?
   - ¿Reservas?
   - ¿Errores del sistema?
   - ¿Monitoreo de servicios?

---

## 🔧 Comandos de Diagnóstico Rápido

### Verificar TODOS los servicios

```bash
#!/bin/bash
echo "=== DIAGNÓSTICO NOTIFICACIONES ==="
echo ""

echo "1. SERVICIO ANA"
docker ps | grep ana && echo "✅ Ana corriendo" || echo "❌ Ana NO corriendo"
curl -sf https://ana.checkin24hs.com/health > /dev/null && echo "✅ Ana responde" || echo "❌ Ana NO responde"
crontab -l | grep -q "ana.checkin24hs.com" && echo "✅ Cron jobs configurados" || echo "❌ Cron jobs NO configurados"
echo ""

echo "2. EMAIL MONITOR"
crontab -l | grep -q "email-monitor" && echo "✅ Cron configurado" || echo "❌ Cron NO configurado"
[ -f /var/log/email-monitor.log ] && echo "✅ Log existe: $(ls -lh /var/log/email-monitor.log | awk '{print $5" "$6" "$7}')" || echo "❌ Log NO existe"
[ -f /root/checkin24hs/email-monitor/.env ] && echo "✅ .env existe" || echo "❌ .env NO existe"
echo ""

echo "3. NO STOP"
echo "❓ Sistema no identificado en código"
echo ""

echo "=== FIN DIAGNÓSTICO ==="
```

### Verificar Logs

```bash
# Logs de Ana
docker service logs checkin24hs_ana --tail 50

# Logs de Ana cron jobs
tail -50 /var/log/ana-jobs.log

# Logs de Email Monitor
tail -50 /var/log/email-monitor.log
```

---

## 📝 Próximos Pasos

1. **Ejecutar diagnóstico rápido en servidor**:
   ```bash
   bash /root/checkin24hs/scripts/diagnostico-notificaciones.sh
   ```

2. **Revisar logs de cada sistema**

3. **Aclarar qué es "No Stop"** con el usuario

4. **Crear fixes específicos según lo encontrado**

---

## 🚀 Acciones Inmediatas Sugeridas

### Si Ana no funciona:
```bash
cd /root/checkin24hs
docker compose -f docker-compose.ana.yml up -d --build
# Esperar 30 segundos
curl https://ana.checkin24hs.com/health
# Configurar cron (ver ana/crontab.example)
```

### Si Email Monitor no funciona:
```bash
cd /root/checkin24hs/email-monitor
node monitor.js --dry-run
# Si funciona:
crontab -e
# Agregar: */10 * * * * cd /root/checkin24hs/email-monitor && node monitor.js >> /var/log/email-monitor.log 2>&1
```

### Para "No Stop":
- Aclarar con usuario qué sistema es
- Buscar en documentación/Slack/emails
- Revisar servicios externos (UptimeRobot, etc.)
