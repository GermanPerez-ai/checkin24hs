# 📊 Resumen de Verificaciones de WhatsApp

## 🔍 Estado Actual

Según las verificaciones realizadas desde Windows:
- **Ninguna instancia responde** desde fuera del servidor (puertos 3001-3004 y 4001-4004)
- Esto es **normal** si los servicios solo están accesibles desde el servidor mismo

## 📋 Configuración Encontrada

Según `ecosystem.config.js`, las instancias están configuradas así:

| Instancia | Nombre PM2 | Puerto | Estado Esperado |
|-----------|------------|--------|-----------------|
| WhatsApp 1 | whatsapp-1 | 4001 | Debe estar corriendo |
| WhatsApp 2 | whatsapp-2 | 4002 | Debe estar corriendo |
| WhatsApp 3 | whatsapp-3 | 4003 | Debe estar corriendo |
| WhatsApp 4 | whatsapp-4 | 4004 | Debe estar corriendo |

**Nota:** También hay referencias a puertos 3001-3004 en algunos scripts, pero la configuración PM2 usa 4001-4004.

## ✅ Cómo Verificar Conexiones Activas

### Opción 1: Desde el Servidor (Recomendado)

Conéctate al servidor y ejecuta:

```bash
# 1. Ver procesos PM2
pm2 list

# 2. Verificar puertos activos
netstat -tulpn | grep -E "3001|3002|3003|3004|4001|4002|4003|4004"
# O con ss:
ss -tulpn | grep -E "3001|3002|3003|3004|4001|4002|4003|4004"

# 3. Verificar estado vía API (desde el servidor)
curl http://localhost:4001/api/status
curl http://localhost:4002/api/status
curl http://localhost:4003/api/status
curl http://localhost:4004/api/status

# 4. Ver logs de una instancia
pm2 logs whatsapp-1 --lines 20 --nostream

# 5. Ejecutar script completo de verificación
bash /root/checkin24hs/EJECUTAR_TODAS_VERIFICACIONES.sh
```

### Opción 2: Desde Windows (SSH)

```powershell
# Ver procesos PM2
ssh root@72.61.58.240 "pm2 list"

# Verificar puertos
ssh root@72.61.58.240 "netstat -tulpn | grep -E '3001|3002|3003|3004|4001|4002|4003|4004'"

# Ver estado de una instancia
ssh root@72.61.58.240 "curl -s http://localhost:4001/api/status | head -10"

# Ejecutar script completo
ssh root@72.61.58.240 "bash /root/checkin24hs/EJECUTAR_TODAS_VERIFICACIONES.sh"
```

### Opción 3: Consultar Base de Datos (Supabase)

Ejecuta en Supabase SQL Editor:

```sql
-- Ver todas las conexiones
SELECT 
    card_number AS "Número",
    status AS "Estado",
    phone AS "Teléfono",
    name AS "Nombre",
    connected_at AS "Conectado el"
FROM whatsapp_cards
ORDER BY card_number;

-- Resumen de conexiones activas
SELECT 
    COUNT(*) FILTER (WHERE status = 'connected') AS "Conexiones activas",
    COUNT(*) FILTER (WHERE status = 'connecting') AS "Conectando",
    COUNT(*) FILTER (WHERE status = 'disconnected') AS "Desconectadas",
    COUNT(*) AS "Total"
FROM whatsapp_cards;
```

## 🛠️ Scripts Creados

1. **EJECUTAR_TODAS_VERIFICACIONES.ps1** - Script PowerShell para Windows
2. **EJECUTAR_TODAS_VERIFICACIONES.sh** - Script Bash para el servidor
3. **CONSULTAR_CONEXIONES_WHATSAPP.ps1** - Script simple de consulta
4. **CONSULTAR_CONEXIONES_WHATSAPP.sql** - Consultas SQL para Supabase

## 📝 Próximos Pasos

1. **Subir el script bash al servidor:**
   ```bash
   scp EJECUTAR_TODAS_VERIFICACIONES.sh root@72.61.58.240:/root/checkin24hs/
   ```

2. **Ejecutar en el servidor:**
   ```bash
   ssh root@72.61.58.240
   cd /root/checkin24hs
   chmod +x EJECUTAR_TODAS_VERIFICACIONES.sh
   bash EJECUTAR_TODAS_VERIFICACIONES.sh
   ```

3. **Revisar resultados** y verificar qué instancias están activas

## 🔧 Comandos Útiles PM2

```bash
# Ver todos los procesos
pm2 list

# Ver información detallada de una instancia
pm2 describe whatsapp-1

# Ver logs en tiempo real
pm2 logs whatsapp-1

# Ver logs de todas las instancias
pm2 logs

# Reiniciar una instancia
pm2 restart whatsapp-1

# Reiniciar todas
pm2 restart all

# Ver uso de recursos
pm2 monit

# Guardar configuración
pm2 save
```




