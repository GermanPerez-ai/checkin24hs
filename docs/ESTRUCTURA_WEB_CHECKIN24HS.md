# Estructura visual de la web checkin24hs.com

Referencia rápida del orden de secciones y dónde está cada cosa.

---

## Home (página principal)

```
┌─────────────────────────────────────────────────────────────┐
│  HEADER (barra azul)                                        │
│  Checkin24hs    Inicio | Destinos | Novedades | Nosotros    │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  SLIDER / CARRUSEL (imagen 1200×400 o 3:1, max 320px alto)  │
│  "Toda la Patagonia..." + botón                             │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  NOVEDADES (#novedades)                                     │
│  Título "Novedades" + grid de tarjetas (imagen 800×500)     │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  ALOJAMIENTOS (hoteles)                                      │
│  Título "Alojamientos" + grid de HotelCard                   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  DESTINOS (#destinos)                                        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  SOBRE NOSOTROS (#sobre-nosotros)                           │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  FOOTER                                                      │
└─────────────────────────────────────────────────────────────┘
                    ┌──────┐
                    │ Flor │  ← Widget flotante (chat)
                    │ Widget│
                    └──────┘
```

---

## Rutas

| Ruta | Contenido |
|------|-----------|
| `/` | Home (estructura de arriba) |
| `/hotel/:slug` | Detalle de un hotel |
| `/novedad/:slugOrId` | Detalle de una novedad (título, imagen, cuerpo de nota) |

---

## Archivos principales (checkin24hs-web)

| Qué | Archivo |
|-----|---------|
| Orden de secciones en Home | `src/pages/Home.tsx` |
| Slider / carrusel | `src/components/SliderOfertas.tsx` + `.module.css` |
| Sección Novedades | `src/components/Novedades.tsx` + `.module.css` |
| Sección Alojamientos | `src/pages/Home.tsx` (grid + HotelCard) |
| Detalle de novedad | `src/pages/NovedadDetail.tsx` + `.module.css` |
| Header | `src/components/Header.tsx` + `.module.css` |
| Estilos globales / container | `src/index.css` |

---

## Cómo ver la web en vivo

En la carpeta del proyecto:

```powershell
cd C:\Users\German\Downloads\Checkin24hs\checkin24hs-web
npm install
npm run dev
```

Abrí en el navegador la URL que muestre (ej. `http://localhost:5173`) para ver la Home y navegar. Así podés ubicar cada sección en pantalla y probar cambios al instante.
