# 🔍 Verificar Configuración del Servicio Dashboard

## 📊 Paso 1: Verificar Servicio Dashboard

### Comando 1: Ver estado del servicio

```bash
# Ver estado del servicio dashboard
docker service inspect checkin24hs_dashboard --pretty | head -50
```

### Comando 2: Ver contenedores activos

```bash
# Ver contenedores activos del dashboard
docker ps | grep "checkin24hs_dashboard" | grep -v "proxy"
```

### Comando 3: Ver configuración de redes

```bash
# Ver redes del servicio dashboard
docker service inspect checkin24hs_dashboard | grep -A 20 "Networks"
```

### Comando 4: Ver aliases configurados

```bash
# Ver aliases del servicio dashboard
docker service inspect checkin24hs_dashboard | grep -A 10 "Aliases"
```

### Comando 5: Ver puertos configurados

```bash
# Ver puertos del servicio dashboard
docker service inspect checkin24hs_dashboard | grep -A 5 "Ports"
```

---

**Ejecuta estos 5 comandos y comparte los resultados. Luego revisaremos el servicio dashboard-proxy.**
