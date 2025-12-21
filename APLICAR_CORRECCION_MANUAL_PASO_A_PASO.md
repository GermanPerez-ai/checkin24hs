# 🔧 Aplicar Corrección loadHotelsTable - Manual

## Paso 1: Encontrar el Contenedor Correcto

Ejecuta estos comandos para encontrar el contenedor del dashboard:

```bash
# Ver todos los contenedores corriendo
docker ps

# Buscar específicamente el dashboard
docker ps | grep dashboard

# Si no aparece, buscar por "checkin24hs"
docker ps | grep checkin24hs

# Ver todos los contenedores (incluso detenidos)
docker ps -a | grep dashboard
```

Anota el **ID del contenedor** (primera columna) o el **nombre completo**.

---

## Paso 2: Aplicar la Corrección Manualmente

Una vez que tengas el ID del contenedor, ejecuta estos comandos:

```bash
# Reemplaza CONTAINER_ID con el ID que encontraste
CONTAINER_ID="TU_ID_AQUI"

# 1. Hacer backup
docker exec $CONTAINER_ID cp /app/dashboard.html /app/dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || \
docker exec $CONTAINER_ID cp dashboard.html dashboard.html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || \
echo "⚠️  No se pudo hacer backup (continuando)"

# 2. Descargar el archivo corregido
curl -o /tmp/dashboard_corregido.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# 3. Verificar que se descargó
ls -lh /tmp/dashboard_corregido.html

# 4. Copiar al contenedor (intentar diferentes rutas)
docker cp /tmp/dashboard_corregido.html $CONTAINER_ID:/app/dashboard.html || \
docker cp /tmp/dashboard_corregido.html $CONTAINER_ID:/dashboard.html || \
docker cp /tmp/dashboard_corregido.html $CONTAINER_ID:./dashboard.html

# 5. Verificar que se copió
docker exec $CONTAINER_ID ls -lh /app/dashboard.html || \
docker exec $CONTAINER_ID ls -lh dashboard.html

# 6. Reiniciar el contenedor
docker restart $CONTAINER_ID

# 7. Esperar 15 segundos
sleep 15

# 8. Ver logs para verificar
docker logs $CONTAINER_ID --tail 20
```

---

## Paso 3: Verificar

Después de aplicar la corrección:

1. Abre `https://dashboard.checkin24hs.com`
2. Presiona Ctrl+F5 (limpiar caché)
3. Abre la consola (F12)
4. Verifica que NO aparece: `Identifier 'loadHotelsTable' has already been declared`

---

## Si el Contenedor No Se Encuentra

Si no encuentras ningún contenedor con "dashboard" o "checkin24hs", el servicio puede estar corriendo de otra forma:

1. **Verificar servicios Docker Swarm:**
   ```bash
   docker service ls
   ```

2. **Verificar procesos Node.js:**
   ```bash
   ps aux | grep node
   ```

3. **Verificar puertos en uso:**
   ```bash
   netstat -tulpn | grep 3000
   ```

Si el servicio está en Docker Swarm, necesitarás actualizar el servicio en lugar del contenedor.

