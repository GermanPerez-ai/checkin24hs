# 🖼️ Sistema Dinámico de Imágenes de Preview

## ✨ Características

El sistema ahora **detecta automáticamente todos los hoteles disponibles** en el directorio `hotel-images`. Esto significa:

- ✅ **No necesitas modificar código** cuando agregues un nuevo hotel
- ✅ **Escalable automáticamente** - cualquier hotel nuevo estará disponible
- ✅ **Flexible** - puedes forzar un hotel específico con variable de entorno

## 🏗️ Cómo Funciona

### Detección Automática

El código busca automáticamente todos los directorios en `hotel-images/` que:
1. Empiecen con `hotel-`
2. Tengan un archivo `main.jpg` dentro

Ejemplo de estructura:
```
hotel-images/
  ├── hotel-1-puyehue/
  │   └── main.jpg
  ├── hotel-2-huilo-huilo/
  │   └── main.jpg
  ├── hotel-3-corralco/
  │   └── main.jpg
  └── hotel-nuevo/          ← ¡Nuevo hotel agregado!
      └── main.jpg          ← Automáticamente disponible
```

### Orden de Prioridad

1. **Variable de entorno `OG_COTIZAR_IMAGE`** (si está configurada)
2. **Primer hotel encontrado** (orden alfabético)

## 🔧 Cómo Cambiar la Imagen

### Opción 1: Variable de Entorno (Recomendado para producción)

En EasyPanel, agrega la variable de entorno:
```
OG_COTIZAR_IMAGE=hotel-2-huilo-huilo
```

**Ventajas:**
- ✅ No requiere rebuild
- ✅ Fácil de cambiar
- ✅ Persistente

### Opción 2: Script Guiado

```bash
cd /root/checkin24hs
./GUIAR_CAMBIO_IMAGEN_DINAMICO.sh
```

El script:
1. Detecta automáticamente todos los hoteles disponibles
2. Te muestra una lista numerada
3. Te permite seleccionar el hotel
4. Aplica el cambio (temporal o permanente)

### Opción 3: Cambio Temporal en Servidor

```bash
cd /root/checkin24hs
./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh hotel-2-huilo-huilo
```

**Nota:** Este cambio se pierde al reiniciar el servicio.

## ➕ Cómo Agregar un Nuevo Hotel

### Paso 1: Crear la estructura

```bash
mkdir -p hotel-images/hotel-6-nuevo-hotel
cp imagen.jpg hotel-images/hotel-6-nuevo-hotel/main.jpg
```

### Paso 2: ¡Listo!

El sistema **automáticamente** detectará el nuevo hotel. No necesitas:
- ❌ Modificar código
- ❌ Actualizar listas
- ❌ Hacer cambios en `server.js`

### Paso 3: (Opcional) Usar el nuevo hotel

Si quieres usar el nuevo hotel como imagen de preview:

```bash
# Temporalmente
./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh hotel-6-nuevo-hotel

# O permanentemente (agregar variable de entorno en EasyPanel)
OG_COTIZAR_IMAGE=hotel-6-nuevo-hotel
```

## 📋 Convenciones de Nombres

Para que el sistema detecte automáticamente un hotel:

1. **Directorio:** Debe empezar con `hotel-`
   - ✅ `hotel-1-puyehue`
   - ✅ `hotel-2-huilo-huilo`
   - ✅ `hotel-10-nuevo-hotel`
   - ❌ `puyehue` (no empieza con hotel-)
   - ❌ `hotel_puyehue` (usa guión, no guión bajo)

2. **Imagen principal:** Debe llamarse `main.jpg`
   - ✅ `main.jpg`
   - ❌ `principal.jpg`
   - ❌ `main.png`

## 🔍 Verificar Hoteles Disponibles

Para ver qué hoteles detecta el sistema:

```bash
# Desde el servidor
cd /root/checkin24hs
ls -d hotel-images/hotel-*/main.jpg | sed 's|hotel-images/||; s|/main.jpg||'
```

O ejecuta el script guiado y verás la lista automáticamente.

## 🎯 Ejemplos de Uso

### Ejemplo 1: Agregar hotel-6-villarrica

```bash
# 1. Crear estructura
mkdir -p hotel-images/hotel-6-villarrica
cp villarrica.jpg hotel-images/hotel-6-villarrica/main.jpg

# 2. El sistema ya lo detecta automáticamente
# 3. Para usarlo como preview:
./APLICAR_CAMBIO_IMAGEN_SERVIDOR.sh hotel-6-villarrica
```

### Ejemplo 2: Cambiar a hotel-3-corralco permanentemente

1. En EasyPanel, agrega variable de entorno:
   ```
   OG_COTIZAR_IMAGE=hotel-3-corralco
   ```
2. Reinicia el servicio
3. ¡Listo!

### Ejemplo 3: Rotar entre hoteles

Puedes cambiar la variable de entorno periódicamente para rotar la imagen de preview.

## 🐛 Troubleshooting

### El hotel no aparece en la lista

1. Verifica que el directorio empiece con `hotel-`
2. Verifica que exista `main.jpg` dentro del directorio
3. Verifica permisos de lectura

### La imagen no se muestra

1. Verifica que `main.jpg` sea una imagen válida
2. Verifica que el archivo no esté corrupto
3. Revisa los logs del contenedor:
   ```bash
   docker service logs checkin24hs_dashboard --tail 50
   ```

## 📝 Notas Técnicas

- El sistema busca en dos ubicaciones:
  - `../hotel-images/` (desde el directorio del dashboard)
  - `./hotel-images/` (dentro del contenedor)
- Los hoteles se ordenan alfabéticamente para consistencia
- El cache es de 1 día (`max-age=86400`)
