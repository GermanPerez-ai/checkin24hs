# 🔍 Buscar Contenedor de Traefik

## Comandos para Encontrar Traefik

### 1. Ver Todos los Contenedores de Traefik

```bash
docker ps | grep traefik
```

### 2. Ver Todos los Contenedores (Incluyendo Detenidos)

```bash
docker ps -a | grep traefik
```

### 3. Ver Logs del Contenedor Correcto

Una vez que encuentres el nombre correcto, usa:

```bash
docker logs [NOMBRE_DEL_CONTENEDOR] --tail 30
```

### 4. Ver Logs de Todos los Contenedores Relacionados

```bash
docker ps --format "{{.Names}}" | grep -i traefik | xargs -I {} docker logs {} --tail 20
```


