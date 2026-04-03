# 🗑️ Eliminar Servicio CRM - Guía Completa

## 📋 Pasos para Eliminar el CRM

### Paso 1: Ejecutar el Script de Eliminación

En el servidor, ejecuta:

```bash
cd ~/checkin24hs
chmod +x ELIMINAR_SERVICIO_CRM.sh
./ELIMINAR_SERVICIO_CRM.sh
```

El script:
- ✅ Verifica que el servicio existe
- ✅ Muestra información del servicio
- ✅ Pide confirmación antes de eliminar
- ✅ Elimina el servicio
- ✅ Verifica que se eliminó correctamente
- ✅ Limpia contenedores si es necesario

---

### Paso 2: Eliminar Dominio en EasyPanel (Opcional)

Si el dominio está configurado en EasyPanel:

1. **Accede a EasyPanel**
2. **Ve al servicio:** `checkin24hs_crm` o `crm`
3. **Ve a la pestaña "Dominios"** o "Domains"
4. **Elimina el dominio:** `crm.checkin24hs.com`
5. **Guarda los cambios**

---

### Paso 3: Eliminar DNS (Opcional)

Si quieres eliminar completamente el dominio:

1. **Accede a tu proveedor de DNS** (Cloudflare, Namecheap, etc.)
2. **Busca el dominio:** `checkin24hs.com`
3. **Elimina el registro A:** `crm.checkin24hs.com` → `72.61.58.240`
4. **Guarda los cambios**

**Nota:** La propagación DNS puede tardar hasta 48 horas.

---

### Paso 4: Archivar Directorio crm/ (Opcional)

Los archivos en `crm/` no se usan por `dashboard.html`, pero puedes conservarlos:

**Opción A: Mover a backups**
```bash
# En el servidor (si los archivos están ahí)
mv crm backups/crm_$(date +%Y%m%d)

# O desde tu máquina local (PowerShell)
Move-Item -Path "crm" -Destination "backups\crm_$(Get-Date -Format 'yyyyMMdd')"
```

**Opción B: Eliminar completamente**
```bash
# Solo si estás seguro de que no los necesitarás
rm -rf crm
```

---

## ✅ Verificación Post-Eliminación

Después de eliminar, verifica:

```bash
# 1. Verificar que el servicio no existe
docker service ls | grep crm
# No debe mostrar nada

# 2. Verificar que no hay contenedores activos
docker ps | grep crm
# No debe mostrar nada

# 3. Verificar que no hay contenedores detenidos (opcional)
docker ps -a | grep crm
# Puede mostrar contenedores detenidos (se pueden eliminar)
```

---

## 🔍 Comandos Manuales (Alternativa)

Si prefieres ejecutar los comandos manualmente:

```bash
# 1. Verificar servicio
docker service ls | grep crm

# 2. Eliminar servicio
docker service rm checkin24hs_crm

# 3. Verificar eliminación
docker service ls | grep crm

# 4. Verificar contenedores
docker ps | grep crm
docker ps -a | grep crm

# 5. Eliminar contenedores detenidos (opcional)
docker ps -a | grep crm | awk '{print $1}' | xargs docker rm -f
```

---

## ⚠️ Advertencias

1. **Backup:** Si hay datos importantes en el CRM, haz backup antes de eliminar
2. **Dependencias:** Ya verificamos que `dashboard.html` NO depende del CRM
3. **DNS:** Si eliminas el DNS, puede tardar hasta 48 horas en propagarse
4. **Archivos:** Los archivos en `crm/` no se usan, pero puedes conservarlos por si acaso

---

## ✅ Checklist Final

- [ ] Servicio Docker eliminado
- [ ] Contenedores detenidos/eliminados
- [ ] Dominio eliminado en EasyPanel (opcional)
- [ ] DNS eliminado (opcional)
- [ ] Archivos archivados o eliminados (opcional)
- [ ] Verificación completada

---

## 📝 Notas

- El servicio `checkin24hs_crm` es independiente de `dashboard.html`
- Eliminarlo NO afecta el funcionamiento del dashboard
- Los archivos de Flor en la raíz (`flor-*.js`) se conservan y se siguen usando
- El código de Flor está inline en `dashboard.html`, no depende de archivos externos
