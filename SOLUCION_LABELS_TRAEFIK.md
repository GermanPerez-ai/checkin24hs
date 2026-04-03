# 🔧 Solución: Labels de Traefik para checkin24hs_dashboard

## 📋 Situación Actual

El servicio `checkin24hs_dashboard` **NO tiene labels de Traefik**, por eso Traefik no puede enrutar el tráfico y aparece el error 404.

## 🔍 Diagnóstico

Primero, ejecuta el diagnóstico para entender cómo está configurado el servicio:

```bash
# En el servidor (SSH)
cd ~/checkin24hs
bash DIAGNOSTICO_SERVICIO_EASYPANEL.sh
```

Este script te dirá:
- ✅ Si el servicio está en la red `easypanel`
- ✅ Si tiene labels de EasyPanel (indica si fue creado desde EasyPanel o CLI)
- ✅ Si tiene labels de Traefik
- ✅ Qué puerto está usando
- ✅ Si Traefik está corriendo

## ✅ Soluciones

### Opción 1: Si el servicio está en EasyPanel (RECOMENDADO)

Si el servicio aparece en la lista de servicios de EasyPanel:

1. **Ve a EasyPanel** → **Servicios** → **dashboard** (o `checkin24hs_dashboard`)
2. **Busca la sección "Domain" o "Dominio"**
3. **Configura el dominio**: `dashboard.checkin24hs.com`
4. **Haz clic en "Deploy" o "Save"**
5. EasyPanel aplicará automáticamente las labels de Traefik

**Ventajas:**
- ✅ Fácil y seguro
- ✅ EasyPanel gestiona las labels automáticamente
- ✅ Si cambias el dominio, EasyPanel actualiza las labels

### Opción 2: Agregar labels manualmente (si NO está en EasyPanel)

Si el servicio **NO aparece en EasyPanel** o EasyPanel no permite configurar el dominio:

```bash
# En el servidor (SSH)
cd ~/checkin24hs
bash AGREGAR_LABELS_TRAEFIK_MANUAL.sh
```

Este script:
- ✅ Verifica que el servicio esté en la red `easypanel`
- ✅ Obtiene el puerto del servicio
- ✅ Agrega todas las labels de Traefik necesarias
- ✅ Verifica que se aplicaron correctamente

**Labels que se agregan:**
- `traefik.enable=true`
- `traefik.http.routers.dashboard.rule=Host(\`dashboard.checkin24hs.com\`)`
- `traefik.http.routers.dashboard.entrypoints=web,websecure`
- `traefik.http.services.dashboard.loadbalancer.server.port=3000`

### Opción 3: Recrear el servicio desde EasyPanel

Si el servicio fue creado manualmente y quieres que EasyPanel lo gestione completamente:

1. **En EasyPanel:**
   - Ve a **Projects** → **New Service** (o **New Project**)
   - Nombre: `dashboard` (o `checkin24hs-dashboard`)
   - Fuente: GitHub, rama `working-version`, ruta `/deploy`
   - Puerto: `3000` (o el puerto que uses)
   - **Configura el dominio**: `dashboard.checkin24hs.com`
   - **Haz clic en "Deploy"**

2. **Espera a que se cree el servicio**

3. **Verifica que funciona:**
   ```bash
   curl -I https://dashboard.checkin24hs.com
   ```

4. **Elimina el servicio viejo** (después de verificar que el nuevo funciona):
   ```bash
   docker service rm checkin24hs_dashboard
   ```

## 🎯 Recomendación

**Usa la Opción 1** si el servicio está en EasyPanel. Es la forma más segura y fácil.

**Usa la Opción 2** si el servicio NO está en EasyPanel o si necesitas una solución rápida.

**Usa la Opción 3** si quieres que EasyPanel gestione completamente el servicio (recomendado a largo plazo).

## ✅ Verificación

Después de aplicar cualquiera de las soluciones:

```bash
# 1. Verificar que las labels se aplicaron
docker service inspect checkin24hs_dashboard --format '{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{"\n"}}{{end}}' | grep traefik

# 2. Esperar 10-30 segundos para que Traefik detecte el cambio

# 3. Probar el acceso
curl -I https://dashboard.checkin24hs.com

# 4. Si hay problemas, ver logs de Traefik
docker service logs traefik --tail 50
```

## 📝 Notas

- **Las labels de Traefik son necesarias** para que Traefik sepa cómo enrutar el tráfico
- **El servicio debe estar en la red `easypanel`** para que Traefik pueda acceder a él
- **Después de agregar labels, espera 10-30 segundos** para que Traefik detecte el cambio
- **Si cambias el dominio**, actualiza las labels o reconfigura en EasyPanel
