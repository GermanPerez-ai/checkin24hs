# Corregir Puerto de EasyPanel

## Problema

EasyPanel está corriendo pero escucha solo en `127.0.0.1` (localhost), no en todas las interfaces. Esto impide el acceso desde fuera del servidor.

## Solución

### Paso 1: Verificar Mapeo de Puertos Actual

```bash
# Ver mapeo de puertos del contenedor
docker port easypanel

# Ver qué está usando el puerto 3000 en el host
sudo lsof -i :3000

# O con netstat
sudo netstat -tulpn | grep 3000
```

### Paso 2: Recrear EasyPanel con Puerto Correcto

Si el puerto no está mapeado correctamente:

```bash
# Detener y eliminar EasyPanel actual
docker stop easypanel
docker rm easypanel

# Recrear EasyPanel con mapeo de puerto explícito
docker run -d \
  --name easypanel \
  --restart unless-stopped \
  --network easypanel \
  -p 0.0.0.0:3000:3000 \
  -v /etc/easypanel:/etc/easypanel \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  easypanel/easypanel:latest

# Esperar a que se inicie
sleep 20

# Verificar
docker ps | grep easypanel
docker port easypanel
sudo lsof -i :3000
```

### Paso 3: Verificar Accesibilidad

```bash
# Probar conexión local
curl http://localhost:3000

# Probar desde la IP del servidor
curl http://72.61.58.240:3000

# Ver logs
docker logs easypanel --tail 30
```

## Verificar Firewall

Si aún no es accesible, verifica el firewall:

```bash
# Ver estado del firewall
sudo ufw status

# Si está activo, permitir puerto 3000
sudo ufw allow 3000/tcp

# Ver reglas de iptables
sudo iptables -L -n | grep 3000
```

## Alternativa: Verificar Configuración de EasyPanel

EasyPanel puede tener una configuración interna que limita a qué interfaces escucha. Verifica:

```bash
# Ver variables de entorno
docker inspect easypanel | grep -A 20 Env

# Ver configuración
cat /etc/easypanel/config.json 2>/dev/null || echo "No hay archivo de configuración"
```

## Notas Importantes

- `-p 0.0.0.0:3000:3000` mapea el puerto 3000 del contenedor al puerto 3000 del host en todas las interfaces
- `0.0.0.0` significa "todas las interfaces", no solo localhost
- El firewall del servidor debe permitir conexiones al puerto 3000

## Luego en el Navegador

1. Espera 1-2 minutos después de recrear EasyPanel
2. Intenta acceder: **http://72.61.58.240:3000**
3. Si aún no funciona, verifica:
   - Firewall del servidor
   - Reglas de iptables
   - Configuración de red del proveedor (Hostinger)


