# 🗑️ Eliminar CRM de Forma Segura

## 📋 Estado Actual

Según la verificación:
- ✅ **Servicio activo:** `checkin24hs_crm` (corriendo)
- ✅ **DNS configurado:** `crm.checkin24hs.com` → `72.61.58.240`
- ✅ **Contenedor activo:** Desde hace 6 días
- ⚠️ **Puerto:** 3005 (interno)

---

## 🔍 Verificaciones Adicionales

Antes de eliminar, verifica:

### 1. Verificar si está accesible vía Traefik

```bash
# Verificar configuración de Traefik
docker service inspect checkin24hs_crm --format '{{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}}{{println}}{{end}}' | grep traefik

# Verificar si Traefik tiene rutas para el CRM
docker service logs traefik --tail 100 | grep -i "crm.checkin24hs.com"
```

### 2. Probar acceso desde navegador

Abre en tu navegador:
- `https://crm.checkin24hs.com`
- `http://crm.checkin24hs.com`

**Si no carga o da error 404:** El servicio está corriendo pero no está configurado en Traefik, puedes eliminarlo.

**Si carga correctamente:** Verifica si realmente lo usas antes de eliminarlo.

---

## ✅ Pasos para Eliminar el CRM

### Paso 1: Eliminar el Servicio Docker

```bash
docker service rm checkin24hs_crm
```

### Paso 2: Verificar que se Eliminó

```bash
docker service ls | grep crm
# No debe mostrar nada

docker ps | grep crm
# No debe mostrar nada
```

### Paso 3: Eliminar Configuración en EasyPanel (si existe)

1. Ve a EasyPanel
2. Busca el servicio `checkin24hs_crm` o `crm`
3. Elimínalo desde la interfaz

### Paso 4: Eliminar DNS (Opcional)

Si quieres eliminar completamente el dominio:

1. Ve a tu proveedor de DNS
2. Elimina el registro A de `crm.checkin24hs.com`

**Nota:** Si solo eliminas el servicio pero mantienes el DNS, el dominio seguirá apuntando pero no habrá nada que sirva.

### Paso 5: Limpiar Archivos (Opcional)

Los archivos del CRM están en tu repositorio local (`crm/`), no en el servidor. Puedes:

- **Conservarlos:** Por si los necesitas en el futuro
- **Mover a backups:** `mv crm backups/crm_$(date +%Y%m%d)`
- **Eliminar:** Solo si estás seguro de que no los necesitarás

---

## ⚠️ Advertencias

1. **Backup:** Si hay datos importantes en el CRM, haz backup antes de eliminar
2. **Dependencias:** Verifica que ningún otro servicio dependa del CRM
3. **DNS:** Si eliminas el DNS, puede tardar hasta 48 horas en propagarse

---

## 🔍 Verificar Dependencias

Antes de eliminar, verifica si algo depende del CRM:

```bash
# Verificar si hay referencias en otros servicios
docker service ls --format "{{.Name}}" | xargs -I {} docker service inspect {} --format '{{.Name}}: {{range $key, $value := .Spec.TaskTemplate.ContainerSpec.Labels}}{{$key}}={{$value}} {{end}}' | grep -i crm

# Verificar logs de otros servicios
docker service logs checkin24hs_dashboard --tail 50 | grep -i crm
docker service logs checkin24hs_whatsapp --tail 50 | grep -i crm
```

---

## ✅ Comandos Completos para Eliminar

```bash
# 1. Verificar estado actual
docker service ls | grep crm
docker ps | grep crm

# 2. Eliminar servicio
docker service rm checkin24hs_crm

# 3. Verificar eliminación
docker service ls | grep crm
docker ps | grep crm

# 4. Verificar que no hay contenedores huérfanos
docker ps -a | grep crm
```

---

## 📝 Después de Eliminar

1. ✅ Verificar que el servicio no existe
2. ✅ Verificar que no hay contenedores activos
3. ✅ Eliminar DNS (opcional)
4. ✅ Limpiar archivos locales (opcional)
5. ✅ Documentar la eliminación
