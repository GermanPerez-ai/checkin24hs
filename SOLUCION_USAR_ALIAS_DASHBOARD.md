# 🔧 Solución: Usar Alias "dashboard"

## 🎯 Problema Confirmado

- ✅ Alias real: `checkin24hs-dashboard` (guión) y `dashboard`
- ❌ EasyPanel genera: `checkin24hs_dashboard` (guión bajo)
- ❌ No coinciden → 404

## ✅ Solución: Cambiar Destino a "dashboard"

El alias `dashboard` existe. Necesitamos hacer que el dominio use ese alias.

### Paso 1: Editar el Dominio

1. En EasyPanel, ve a la pestaña **"Dominios"**
2. Haz clic en el **lápiz** (editar) del dominio `dashboard.checkin24hs.com`
3. **Si puedes editar el destino**, cámbialo a:
   ```
   http://dashboard:80/
   ```
4. Guarda los cambios

### Paso 2: Si No Puedes Editar el Destino

Si EasyPanel no te permite editar el destino:

1. **Elimina** el dominio `dashboard.checkin24hs.com` (icono de basura)
2. Espera 30 segundos
3. **Agrega** el dominio de nuevo: `dashboard.checkin24hs.com`
4. **Verifica** qué destino genera**
   - Si genera `http://checkin24hs_dashboard:80/` (guión bajo), el problema persiste
   - Si genera `http://dashboard:80/`, debería funcionar

### Paso 3: Probar

1. Espera 30-60 segundos después de hacer los cambios
2. Abre tu navegador
3. Ve a: `https://dashboard.checkin24hs.com/`
4. **¿Funciona?**

---

## 🔍 Si EasyPanel Sigue Generando con Guión Bajo

Si después de eliminar y recrear el dominio, EasyPanel sigue generando `http://checkin24hs_dashboard:80/` (guión bajo), entonces el problema es que EasyPanel siempre usa el formato `proyecto_servicio`.

En ese caso, la única solución sería:
- Renombrar el proyecto o el servicio para que el alias generado coincida
- O contactar soporte de EasyPanel

---

**Intenta editar el dominio o eliminarlo y recrearlo. ¿Puedes cambiar el destino a `http://dashboard:80/`?**
