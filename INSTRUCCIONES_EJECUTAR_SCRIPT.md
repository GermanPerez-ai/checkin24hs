# Instrucciones para Ejecutar el Script

## Problema
El comando se corta porque el `||` necesita estar en la misma línea o el script necesita ser más simple.

## Solución: Usar el Script Simplificado

### Opción 1: Crear el script directamente en el servidor

Ejecuta este comando COMPLETO en el servidor (copia y pega todo):

```bash
cat > /root/checkin24hs/aplicar.sh << 'EOF'
#!/bin/bash
cd /root/checkin24hs
echo "=== DETENIENDO CONTENEDORES ==="
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Detenidos"
echo ""
echo "=== COPIANDO ARCHIVO ==="
for c in $(docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard); do
    echo "Copiando a: $c"
    if docker cp deploy/dashboard.html "$c:/app/dashboard.html" 2>/dev/null; then
        echo "✅ $c - /app/dashboard.html"
    else
        docker cp deploy/dashboard.html "$c:/usr/share/nginx/html/dashboard.html" 2>/dev/null
        echo "✅ $c - /usr/share/nginx/html/dashboard.html"
    fi
done
echo ""
echo "=== REINICIANDO CONTENEDORES ==="
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard") 2>/dev/null
sleep 3
echo "✅ Reiniciados"
echo ""
echo "=== ESTADO ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep checkin24hs_dashboard
echo ""
echo "✅ Completado!"
EOF

chmod +x /root/checkin24hs/aplicar.sh
bash /root/checkin24hs/aplicar.sh
```

### Opción 2: Ejecutar comandos uno por uno

```bash
cd /root/checkin24hs

# 1. Detener
docker stop $(docker ps -q --filter "name=checkin24hs_dashboard")
sleep 3

# 2. Copiar (ejecuta cada contenedor por separado)
# Primero lista los contenedores:
docker ps -a --format '{{.Names}}' | grep checkin24hs_dashboard

# Luego copia a cada uno (reemplaza NOMBRE_CONTENEDOR con el nombre real):
docker cp deploy/dashboard.html NOMBRE_CONTENEDOR:/app/dashboard.html

# O si falla, usa la otra ruta:
docker cp deploy/dashboard.html NOMBRE_CONTENEDOR:/usr/share/nginx/html/dashboard.html

# 3. Reiniciar
docker start $(docker ps -aq --filter "name=checkin24hs_dashboard")
sleep 3

# 4. Verificar
docker ps | grep checkin24hs_dashboard
```

### Opción 3: Usar el script ya subido

```bash
cd /root/checkin24hs
chmod +x aplicar_dashboard.sh
bash aplicar_dashboard.sh
```










