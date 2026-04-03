# 🔄 Reiniciar Traefik para Aplicar Cambios

## Comandos para Reiniciar Traefik

### 1. Ver Contenedor de Traefik

```bash
docker ps | grep traefik
```

### 2. Reiniciar Traefik

```bash
# Reiniciar el contenedor de Traefik
docker restart traefik.1.tohc9vmjwor1uqmo6s0t9q19w

# O si está en un stack de Docker Compose
docker-compose restart traefik
```

### 3. Verificar que se Reinició Correctamente

```bash
# Ver logs después del reinicio
docker logs traefik.1.tohc9vmjwor1uqmo6s0t9q19w --tail 50

# Verificar que no hay errores de API
docker logs traefik.1.tohc9vmjwor1uqmo6s0t9q19w 2>&1 | grep -i "client version\|API version" | tail -10
```

### 4. Verificar Versión de Docker

```bash
# Ver versión de Docker
docker version

# Ver versión de la API de Docker
docker info | grep -i "Server Version\|API Version"
```

---

## Después del Reinicio

1. Espera 1-2 minutos para que Traefik se inicie completamente
2. Verifica los logs para asegurarte de que no hay errores
3. Prueba SSL de nuevo: `https://configwp.checkin24hs.com`

---

## Si el Problema Persiste

Si después de reiniciar Traefik sigue apareciendo el error de API:

1. **Verificar versión de Docker:**
   ```bash
   docker version
   ```

2. **Si Docker es muy nuevo**, puede que necesites:
   - Actualizar Traefik a una versión más reciente específica
   - O configurar Traefik para usar una versión específica de la API

3. **Alternativa:** Usar HTTP temporalmente hasta que se resuelva el problema de infraestructura


