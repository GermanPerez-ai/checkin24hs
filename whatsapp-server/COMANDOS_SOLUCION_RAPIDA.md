# 🚀 Comandos Rápidos para Solucionar Autenticación Fallida

## ⚡ Solución Rápida (Copia y Pega)

Ejecuta estos comandos en orden:

```bash
# 1. Encontrar el contenedor
CONTAINER_ID=$(docker ps | grep checkin24hs_whatsapp | awk '{print $1}')

# 2. Verificar que existe
echo "Contenedor: $CONTAINER_ID"

# 3. Limpiar sesión
docker exec $CONTAINER_ID rm -rf /app/auth_info_baileys_1

# 4. Reiniciar servicio
docker service update --force checkin24hs_whatsapp

# 5. Esperar 30 segundos
echo "Esperando 30 segundos..."
sleep 30

# 6. Ver logs para confirmar
docker service logs checkin24hs_whatsapp --tail 20
```

## 📋 Checklist ANTES de Escanear el QR

**EN TU TELÉFONO (MUY IMPORTANTE):**

1. ✅ Abre WhatsApp
2. ✅ Ve a **Configuración** → **Dispositivos vinculados**
3. ✅ **Desconecta TODAS las sesiones** (Chrome, Desktop, etc.)
4. ✅ **Cierra completamente WhatsApp** (no solo minimizar)
5. ✅ Espera 10 segundos
6. ✅ Vuelve a abrir WhatsApp
7. ✅ **Desactiva WiFi, activa DATOS MÓVILES**
8. ✅ Ve a **Dispositivos vinculados** → **Vincular un dispositivo**
9. ✅ Escanea el QR **INMEDIATAMENTE** (dentro de 2 minutos)
10. ✅ **NO cierres WhatsApp** durante la autenticación
11. ✅ Espera 2-5 minutos pacientemente

## 🔍 Verificar Estado

```bash
# Ver estado del servicio
curl http://localhost:3001/api/status

# Ver logs en tiempo real
docker service logs checkin24hs_whatsapp --tail 50 -f
```

## 🆘 Si Sigue Sin Funcionar

```bash
# Verificar recursos del contenedor
docker stats $(docker ps | grep checkin24hs_whatsapp | awk '{print $1}')

# Verificar conectividad a WhatsApp
ping -c 5 web.whatsapp.com
```
