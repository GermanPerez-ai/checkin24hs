# Imagen personalizada para el preview (WhatsApp / Open Graph)

## Dónde poner tu imagen

Coloca tu imagen en:

```
hotel-images/og-preview.jpg
```

Es decir:
- Carpeta: **hotel-images** (la misma donde están hotel-1-puyehue, hotel-2-huilo-huilo, etc.)
- Nombre del archivo: **og-preview.jpg** (exactamente así)

Si existe `og-preview.jpg`, el sistema la usará **siempre** para el preview del enlace (tiene prioridad sobre los hoteles).

## Requisitos recomendados

- **Formato:** JPG
- **Resolución:** 1200 × 630 px (para que se vea bien en WhatsApp/Facebook)
- **Peso:** menos de 300 KB (WhatsApp funciona mejor así)

## Después de subir la imagen

1. **En tu máquina local:** guarda el archivo como `hotel-images/og-preview.jpg`.
2. **En el servidor:** si el dashboard ya tiene el código actualizado, tendrías que tener también `hotel-images/og-preview.jpg` en el contexto del dashboard (o en el servidor donde corre el contenedor).

Si el dashboard se construye desde GitHub y no incluye `hotel-images` en la imagen, entonces la imagen personalizada solo funcionará si:
- La montas como volumen en el contenedor del dashboard, o
- La copias dentro del contenedor en la ruta que lee el server.js.

El server.js busca en:
- `../hotel-images/og-preview.jpg` (respecto al directorio del dashboard)
- `./hotel-images/og-preview.jpg` (dentro del contenedor)

Por tanto, en el servidor tendrías que asegurar que el contenedor del dashboard tenga acceso a `hotel-images/og-preview.jpg` (por volumen, copia, o incluyéndolo en el build).
