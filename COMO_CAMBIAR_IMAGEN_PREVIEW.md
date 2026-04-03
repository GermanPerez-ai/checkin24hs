# 🖼️ Cómo Cambiar la Imagen de Preview del Cotizador

La imagen que aparece en el preview de WhatsApp cuando se envía el enlace `https://cotizar.checkin24hs.com/` se puede cambiar de varias formas.

## 📋 Hoteles Disponibles

1. `hotel-1-puyehue`
2. `hotel-2-huilo-huilo`
3. `hotel-3-corralco`
4. `hotel-4-futangue`
5. `hotel-5-aguas-calientes`

## 🔧 Métodos para Cambiar la Imagen

### Método 1: Usar el Script Automático (Recomendado)

```bash
# Desde el servidor
cd /root/checkin24hs
./CAMBIAR_IMAGEN_PREVIEW.sh hotel-2-huilo-huilo
```

El script te preguntará si quieres:
- Aplicar solo en el servidor (temporal)
- Cambiar en el código (permanente)
- Ambos

### Método 2: Cambiar el Orden en server.js (Permanente)

Edita `checkin24hs-admin/server.js` y cambia el orden del array `hotels`:

```javascript
const hotels = [
  'hotel-2-huilo-huilo',  // ← Poner el hotel que quieres primero
  'hotel-1-puyehue',
  'hotel-3-corralco',
  'hotel-4-futangue',
  'hotel-5-aguas-calientes'
];
```

Luego:
1. Haz commit y push a GitHub
2. Haz rebuild desde EasyPanel

### Método 3: Usar Variable de Entorno (Flexible)

El código ahora soporta la variable de entorno `OG_COTIZAR_IMAGE`:

```bash
# En EasyPanel, agrega la variable de entorno:
OG_COTIZAR_IMAGE=hotel-2-huilo-huilo
```

Esto hará que siempre use ese hotel, sin importar el orden del array.

### Método 4: Cambiar Directamente en el Servidor (Temporal)

```bash
# 1. Descargar el script
cd /root/checkin24hs
./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh hotel-2-huilo-huilo
```

**Nota:** Este cambio se perderá al reiniciar el servicio.

## 🎯 Cambio Rápido (Solo Servidor)

Si solo quieres probar rápidamente:

```bash
# Desde el servidor
cd /root/checkin24hs
./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh hotel-2-huilo-huilo
```

## 🔄 Cambio Permanente

1. Edita `checkin24hs-admin/server.js`
2. Cambia el orden del array `hotels` (pon el hotel que quieres primero)
3. Haz commit y push:
   ```bash
   git add checkin24hs-admin/server.js
   git commit -m "Cambiar imagen de preview a hotel-2-huilo-huilo"
   git push origin main
   ```
4. Haz rebuild desde EasyPanel

## ✅ Verificar el Cambio

```bash
# Desde el servidor
curl -I https://dashboard.checkin24hs.com/og-cotizar.jpg

# Debería mostrar:
# HTTP/2 200
# content-type: image/jpeg
```

Luego envía un mensaje de WhatsApp con el enlace `https://cotizar.checkin24hs.com/` para ver el preview.

## 📝 Notas

- El cache del preview es de 1 día (`max-age=86400`)
- Si cambias la imagen, puede tomar hasta 24 horas para que WhatsApp actualice el cache
- Para forzar actualización en WhatsApp, cambia ligeramente la URL (ej: agregar `?v=2`)
