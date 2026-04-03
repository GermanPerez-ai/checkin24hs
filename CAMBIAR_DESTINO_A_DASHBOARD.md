# 🔧 Cambiar Destino del Dominio a "dashboard"

## 🎯 Problema Confirmado

- ✅ Alias real: `checkin24hs-dashboard` (guión) y `dashboard`
- ❌ EasyPanel genera: `checkin24hs_dashboard` (guión bajo)
- ❌ No coinciden → 404

## ✅ Solución: Usar el Alias "dashboard"

El alias `dashboard` existe. Cambiemos el destino del dominio para usarlo.

### Paso 1: Editar el Dominio

1. En EasyPanel, ve a la pestaña **"Dominios"**
2. Haz clic en el **lápiz** (editar) del dominio `dashboard.checkin24hs.com`
3. En el modal que se abre, busca la sección **"Destino"**
4. **Cambia el destino** de:
   ```
   http://checkin24hs_dashboard:3000/
   ```
   A:
   ```
   http://dashboard:3000/
   ```
   (Usa solo `dashboard`, sin prefijo)

5. Haz clic en **"Guardar"**

### Paso 2: Si No Puedes Editar el Destino

Si EasyPanel no te permite editar el destino:

1. **Elimina** el dominio `dashboard.checkin24hs.com`
2. Espera 30 segundos
3. **Agrega** el dominio de nuevo: `dashboard.checkin24hs.com`
4. **Verifica** qué destino genera
   - Si genera `http://checkin24hs_dashboard:3000/` (guión bajo), el problema persiste
   - Si genera `http://dashboard:3000/`, debería funcionar

### Paso 3: Probar

1. Espera 30-60 segundos después de hacer los cambios
2. Abre tu navegador
3. Ve a: `https://dashboard.checkin24hs.com/`
4. **¿Funciona?**

---

## 🔍 Si EasyPanel Sigue Generando con Guión Bajo

Si después de eliminar y recrear el dominio, EasyPanel sigue generando `http://checkin24hs_dashboard:3000/` (guión bajo), entonces:

- El problema es que EasyPanel siempre usa el formato `proyecto_servicio`
- La única solución sería contactar soporte de EasyPanel o usar una solución alternativa

---

**Intenta editar el dominio y cambiar el destino a `http://dashboard:3000/`. Si no puedes editarlo, elimínalo y créalo de nuevo, y verifica qué destino genera.**
