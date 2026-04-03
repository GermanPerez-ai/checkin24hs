# 🔧 Solución: Puertos Duplicados en el Servicio

## 🔍 Problema

El error `"duplicate published ports provided"` indica que el puerto 30002 está configurado dos veces (probablemente una vez en modo `host` y otra en modo `ingress`).

Sin embargo, **el servicio está corriendo** y los logs muestran:
```
🚀 Servidor iniciado en http://localhost:3000
📊 API disponible en http://localhost:3000/api/puyehue-quote
🌐 Frontend disponible en http://localhost:3000
```

Esto significa que **el servidor está funcionando**, pero puede haber problemas de acceso debido a los puertos duplicados.

---

## ✅ Solución: Limpiar Puertos Duplicados

Ejecuta este comando completo en SSH:

```bash
echo "🔧 Limpiando puertos duplicados..." && docker service scale checkin24hs_checkin24hs-dashboard=0 && sleep 10 && docker service update --publish-rm 30002 checkin24hs_checkin24hs-dashboard && sleep 5 && docker service inspect checkin24hs_checkin24hs-dashboard --format '{{json .Endpoint.Ports}}' | jq && docker service update --publish-add published=30002,target=3000,protocol=tcp,mode=ingress checkin24hs_checkin24hs-dashboard && sleep 5 && docker service scale checkin24hs_checkin24hs-dashboard=1 && sleep 15 && docker service ps checkin24hs_checkin24hs-dashboard && curl -I http://localhost:30002 2>&1 | head -5
```

---

## 🎯 Verificación Rápida

Primero, **prueba si ya funciona**:

```bash
# Probar desde el servidor
curl http://localhost:30002 | head -20

# Verificar estado
docker service ps checkin24hs_checkin24hs-dashboard
```

Si funciona desde el servidor pero no desde fuera, el problema es de red/firewall.

---

## ✅ Si el Servicio Ya Está Funcionando

Si los logs muestran que el servidor está iniciado, **prueba acceder directamente**:

1. **Desde el navegador**: `http://72.61.58.240:30002`
2. **Si no funciona**, prueba limpiar los puertos duplicados con el comando de arriba

---

## 🔍 Verificar Estado Actual

Ejecuta esto para ver el estado completo:

```bash
echo "🔍 Estado completo:" && echo "" && echo "1. Estado del servicio:" && docker service ps checkin24hs_checkin24hs-dashboard && echo "" && echo "2. Puertos configurados:" && docker service inspect checkin24hs_checkin24hs-dashboard --format '{{json .Endpoint.Ports}}' | jq && echo "" && echo "3. Probar conexión local:" && curl -I http://localhost:30002 2>&1 | head -5 && echo "" && echo "4. Ver contenido:" && curl http://localhost:30002 2>&1 | head -20
```

---

## 🎯 Próximos Pasos

1. **Prueba acceder**: `http://72.61.58.240:30002`
2. **Si no funciona**, ejecuta el comando de limpieza de puertos
3. **Si sigue sin funcionar**, verifica el firewall o prueba con otro puerto


