# 🔧 Corregir Servicio Dashboard-Proxy

## 📊 Paso 1: Limpiar Contenedores Antiguos

### Comando 1: Escalar servicio a 0

```bash
# Escalar servicio a 0 para detener todos los contenedores
docker service scale checkin24hs_dashboard-proxy=0
```

### Comando 2: Esperar y verificar

```bash
# Esperar 10 segundos
sleep 10

# Verificar que no hay contenedores activos
docker ps | grep dashboard-proxy
```

### Comando 3: Limpiar contenedores detenidos

```bash
# Limpiar contenedores detenidos
docker container prune -f
```

### Comando 4: Escalar servicio a 1

```bash
# Escalar servicio a 1 para crear un nuevo contenedor limpio
docker service scale checkin24hs_dashboard-proxy=1
```

### Comando 5: Esperar y verificar

```bash
# Esperar 30 segundos
sleep 30

# Verificar que solo hay 1 contenedor activo
docker ps | grep dashboard-proxy
```

---

**Ejecuta estos 5 comandos en orden. Luego corregiremos las variables de entorno en EasyPanel.**
