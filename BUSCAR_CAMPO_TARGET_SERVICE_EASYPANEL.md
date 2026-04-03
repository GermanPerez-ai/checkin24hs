# 🔍 Buscar Campo Target Service en EasyPanel

## 🎯 Dónde Buscar el Campo

En el modal "Actualizar dominio" de `dashboard.checkin24hs.com`:

### Ubicaciones Posibles:

1. **En la sección "Destino"** (donde están Protocolo, Puerto, Ruta):
   - Puede estar **debajo** de "Ruta" (haz scroll hacia abajo)
   - Puede llamarse:
     - "Target Service"
     - "Servicio de destino"
     - "Service"
     - "Servicio"
     - "Application"
     - "Aplicación"
     - "URL"
     - "Host"

2. **En otra pestaña del modal**:
   - Revisa las pestañas "Middlewares" o "SSL"
   - Puede estar en configuración avanzada

3. **Como parte del campo "Host"**:
   - Puede que el campo "Host" en la parte superior permita poner la IP
   - O puede haber un campo separado para el destino

## 🔍 Qué Buscar Exactamente

Busca un campo que actualmente tenga:
- `checkin24hs-dashboard`
- `checkin24hs_dashboard`
- `http://checkin24hs_dashboard:3000`
- O esté vacío

**Ese campo** es donde debes poner: `10.11.125.90:3000`

## 📋 Alternativa: Ver la Lista de Dominios

En la lista de dominios (antes de editar), puedes ver:
- Dominio: `dashboard.checkin24hs.com`
- Destino: `http://checkin24hs_dashboard:30002/` (o similar)

**Ese destino** es lo que necesitas cambiar. Haz clic en "Editar" y busca dónde está ese valor.

---

**¿Puedes hacer una captura de pantalla completa del modal "Actualizar dominio" (haciendo scroll si es necesario) para ver todos los campos? O dime exactamente qué campos ves en la sección "Destino".**

