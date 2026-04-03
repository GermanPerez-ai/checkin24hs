# 🔧 Probar Dominio Ya Configurado

## 🎯 Estado Actual

Veo que el dominio `https://dashboard.checkin24hs.com/` ya está agregado y apunta a:
- `http://checkin24hs_dashboard:80/` (con **guión bajo**)

Pero el alias real en Docker es:
- `checkin24hs-dashboard` (con **guión**)

## ✅ Paso 1: Probar si Funciona

Aunque el destino tenga guión bajo, probemos si funciona:

1. Abre tu navegador
2. Ve a: `https://dashboard.checkin24hs.com/`
3. **¿Qué ves?**
   - ¿Funciona y muestra el dashboard?
   - ¿O sigue dando 404?

## 🔍 Si Sigue Dando 404

Si sigue dando 404, el problema es que el alias no coincide. Necesitamos verificar el alias del nuevo servicio.

### Paso 2: Verificar el Alias del Nuevo Servicio

En el servidor, ejecuta:

```bash
# Ver todos los servicios dashboard
docker service ls | grep dashboard

# Ver los aliases del nuevo servicio (reemplaza dashboard-new con el nombre real)
docker service inspect checkin24hs_dashboard-new --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

O si el servicio se llama diferente, primero encuentra el nombre:

```bash
docker service ls | grep dashboard
```

Luego usa el nombre correcto en el comando de inspección.

## 🔧 Solución: Editar el Dominio

Si el dominio no funciona, podemos intentar editarlo:

1. En la pestaña "Dominios", haz clic en el **lápiz** (editar) del dominio `dashboard.checkin24hs.com`
2. Verifica si puedes cambiar el destino manualmente
3. Si puedes, cámbialo a: `http://checkin24hs-dashboard:80/` (con **guión**)
4. O a: `http://dashboard:80/` (si ese alias existe)

---

**Primero, prueba acceder a `https://dashboard.checkin24hs.com/` y dime qué ves. ¿Funciona o sigue dando 404?**
