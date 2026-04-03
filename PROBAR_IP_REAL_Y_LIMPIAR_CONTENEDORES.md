# 🔧 Probar IP Real y Limpiar Contenedores

## 📊 Estado Actual

- ✅ IP del contenedor más reciente: `10.0.2.79`
- ❌ 5 contenedores activos (debería haber 1)
- ❌ DNS sigue apuntando a IP antigua (`10.0.2.104`)

## 🔧 Solución

### Paso 1: Probar conexión con IP real

```bash
# Probar conexión a la IP real
docker run --rm --network easypanel-checkin24hs curlimages/curl:latest curl -I http://10.0.2.79:3000/
```

### Paso 2: Limpiar contenedores antiguos (dejar solo el más reciente)

El contenedor más reciente es: `1bf1d9afe693`

```bash
# Detener y eliminar los otros 4 contenedores
docker stop 2b5ed93c2c80 5b12979dbdd7 ff9f3cdaff20 2c13de0c83a5
docker rm 2b5ed93c2c80 5b12979dbdd7 ff9f3cdaff20 2c13de0c83a5
```

### Paso 3: Verificar que solo queda 1 contenedor

```bash
docker ps | grep dashboard
```

### Paso 4: Actualizar dominio en EasyPanel con IP directa (SOLUCIÓN TEMPORAL)

Como el DNS está desactualizado, configura el dominio en EasyPanel para usar la IP directa:

1. Ve a EasyPanel → Dominios
2. Edita `dashboard.checkin24hs.com`
3. Cambia el destino a: `http://10.0.2.79:3000/`

**NOTA**: Esta es una solución temporal. La IP puede cambiar cuando el contenedor se reinicie. Pero al menos el dashboard funcionará ahora.

### Paso 5: Solución permanente (más tarde)

Para una solución permanente, necesitaremos:
- Reiniciar Docker Swarm
- O recrear el servicio completamente
- O esperar a que el DNS se actualice automáticamente (puede tardar horas)

---

**Primero prueba el Paso 1 con la IP real. Si funciona, configura EasyPanel con esa IP.**
