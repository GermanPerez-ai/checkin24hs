# 🔧 Solución: Alias con Guión vs Guión Bajo

## 🎯 Problema Identificado

El servicio tiene estos aliases:
- ✅ `checkin24hs-dashboard` (con **guión**)
- ✅ `dashboard`

Pero en EasyPanel, el dominio está configurado para apuntar a:
- ❌ `checkin24hs_dashboard` (con **guión bajo**)

**El guión bajo no coincide con el alias real del servicio.**

## ✅ Solución

### Paso 1: Corregir el Dominio en EasyPanel

1. En EasyPanel, ve a la pestaña **"Dominios"** del servicio `dashboard`
2. Haz clic en el **lápiz** (editar) del dominio `dashboard.checkin24hs.com`
3. Cambia el destino de:
   ```
   http://checkin24hs_dashboard:80/
   ```
   A:
   ```
   http://checkin24hs-dashboard:80/
   ```
   (Nota: **guión** en lugar de **guión bajo**)

4. Haz clic en **"Guardar"**

### Paso 2: Esperar y Probar

1. Espera 30-60 segundos para que el proxy actualice la configuración
2. Prueba acceder a: `https://dashboard.checkin24hs.com/`

### Paso 3: Si No Funciona, Recrear el Dominio

Si cambiar el destino no funciona:

1. **Elimina** el dominio `dashboard.checkin24hs.com`
2. Espera 30 segundos
3. **Agrega** el dominio de nuevo:
   - Dominio: `dashboard.checkin24hs.com`
   - Destino: `http://checkin24hs-dashboard:80/` (con **guión**)
4. Guarda y espera 60 segundos
5. Prueba acceder

---

## 🔍 Explicación

Docker Swarm (que usa EasyPanel) crea aliases para los servicios. El alias real es `checkin24hs-dashboard` (con guión), no `checkin24hs_dashboard` (con guión bajo).

El proxy de EasyPanel (Traefik) necesita usar el alias correcto para poder resolver el servicio.

---

**Cambia `checkin24hs_dashboard` a `checkin24hs-dashboard` (con guión) en la configuración del dominio.**
