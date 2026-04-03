# 🔧 Solución: Puerto 30002 Ya Está en Uso

## 🚨 Problema

El puerto 30002 está siendo usado por el servicio viejo `checkin24hs_dashboard`.

## ✅ Soluciones

### Opción 1: Eliminar el Puerto del Servicio Viejo (Recomendado)

1. **Ve a** → **Servicios** → **dashboard** (el servicio viejo)
2. **Ve a "Puertos"** en el menú lateral
3. **Elimina el puerto 30002** del servicio viejo
4. **Vuelve al nuevo servicio** `checkin24hs-dashboard`
5. **Intenta crear el puerto 30002 de nuevo**

### Opción 2: Usar un Puerto Diferente Temporalmente

1. **En el modal "Crear puerto"**, cambia el puerto publicado a otro:
   - **Publicado**: `30003` (o cualquier puerto libre)
   - **Destino**: `3000`
2. **Crea el puerto**
3. **Luego elimina el servicio viejo** y cambia el puerto a 30002 si quieres

### Opción 3: Eliminar el Servicio Viejo Primero

1. **Ve a** → **Servicios** → **dashboard** (el servicio viejo)
2. **Elimina el servicio** (botón "Destruir servicio" o similar)
3. **Vuelve al nuevo servicio** `checkin24hs-dashboard`
4. **Crea el puerto 30002**

## 🎯 Recomendación

**Usa la Opción 1**: Elimina el puerto 30002 del servicio viejo, luego créalo en el nuevo servicio.

---

**Ve al servicio viejo "dashboard", elimina el puerto 30002, y luego vuelve al nuevo servicio para crearlo.**

