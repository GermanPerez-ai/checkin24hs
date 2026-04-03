# 🔍 Probar Contenedor y Verificar Aliases

## 🎯 Pasos

### Paso 1: Probar desde Dentro del Contenedor

Usa el primer contenedor (5bedb81f0653):

```bash
docker exec 5bedb81f0653 curl http://localhost:3000/
```

Esto verificará si el servicio responde correctamente desde dentro del contenedor.

### Paso 2: Verificar Aliases del Servicio

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Esto mostrará los aliases reales del servicio.

### Paso 3: Verificar el Nombre del Servicio

```bash
docker service ls | grep dashboard
```

---

**Ejecuta estos tres comandos y comparte los resultados. Esto nos ayudará a identificar el problema exacto.**
