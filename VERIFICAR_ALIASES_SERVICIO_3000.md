# 🔍 Verificar Aliases del Servicio con Puerto 3000

## 🎯 Problema

El dominio está configurado con puerto 3000, pero sigue dando 404. El problema probablemente es el mismo: el alias no coincide.

## ✅ Verificar Aliases

En el servidor, ejecuta:

```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Esto mostrará los aliases reales del servicio.

## 🔍 Análisis

EasyPanel genera: `http://checkin24hs_dashboard:3000/` (con **guión bajo**)

Necesitamos verificar si el alias real es:
- `checkin24hs-dashboard` (con **guión**) → No coincide
- `checkin24hs_dashboard` (con **guión bajo**) → Coincide ✅
- `dashboard` → Podríamos usar este

## ✅ Soluciones Posibles

### Solución 1: Si el Alias es `checkin24hs-dashboard` (guión)

El problema es el mismo de antes. Opciones:
- Agregar el alias `checkin24hs_dashboard` (guión bajo) al servicio
- O usar el alias `dashboard` si existe

### Solución 2: Si el Alias es `dashboard`

Podemos cambiar el destino del dominio a `http://dashboard:3000/` en lugar de `http://checkin24hs_dashboard:3000/`

### Solución 3: Probar Acceso Directo

Mientras tanto, podemos probar si el servicio responde directamente:

En el servidor:
```bash
# Probar desde dentro del contenedor
docker exec $(docker ps | grep dashboard | head -1 | awk '{print $1}') curl http://localhost:3000/
```

O desde el servidor:
```bash
# Verificar que el servicio esté escuchando
docker service ps checkin24hs_dashboard
```

---

**Ejecuta el comando para ver los aliases y comparte el resultado. También prueba el acceso directo desde el servidor.**
