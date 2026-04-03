# 🔧 Solución: Puerto 30002 No Funciona

## 🔍 Diagnóstico Rápido

Ejecuta este comando en SSH para diagnosticar el problema:

```bash
echo "🔍 Diagnóstico..." && docker service ps checkin24hs_checkin24hs-dashboard --no-trunc | head -3 && echo "" && docker service inspect checkin24hs_checkin24hs-dashboard --format '{{json .Endpoint.Ports}}' 2>&1 | jq 2>&1 || docker service inspect checkin24hs_checkin24hs-dashboard --format '{{json .Endpoint.Ports}}' 2>&1 && echo "" && sudo netstat -tuln | grep 30002 && echo "" && docker service logs checkin24hs_checkin24hs-dashboard --tail 10
```

---

## 🔧 Soluciones Comunes

### Problema 1: El Servicio No Está Corriendo

**Síntomas:**
- El servicio aparece en estado "Pending" o "Shutdown"
- No hay contenedores corriendo

**Solución:**
```bash
# Verificar estado
docker service ps checkin24hs_checkin24hs-dashboard

# Si está en 0 réplicas, escalar a 1
docker service scale checkin24hs_checkin24hs-dashboard=1

# Esperar y verificar
sleep 10
docker service ps checkin24hs_checkin24hs-dashboard
```

---

### Problema 2: El Puerto No Está Publicado

**Síntomas:**
- El servicio está corriendo pero `netstat` no muestra el puerto 30002
- `docker service inspect` no muestra el puerto en `Endpoint.Ports`

**Solución:**
1. Ve a EasyPanel → Servicio `checkin24hs-dashboard` → Pestaña "Puertos"
2. Verifica que exista un puerto:
   - **Protocolo**: `TCP`
   - **Publicado**: `30002`
   - **Destino**: `3000`
3. Si no existe, créalo
4. Si existe pero no funciona, elimínalo y créalo de nuevo

**O desde SSH:**
```bash
# Eliminar puerto existente (si hay)
docker service update --publish-rm 30002 checkin24hs_checkin24hs-dashboard

# Agregar puerto correcto
docker service update --publish-add published=30002,target=3000,protocol=tcp,mode=host checkin24hs_checkin24hs-dashboard

# Verificar
docker service inspect checkin24hs_checkin24hs-dashboard --format '{{json .Endpoint.Ports}}' | jq
```

---

### Problema 3: El Servicio Está en Modo Ingress en Lugar de Host

**Síntomas:**
- El puerto está publicado pero en modo `ingress`
- No es accesible desde fuera del servidor

**Solución:**
```bash
# Cambiar a modo host
docker service update \
  --publish-rm 30002:3000 \
  --publish-add published=30002,target=3000,protocol=tcp,mode=host \
  checkin24hs_checkin24hs-dashboard
```

---

### Problema 4: El Servidor No Está Escuchando en el Puerto Correcto

**Síntomas:**
- El servicio está corriendo
- El puerto está publicado
- Pero `curl localhost:30002` no funciona

**Solución:**
1. Verifica los logs del servicio:
```bash
docker service logs checkin24hs_checkin24hs-dashboard --tail 20
```

2. Debe mostrar:
```
🚀 Servidor iniciado en http://0.0.0.0:3000/
```

3. Si no muestra esto, el servidor no está iniciando correctamente. Verifica:
   - Que el `Dockerfile` tenga `CMD ["node", "server.js"]`
   - Que `server.js` exista en el contenedor
   - Que no haya errores en los logs

---

### Problema 5: Firewall Bloqueando el Puerto

**Síntomas:**
- Todo funciona localmente (`curl localhost:30002`)
- Pero no funciona desde fuera

**Solución:**
```bash
# Verificar firewall
sudo ufw status

# Si está activo, permitir el puerto 30002
sudo ufw allow 30002/tcp

# Verificar
sudo ufw status | grep 30002
```

---

### Problema 6: El Servicio Tiene un Nombre Diferente

**Síntomas:**
- `docker service ls` no muestra `checkin24hs_checkin24hs-dashboard`

**Solución:**
```bash
# Ver todos los servicios
docker service ls

# Buscar el servicio correcto
docker service ls | grep -i dashboard

# Usar el nombre correcto en los comandos
```

---

## ✅ Verificación Final

Después de aplicar la solución, verifica:

```bash
# 1. Estado del servicio
docker service ps checkin24hs_checkin24hs-dashboard

# 2. Puerto publicado
docker service inspect checkin24hs_checkin24hs-dashboard --format '{{json .Endpoint.Ports}}' | jq

# 3. Puerto en uso
sudo netstat -tuln | grep 30002

# 4. Conexión local
curl -I http://localhost:30002

# 5. Logs
docker service logs checkin24hs_checkin24hs-dashboard --tail 5
```

---

## 🆘 Si Nada Funciona

1. **Verifica en EasyPanel:**
   - ¿El servicio está en estado "Running" (verde)?
   - ¿El puerto 30002 está configurado?
   - ¿Los logs muestran errores?

2. **Recrea el servicio desde cero:**
   - Elimina el servicio en EasyPanel
   - Créalo de nuevo con la configuración correcta
   - Asegúrate de que la "Ruta de compilación" sea `/` (raíz)

3. **Prueba con otro puerto:**
   - Usa el puerto 30003 o 30004
   - Configúralo en EasyPanel
   - Prueba `http://72.61.58.240:30003`


