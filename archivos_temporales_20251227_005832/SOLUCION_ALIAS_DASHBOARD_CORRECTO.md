# 🔧 Solución: Alias Correcto del Dashboard

## ✅ Diagnóstico

- ✅ Traefik está en la red `easypanel`
- ✅ El servicio dashboard YA está en la red `easypanel`
- ❌ El problema es el **alias**: el servicio usa `checkin24hs-dashboard` (con guión), pero la configuración del dominio usa `checkin24hs_dashboard` (con guión bajo)

## 🎯 Solución

### Opción 1: Corregir el Alias en EasyPanel (Recomendado)

1. Ve a **EasyPanel** → **Servicios** → **dashboard**
2. Ve a la sección **"Dominios"**
3. Haz clic en el dominio del dashboard para editarlo
4. En el campo **"Target Service"** o **"Servicio de destino"**, cambia:
   - De: `checkin24hs_dashboard` (con guión bajo)
   - A: `checkin24hs-dashboard` (con guión)
5. **Guarda** los cambios
6. **Reinicia** el servicio

### Opción 2: Cambiar el Alias del Servicio (Desde SSH)

Si prefieres cambiar el alias del servicio para que coincida con la configuración actual:

```bash
# Ver la configuración actual
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq

# Actualizar el alias en la red easypanel
# (Esto requiere recrear el servicio con el alias correcto)
```

**Nota**: Cambiar el alias del servicio es más complicado. Es mejor cambiar la configuración del dominio.

## 🔍 Verificación

Después de corregir el alias, prueba desde SSH:

```bash
# Probar con el alias correcto (con guión)
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://checkin24hs-dashboard:3000 2>&1 | head -20

# O probar con el alias alternativo
docker exec $(docker ps | grep traefik | awk '{print $1}') wget -O- http://dashboard:3000 2>&1 | head -20
```

## 📋 Resumen

**Redes:**
- Traefik está en: `easypanel`
- Dashboard está en: `easypanel` ✅ (ya está conectado)

**Alias:**
- Alias del servicio: `checkin24hs-dashboard` (con guión)
- Alias alternativo: `dashboard`
- Configuración del dominio debe usar: `checkin24hs-dashboard` (con guión)

**Puerto:**
- Puerto del servicio: `3000`

---

**Acción requerida**: Cambiar la configuración del dominio en EasyPanel para usar `checkin24hs-dashboard` (con guión) en lugar de `checkin24hs_dashboard` (con guión bajo).

