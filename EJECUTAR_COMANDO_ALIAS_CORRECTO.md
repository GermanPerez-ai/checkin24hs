# ✅ Ejecutar Comando para Agregar Alias

## 🎯 Información Confirmada

- **Red compartida**: `easypanel-checkin24hs`
- **Traefik está en esta red**: ✅ Confirmado

## ✅ Comando para Ejecutar

```bash
docker service update \
  --network-rm nvhtv52umzihypz8u7adejvpo \
  --network-add name=easypanel-checkin24hs,alias=checkin24hs-dashboard,alias=dashboard,alias=checkin24hs_dashboard \
  checkin24hs_dashboard
```

**Nota**: Reemplaza `<nombre_red>` con `easypanel-checkin24hs` (sin los corchetes).

## ✅ Después de Ejecutar

### Paso 1: Verificar que el Alias se Agregó

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Deberías ver `checkin24hs_dashboard` (con guión bajo) en la lista de aliases de la red `easypanel-checkin24hs`.

### Paso 2: Probar el Dominio

1. Espera 30-60 segundos para que el servicio se actualice
2. Prueba acceder a: `https://dashboard.checkin24hs.com/`
3. **¿Funciona?**

---

**Ejecuta el comando con `easypanel-checkin24hs` (sin los corchetes) y luego verifica que el alias se agregó.**
