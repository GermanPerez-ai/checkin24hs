# Solucionar Conflict 440, Bad MAC y Limpiar Sesión WhatsApp

Cuando aparecen errores **440 (conflict/replaced)**, **Bad MAC** o **No matching sessions**, la sesión de Baileys está corrupta o hay múltiples procesos usando la misma cuenta.

---

## 1. Detener procesos duplicados (Conflict 440)

El error **440 / type: replaced** indica que **dos procesos** están usando la misma sesión de WhatsApp.

### En el servidor (SSH):

```bash
# Ver TODOS los contenedores de WhatsApp
docker ps -a | grep -i whatsapp

# Deberías ver solo UNO del servicio Swarm: checkin24hs_whatsapp.1.xxx
# Si ves OTRO (ej. checkin24hs-whatsapp-1 de docker-compose), detenelo:
docker stop checkin24hs-whatsapp-1
docker rm checkin24hs-whatsapp-1

# Verificar réplicas del servicio Swarm (debe ser 1)
docker service ls | grep whatsapp
docker service scale checkin24hs_whatsapp=1

# Script rápido para diagnosticar
bash scripts/verificar_replicas_whatsapp.sh
```

---

## 2. Limpiar sesión y volver a vincular (Bad MAC)

Cuando hay **Bad MAC** o **No matching sessions**, las llaves de cifrado están corruptas. Hay que borrar el auth y escanear el QR de nuevo.

### En el servidor:

```bash
cd /root/checkin24hs  # o donde tengas el proyecto

# Detener el servicio
docker service scale checkin24hs_whatsapp=0

# Borrar el volumen de auth (nombre típico del stack)
docker volume ls | grep whatsapp
# Ejemplo: checkin24hs_whatsapp-auth

# Eliminar el volumen (cambia el nombre si es distinto)
docker volume rm checkin24hs_whatsapp-auth

# Levantar de nuevo (creará volumen vacío = pedirá QR)
docker service scale checkin24hs_whatsapp=1

# Ver logs para obtener el QR
docker service logs -f checkin24hs_whatsapp
```

Luego:
1. Entrá a **https://whatsapp.checkin24hs.com/qr** o **/api/qr**
2. Escaneá el QR con WhatsApp en el celular
3. Esperá a que muestre "Conectado"

---

## 3. Mensajes type: append

El código ahora procesa **notify** Y **append**. Los mensajes que llegaron mientras estabas desconectado (o anuncios) pueden venir por `append` y Flor los procesará.

---

## 4. Resumen de pasos

| Problema | Solución |
|----------|----------|
| 440 Conflict / replaced | Detener contenedores duplicados, asegurar `replicas: 1` |
| Bad MAC / No matching sessions | Borrar volumen `whatsapp-auth`, escalar a 0, luego a 1, escanear QR |
| Mensajes no procesados (append) | Ya corregido: se procesan notify y append |
| Bucle de reconexión | Delay de 90s para 440; detener duplicados evita el bucle |

---

## 5. Script rápido (copiar y pegar)

```bash
# En el servidor
docker service scale checkin24hs_whatsapp=0
sleep 5
docker volume rm checkin24hs_whatsapp-auth 2>/dev/null || true
docker service scale checkin24hs_whatsapp=1
echo "Esperá el QR en https://whatsapp.checkin24hs.com/qr"
```
