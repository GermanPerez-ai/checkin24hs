# 🔧 Solución: Nombre del Proyecto en EasyPanel

## 🎯 Problema Identificado

- El servicio se llama `dashboard` ✅
- Pero EasyPanel genera: `http://checkin24hs_dashboard:80/` (proyecto_servicio)
- El alias real en Docker es: `checkin24hs-dashboard` (con **guión**, no guión bajo)
- **No coinciden** → 404

## ✅ Soluciones

### Solución 1: Cambiar el Nombre del Proyecto

EasyPanel puede estar usando `proyecto_servicio` para generar el destino. Si cambias el nombre del proyecto, el destino cambiará.

**Pasos:**

1. En EasyPanel, busca la opción para cambiar el nombre del proyecto `checkin24hs`
2. Cámbialo a algo que genere un alias que coincida, o simplemente elimina el prefijo
3. O crea un nuevo proyecto con un nombre diferente
4. Mueve el servicio `dashboard` a ese nuevo proyecto

**Nota:** Esto puede ser complicado y afectar otros servicios.

### Solución 2: Verificar si Hay una Opción para Cambiar el Formato del Destino

1. En la pestaña **"Dominios"**, busca opciones avanzadas o configuración
2. Puede haber una opción para cambiar cómo se genera el destino
3. O puede haber una opción para especificar el destino manualmente

### Solución 3: Usar el Alias "dashboard" Directamente

Si el servicio se llama `dashboard`, EasyPanel debería poder usar el alias `dashboard` directamente.

**Verifica:**

1. En la pestaña **"Dominios"**, cuando agregas el dominio, ¿qué destino aparece exactamente?
2. ¿Aparece `http://checkin24hs_dashboard:80/` o `http://dashboard:80/`?

Si aparece `http://checkin24hs_dashboard:80/`, entonces EasyPanel está usando `proyecto_servicio`.

### Solución 4: Crear el Servicio en un Proyecto Diferente

1. Crea un nuevo proyecto en EasyPanel (por ejemplo, `dashboard` o `app`)
2. Crea el servicio `dashboard` en ese nuevo proyecto
3. Si el proyecto se llama `dashboard` y el servicio también `dashboard`, EasyPanel podría generar `http://dashboard:80/`

### Solución 5: Verificar la Configuración del Servicio en Docker

Puede ser que necesitemos verificar si el servicio en Docker tiene el alias correcto configurado.

En el servidor, ejecuta:
```bash
docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

Esto mostrará todos los aliases configurados.

---

## 🔍 Información Necesaria

Para diagnosticar mejor:

1. **¿Qué destino aparece exactamente cuando agregas el dominio en EasyPanel?**
   - ¿Es `http://checkin24hs_dashboard:80/` o algo diferente?

2. **¿Hay alguna opción en "Dominios" para cambiar el formato del destino?**

3. **¿Puedes cambiar el nombre del proyecto `checkin24hs`?**

---

**Comparte qué destino aparece exactamente cuando agregas el dominio, y si hay opciones para cambiarlo.**
