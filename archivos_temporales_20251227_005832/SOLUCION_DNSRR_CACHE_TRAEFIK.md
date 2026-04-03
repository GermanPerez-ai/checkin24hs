# 🔧 Solución: DNSRR y Cache de Traefik

## Estado Actual

✅ **Modo cambiado a DNSRR:** El servicio ahora usa DNSRR
✅ **Resolución funciona:** `checkin24hs_whatsapp-api` → `10.11.135.107`
❌ **Traefik usa IP antigua:** Sigue intentando `10.11.135.100` (VIP antiguo en cache)

## Solución: Reiniciar Traefik para Limpiar Cache

Traefik tiene cacheada la IP antigua. Necesitamos reiniciarlo para que actualice la resolución DNS.

### Opción 1: Reiniciar Traefik

```bash
# Reiniciar Traefik
docker restart traefik.1.7x4x0qy3w08b8ob9ontssyjb4

# Esperar unos segundos
sleep 10

# Probar acceso de nuevo
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://checkin24hs_whatsapp-api:80/api1/api/qr?card=1
```

---

### Opción 2: Verificar IP Real del Contenedor

```bash
# Ver IP actual del contenedor
docker inspect checkin24hs_whatsapp-api.1.utlbp6ay4muqwvr09relwi3cm | grep -A 10 '"easypanel"' | grep IPAddress

# Probar acceso directo a la nueva IP
docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://10.11.135.107:80/api1/api/qr?card=1
```

---

### Opción 3: Probar desde el Navegador

Después de reiniciar Traefik, prueba directamente:

```bash
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1
```

---

## Próximos Pasos

1. **Reinicia Traefik:** `docker restart traefik.1.7x4x0qy3w08b8ob9ontssyjb4`
2. **Espera 10-15 segundos**
3. **Prueba:** `curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1`
4. **Si no funciona:** Ejecuta: `docker exec traefik.1.7x4x0qy3w08b8ob9ontssyjb4 wget -qO- http://10.11.135.107:80/api1/api/qr?card=1`

¡Con esto debería funcionar! 🎉


