# ✅ Probar Acceso Directo por IP

## 🎯 IP Obtenida

- **IP del contenedor**: `10.0.2.44`

## ✅ Comando para Ejecutar

```bash
# Probar acceso directo por IP
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://10.0.2.44:3000/
```

Si esto funciona (devuelve 200), el servicio está funcionando correctamente y el problema es solo la resolución DNS de los aliases.

## 🔍 Análisis

- **Si funciona por IP**: El servicio está bien, el problema es la resolución DNS de los aliases
- **Si no funciona por IP**: Hay un problema con el servicio mismo

---

**Ejecuta el comando con la IP 10.0.2.44 y comparte el resultado.**
