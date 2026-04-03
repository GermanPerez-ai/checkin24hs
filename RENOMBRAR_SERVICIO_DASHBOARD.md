# 🔧 Renombrar Servicio Dashboard

## 🎯 Problema

- El servicio se llama `checkin24hs_dashboard` (con guión bajo)
- El alias de red es `checkin24hs-dashboard` (con guión)
- EasyPanel usa el nombre del servicio en el dominio y no permite editarlo
- Por eso el alias no funciona

## ✅ Solución: Renombrar el Servicio

Necesitamos renombrar el servicio de `checkin24hs_dashboard` a `checkin24hs-dashboard` para que coincida con el alias de red.

### Opción 1: Renombrar desde EasyPanel (Si está disponible)

1. **Ve a** → **Servicios** → **dashboard**
2. **Busca una opción** para renombrar el servicio:
   - Puede estar en "Configuración" o "Settings"
   - O en un menú de tres puntos (...)
   - O en "Avanzado"
3. **Cambia el nombre** de `checkin24hs_dashboard` a `checkin24hs-dashboard`
4. **Guarda** los cambios

### Opción 2: Renombrar desde SSH

Si EasyPanel no permite renombrar, podemos hacerlo desde SSH:

```bash
# 1. Escalar el servicio a 0
docker service scale checkin24hs_dashboard=0
sleep 10

# 2. Crear un nuevo servicio con el nombre correcto
docker service create \
  --name checkin24hs-dashboard \
  --network easypanel \
  --publish published=30002,target=3000,protocol=tcp,mode=host \
  --replicas 1 \
  easypanel/checkin24hs/dashboard:latest

# 3. Verificar que se creó
docker service ps checkin24hs-dashboard

# 4. Eliminar el servicio viejo (después de verificar que el nuevo funciona)
# docker service rm checkin24hs_dashboard
```

### Opción 3: Recrear el Servicio desde EasyPanel

1. **Crea un nuevo servicio** llamado `checkin24hs-dashboard` (con guión)
2. **Copia toda la configuración** del servicio viejo:
   - Fuente: GitHub, rama `working-version`, ruta `/deploy`
   - Variables de entorno (si tiene)
   - Puertos: 30002:3000
3. **Implementa** el nuevo servicio
4. **Configura el dominio** para que apunte al nuevo servicio
5. **Elimina el servicio viejo** `checkin24hs_dashboard`

## 🎯 Recomendación

**Usa la Opción 3** (recrear desde EasyPanel). Es más segura y no requiere SSH.

---

**¿Puedes buscar en EasyPanel si hay una opción para renombrar el servicio? Si no, podemos recrearlo con el nombre correcto.**

