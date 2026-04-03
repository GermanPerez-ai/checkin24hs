# 🔧 Solución: Encontrar Puerto Libre

## ✅ Confirmación

- ✅ El servidor funciona correctamente (responde con HTML)
- ✅ La IP `10.11.124.79:3000` es accesible
- ❌ El puerto 30001 está en uso

## 🔍 Encontrar Puerto Libre

```bash
# 1. Ver qué puertos están en uso
sudo netstat -tuln | grep -E ':(300[0-9]|301[0-9]|302[0-9])' | awk '{print $4}' | cut -d: -f2 | sort -n

# 2. O ver puertos de servicios Docker
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E ':(300[0-9]|301[0-9]|302[0-9])'

# 3. Probar puertos comunes libres (empezar desde 30002)
for port in 30002 30003 30004 30005; do
  if ! sudo netstat -tuln | grep -q ":$port "; then
    echo "Puerto $port está libre"
  else
    echo "Puerto $port está en uso"
  fi
done
```

## ✅ Solución: Usar Puerto Libre (ej: 30002)

```bash
# 1. Agregar puerto 30002 en modo host -> 3000 interno
docker service update \
  --publish-add published=30002,target=3000,protocol=tcp,mode=host \
  checkin24hs_dashboard

# 2. Esperar
sleep 5

# 3. Verificar que se agregó
docker service inspect checkin24hs_dashboard --format '{{json .Endpoint.Ports}}' | jq

# 4. Probar con el nuevo puerto
curl http://localhost:30002 | head -20

# 5. Probar desde Traefik usando el alias con puerto 30002
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:30002 2>&1 | head -20
```

## 🔧 Configuración en EasyPanel

Una vez que funcione con el puerto libre (ej: 30002):

1. **Ve a EasyPanel** → **Servicios** → **dashboard** → **Dominios**
2. **Edita el dominio** del dashboard
3. **Puerto**: Usa el puerto libre encontrado (ej: `30002`)
4. **Target Service**: `checkin24hs-dashboard` (con guión)
5. **Guarda** los cambios

## 🎯 Alternativa: Usar IP Directa en Traefik

Si no quieres usar un puerto adicional, puedes configurar Traefik para usar la IP directamente, pero esto no es recomendado porque la IP puede cambiar cuando el servicio se reinicia.

