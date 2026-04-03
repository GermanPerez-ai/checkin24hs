# 📋 Configuración del Nuevo Servicio Dashboard

## 🎯 Configuración Completa

Al crear el nuevo servicio `checkin24hs-dashboard` (con guión), usa esta configuración:

### 1. Fuente (Source)

- **Tipo**: GitHub
- **Propietario**: `GermanPerez-ai`
- **Repositorio**: `checkin24hs`
- **Rama**: `working-version` (la que creamos hace poco)
- **Ruta de compilación**: `/deploy` (como estaba ayer)

### 2. Puertos

- **Protocolo**: `tcp`
- **Publicado**: `30002`
- **Destino**: `3000`

### 3. Implementar

- **Réplicas**: `1`
- **Cero tiempo de inactividad**: Activado

### 4. Dominios

Después de crear el servicio, configura el dominio:
- **Host**: `dashboard.checkin24hs.com`
- **Protocolo**: `HTTP`
- **Puerto**: `3000`
- **Target Service**: `checkin24hs-dashboard` (con guión - debería aparecer automáticamente)

## ✅ Pasos

1. **Crea el nuevo servicio** con nombre `checkin24hs-dashboard` (con guión)
2. **Configura la fuente** como arriba
3. **Configura los puertos** (30002:3000)
4. **Implementa** el servicio
5. **Configura el dominio** para que apunte al nuevo servicio
6. **Elimina el servicio viejo** `checkin24hs_dashboard`

---

**La configuración más importante es:**
- **Repositorio**: `checkin24hs`
- **Rama**: `working-version`
- **Ruta de compilación**: `/deploy`

