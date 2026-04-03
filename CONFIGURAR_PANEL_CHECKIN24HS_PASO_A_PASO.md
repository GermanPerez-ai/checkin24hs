# 🚀 Configurar panel.checkin24hs.com - Paso a Paso

## ✅ Paso 1: Ir al Servicio Dashboard

1. En EasyPanel, en el **menú lateral izquierdo**
2. Busca y haz clic en el servicio **`checkin24hs-dashboard`**
3. Verás las pestañas del servicio (Resumen, Fuente, Implementaciones, etc.)

---

## ✅ Paso 2: Ir a la Pestaña Dominios

1. En las pestañas del servicio, busca y haz clic en **"🔗 Dominios"**
2. Verás la lista de dominios actuales (puede estar vacía o tener `dashboard.checkin24hs.com`)

---

## ✅ Paso 3: Crear el Nuevo Dominio

1. Haz clic en el botón **"+"** o **"Crear dominio"** (debe estar en la parte superior o inferior de la lista)
2. Se abrirá un modal para crear el dominio

---

## ✅ Paso 4: Configurar el Dominio

En el modal que se abrió, completa los siguientes campos:

### Pestaña "Detalles" (debe estar seleccionada por defecto):

1. **HTTPS**: Déjalo activado (toggle azul) si quieres HTTPS, o desactívalo si prefieres HTTP primero
2. **Host ***: Escribe `panel.checkin24hs.com`
3. **Ruta *** (Ruta externa): Escribe `/`

### Sección "Destino" (Destination):

4. **Protocolo ***: Selecciona `HTTP` del dropdown
5. **Puerto ***: Escribe `3000`
6. **Ruta *** (Ruta interna): Escribe `/`

---

## ✅ Paso 5: Guardar

1. Revisa que todos los campos estén correctos:
   - Host: `panel.checkin24hs.com`
   - Protocolo: `HTTP`
   - Puerto: `3000`
   - Rutas: `/` (ambas)
2. Haz clic en el botón **"Crear"** o **"Guardar"** (botón verde en la parte inferior derecha)

---

## ✅ Paso 6: Esperar y Verificar

1. **Espera 30-60 segundos** para que EasyPanel configure el dominio y Traefik lo propague
2. Abre tu navegador y ve a: `https://panel.checkin24hs.com` (o `http://panel.checkin24hs.com` si desactivaste HTTPS)
3. Deberías ver la aplicación React de administración funcionando

---

## ❌ Si No Funciona

### Verificar desde SSH:

```bash
# Verificar que el servicio está corriendo
docker service ps checkin24hs_checkin24hs-dashboard --no-trunc | head -3

# Verificar logs
docker service logs checkin24hs_checkin24hs-dashboard --tail 10

# Verificar IP actual
CONTAINER_ID=$(docker ps | grep checkin24hs_checkin24hs-dashboard | awk '{print $1}' | head -1)
docker inspect $CONTAINER_ID --format '{{range $key, $value := .NetworkSettings.Networks}}{{if eq $key "easypanel"}}{{$value.IPAddress}}{{end}}{{end}}'
```

### Verificar en EasyPanel:

1. Ve al dominio `panel.checkin24hs.com` que acabas de crear
2. Verifica que esté asociado al servicio `checkin24hs-dashboard`
3. Verifica que el puerto sea `3000`

---

## 📝 Notas Importantes

- **El código NO cambia**, solo la URL de acceso
- Al crear el dominio **desde el servicio**, EasyPanel lo asocia automáticamente
- Si tienes problemas con HTTPS, primero prueba con HTTP
- El dominio puede tardar unos minutos en propagarse completamente

