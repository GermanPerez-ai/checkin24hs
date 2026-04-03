# 📐 Tamaño y resolución ideal para imagen de preview (Open Graph / WhatsApp)

## ✅ Tamaño recomendado (universal)

| Parámetro | Valor | Notas |
|-----------|--------|--------|
| **Resolución** | **1200 × 630 px** | Estándar para Facebook, WhatsApp, Twitter, LinkedIn |
| **Relación de aspecto** | **1.91:1** | Evita recortes en la mayoría de plataformas |
| **Formato** | JPG o PNG | JPG suele dar mejor compresión |

En tu `cotizador-cliente.html` ya tienes:
```html
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
```
Eso está correcto.

---

## 📱 WhatsApp (importante)

| Parámetro | Valor |
|-----------|--------|
| **Resolución recomendada** | 1200 × 630 px |
| **Tamaño máximo de archivo** | **≈ 300 KB** (WhatsApp comprime o rechaza si es muy grande) |
| **Mínimo** | 300 × 200 px |

Si la imagen pesa mucho más de 300 KB, WhatsApp puede:
- Comprimirla mucho y verse peor, o
- No mostrarla bien.

Conviene que `main.jpg` (o la que uses para `/og-cotizar.jpg`) esté **optimizada y por debajo de ~300 KB**.

---

## 📋 Otras plataformas (referencia)

| Plataforma | Recomendado | Mínimo |
|------------|-------------|--------|
| **Facebook** | 1200 × 630 px | 600 × 315 px (mín. 200 × 200) |
| **Twitter** | 1200 × 628 px (1.91:1) | 300 × 157 px |
| **LinkedIn** | 1200 × 627 px | 552 × 368 px |

---

## 🛠️ Buenas prácticas

1. **Zona segura:** Mantener texto y logo en el **60–80% central** de la imagen para evitar recortes en distintas apps.
2. **Contraste:** Colores con buen contraste para que se vea en modo claro y oscuro.
3. **Peso:** Para WhatsApp, intentar **&lt; 300 KB** (JPG con calidad 80–85% suele bastar).
4. **URL:** Siempre HTTPS (ya lo usas).

---

## 📏 Resumen rápido

- **Resolución:** **1200 × 630 px** (1.91:1).
- **Formato:** JPG (o PNG si necesitas transparencia).
- **Peso:** **&lt; 300 KB** para WhatsApp.
- **Meta tags:** `og:image:width` y `og:image:height` en 1200 y 630 (ya los tienes).

Si tus `main.jpg` de los hoteles son más grandes (p. ej. 1920×1080 o varios MB), conviene generar una versión **1200×630** y **&lt; 300 KB** específica para preview y servir esa en `/og-cotizar.jpg`.
