# 🔍 Verificar Puertos WhatsApp

## Problema Detectado

Solo el puerto **3001** está escuchando. Los puertos **3002, 3003, 3004** NO están escuchando.

## Verificaciones Necesarias

### 1. Verificar en qué puertos están escuchando los servicios WhatsApp

```bash
# Ver todos los puertos que están escuchando
netstat -tlnp | grep node

# O más específico
ss -tlnp | grep node

# Ver procesos de Node.js y sus puertos
lsof -i -P -n | grep node | grep LISTEN
```

### 2. Verificar configuración de los servicios WhatsApp

```bash
# Ver el archivo de configuración del servidor WhatsApp
cat /root/checkin24hs/whatsapp-server/whatsapp-server.js | grep -E '(port|PORT|300)'

# Ver si hay variables de entorno
ps aux | grep whatsapp-server | grep -E '(PORT|port)'
```

### 3. Verificar logs de los servicios

```bash
# Ver logs del servicio (si están en archivos)
tail -f /root/checkin24hs/whatsapp-server/logs/*.log

# O verificar si hay logs en la consola
# (necesitarías ver cómo están iniciados los procesos)
```

---

## Solución Probable

Los servicios WhatsApp probablemente están configurados para escuchar en puertos diferentes, o solo uno está configurado correctamente.

### Opción A: Verificar configuración de puertos

Los servicios WhatsApp necesitan estar configurados para escuchar en:
- Servicio 1: Puerto 3001
- Servicio 2: Puerto 3002
- Servicio 3: Puerto 3003
- Servicio 4: Puerto 3004

### Opción B: Verificar cómo están iniciados

```bash
# Ver cómo están iniciados los procesos
ps aux | grep whatsapp-server.js

# Ver el comando completo de inicio
ps -ef | grep whatsapp-server
```

---

## Próximos Pasos

Ejecuta estos comandos y comparte los resultados:

1. `lsof -i -P -n | grep node | grep LISTEN`
2. `cat /root/checkin24hs/whatsapp-server/whatsapp-server.js | head -50`
3. `ps aux | grep whatsapp-server.js | head -5`

Con esta información podremos identificar por qué solo el puerto 3001 está escuchando.
