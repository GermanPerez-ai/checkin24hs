# Solución para Dashboard con Docker/EasyPanel

## Problema
El dashboard puede estar siendo servido por:
1. Un contenedor Docker antiguo
2. Una configuración de EasyPanel
3. Un proxy (nginx/traefik) que está sirviendo una versión en caché

## Soluciones

### Opción 1: Detener contenedores Docker antiguos

```bash
# Ver todos los contenedores
docker ps -a | grep -i dashboard

# Detener y eliminar contenedores antiguos
docker stop $(docker ps -a | grep -i dashboard | awk '{print $1}')
docker rm $(docker ps -a | grep -i dashboard | awk '{print $1}')

# Verificar que PM2 esté corriendo
pm2 list
pm2 restart dashboard
```

### Opción 2: Verificar configuración de EasyPanel

```bash
# Ver si hay servicios de EasyPanel
systemctl list-units --type=service | grep -i panel

# Ver si hay configuración de Traefik
find /etc -name "*traefik*" -o -name "*easypanel*" 2>/dev/null

# Ver configuración de Docker Compose si existe
find /root -name "docker-compose.yml" -o -name "*.yaml" | grep -i dashboard
```

### Opción 3: Verificar qué archivo se está sirviendo

```bash
# Ver el contenido real que se está sirviendo
curl -s http://localhost:3000/ > /tmp/dashboard_servido.html
head -50 /tmp/dashboard_servido.html

# Comparar con el archivo en el servidor
head -50 /root/checkin24hs/dashboard.html

# Ver si son diferentes
diff <(head -100 /tmp/dashboard_servido.html) <(head -100 /root/checkin24hs/dashboard.html)
```

### Opción 4: Forzar actualización completa

```bash
# 1. Detener PM2
pm2 stop dashboard
pm2 delete dashboard

# 2. Detener cualquier contenedor Docker
docker stop $(docker ps | grep -i dashboard | awk '{print $1}')

# 3. Verificar que el puerto 3000 esté libre
sudo lsof -i :3000

# 4. Reiniciar PM2 con el archivo correcto
cd /root/checkin24hs
pm2 start serve-dashboard.js --name dashboard

# 5. Verificar logs
pm2 logs dashboard --lines 20
```

### Opción 5: Verificar caché del navegador

El problema puede ser caché del navegador. Prueba:
1. Modo incógnito (Ctrl + Shift + N)
2. Hard refresh (Ctrl + Shift + R)
3. Limpiar caché completamente

### Opción 6: Verificar si hay un proxy reverso

```bash
# Ver configuración de nginx
nginx -t 2>/dev/null
cat /etc/nginx/sites-enabled/* 2>/dev/null | grep -i dashboard

# Ver configuración de traefik
find /etc -name "traefik.yml" 2>/dev/null
```

## Comando completo de diagnóstico

```bash
echo "=== DIAGNÓSTICO COMPLETO ==="
echo "1. Procesos Node:"
ps aux | grep node | grep -v grep
echo ""
echo "2. Contenedores Docker:"
docker ps -a | grep -i dashboard
echo ""
echo "3. Puerto 3000:"
sudo lsof -i :3000
echo ""
echo "4. PM2:"
pm2 list
echo ""
echo "5. Archivo servido (primeras líneas):"
curl -s http://localhost:3000/ | head -30
echo ""
echo "6. Archivo en disco (primeras líneas):"
head -30 /root/checkin24hs/dashboard.html
```


