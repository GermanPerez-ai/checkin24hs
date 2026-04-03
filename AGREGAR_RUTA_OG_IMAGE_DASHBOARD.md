# 📸 Agregar Ruta para Imagen de Preview en Dashboard

## ✅ Cambios Realizados

Se ha agregado una ruta especial en el servidor del dashboard para servir la imagen de preview del cotizador.

### 1. **Ruta Agregada**: `/og-cotizar.jpg`

La ruta está disponible en: `https://dashboard.checkin24hs.com/og-cotizar.jpg`

### 2. **Archivos Modificados**

#### `checkin24hs-admin/server.js`
- ✅ Agregada ruta especial `/og-cotizar.jpg`
- ✅ Busca imágenes de hoteles en múltiples ubicaciones
- ✅ Prioridad: `hotel-1-puyehue/main.jpg` → otros hoteles

#### `checkin24hs-admin/Dockerfile`
- ✅ Modificado para copiar `server.js` real (no generado con printf)
- ✅ El servidor buscará imágenes dinámicamente

#### `cotizador-cliente.html`
- ✅ Actualizado `og:image` a `https://dashboard.checkin24hs.com/og-cotizar.jpg`
- ✅ Actualizado `twitter:image` a la misma URL

## 🚀 Próximos Pasos

### 1. Subir Cambios a GitHub

```bash
cd C:\Users\German\Downloads\Checkin24hs
git add checkin24hs-admin/server.js checkin24hs-admin/Dockerfile cotizador-cliente.html
git commit -m "Agregar ruta /og-cotizar.jpg en dashboard para preview de Open Graph"
git push origin main
```

### 2. Hacer Redeploy en EasyPanel

1. Ve a EasyPanel
2. Abre el servicio del dashboard (`checkin24hs-dashboard`)
3. Ve a la pestaña **"Deployments"** o **"Implementaciones"**
4. Haz clic en **"Redeploy"** o **"Reconstruir"**
5. Espera a que termine la construcción (2-5 minutos)

### 3. Verificar que Funciona

1. **Probar la ruta directamente:**
   ```
   https://dashboard.checkin24hs.com/og-cotizar.jpg
   ```
   Debería mostrar una imagen de hotel.

2. **Probar el preview en WhatsApp:**
   - Comparte `https://cotizar.checkin24hs.com/` en WhatsApp
   - Debería aparecer con la imagen del preview

## 🔍 Solución de Problemas

### Si la imagen no aparece (404)

El servidor busca las imágenes en estas ubicaciones (en orden):
1. `../hotel-images/hotel-1-puyehue/main.jpg` (desde la raíz del proyecto)
2. `./hotel-images/hotel-1-puyehue/main.jpg` (desde el contenedor)
3. Otros hoteles en el mismo orden

**Solución**: Asegúrate de que las imágenes de hoteles estén disponibles en el contexto de build de EasyPanel.

### Si necesitas copiar las imágenes al contenedor

Si EasyPanel construye desde `/checkin24hs-admin`, las imágenes no estarán disponibles automáticamente. Opciones:

**Opción 1**: Cambiar el contexto de build en EasyPanel a la raíz del proyecto (`/`)

**Opción 2**: Copiar las imágenes manualmente al contenedor después del deploy:
```bash
# En el servidor
docker exec -it <container_id> mkdir -p /app/hotel-images
docker cp hotel-images/hotel-1-puyehue <container_id>:/app/hotel-images/
```

**Opción 3**: Usar un volumen montado en EasyPanel para las imágenes

## 📋 Verificación Final

- [ ] Cambios subidos a GitHub
- [ ] Redeploy realizado en EasyPanel
- [ ] Ruta `/og-cotizar.jpg` accesible
- [ ] Preview funciona en WhatsApp
