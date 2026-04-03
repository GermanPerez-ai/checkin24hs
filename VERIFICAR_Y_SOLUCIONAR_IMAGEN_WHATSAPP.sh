#!/bin/bash
# Script para verificar y solucionar el problema de imagen en WhatsApp

echo "=========================================="
echo "🔍 VERIFICANDO IMAGEN DE PREVIEW"
echo "=========================================="
echo ""

# 1. Verificar que la ruta funciona
echo "1️⃣ Verificando ruta /og-cotizar.jpg..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://dashboard.checkin24hs.com/og-cotizar.jpg)
CONTENT_TYPE=$(curl -s -I https://dashboard.checkin24hs.com/og-cotizar.jpg 2>/dev/null | grep -i "content-type" | cut -d' ' -f2 | tr -d '\r')
SIZE=$(curl -s -I https://dashboard.checkin24hs.com/og-cotizar.jpg 2>/dev/null | grep -i "content-length" | cut -d' ' -f2 | tr -d '\r')

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ HTTP 200 - La ruta funciona"
    echo "   Content-Type: $CONTENT_TYPE"
    if [ ! -z "$SIZE" ] && [ "$SIZE" != "0" ]; then
        echo "   Tamaño: $SIZE bytes"
        
        # Verificar que sea una imagen válida
        if echo "$CONTENT_TYPE" | grep -qi "image"; then
            echo "   ✅ Es una imagen válida"
        else
            echo "   ⚠️  Content-Type no es image/*"
        fi
    else
        echo "   ⚠️  Tamaño es 0 o no disponible"
    fi
else
    echo "   ❌ HTTP $HTTP_CODE - La ruta no funciona"
    exit 1
fi
echo ""

# 2. Verificar que la imagen sea accesible desde fuera
echo "2️⃣ Verificando accesibilidad desde fuera..."
# Intentar descargar la imagen
TEMP_IMG="/tmp/test_og_image_$(date +%s).jpg"
curl -s -o "$TEMP_IMG" https://dashboard.checkin24hs.com/og-cotizar.jpg

if [ -f "$TEMP_IMG" ] && [ -s "$TEMP_IMG" ]; then
    IMG_SIZE=$(stat -f%z "$TEMP_IMG" 2>/dev/null || stat -c%s "$TEMP_IMG" 2>/dev/null)
    echo "   ✅ Imagen descargable"
    echo "   Tamaño del archivo: $IMG_SIZE bytes"
    
    # Verificar que sea una imagen JPEG válida
    if file "$TEMP_IMG" | grep -qi "jpeg\|jpg"; then
        echo "   ✅ Es un JPEG válido"
    else
        echo "   ⚠️  Puede no ser un JPEG válido"
        file "$TEMP_IMG"
    fi
    
    rm -f "$TEMP_IMG"
else
    echo "   ❌ No se pudo descargar la imagen"
fi
echo ""

# 3. Verificar headers importantes
echo "3️⃣ Verificando headers HTTP..."
HEADERS=$(curl -s -I https://dashboard.checkin24hs.com/og-cotizar.jpg)

echo "   Headers importantes:"
echo "$HEADERS" | grep -iE "content-type|content-length|cache-control|access-control" | head -5
echo ""

# 4. Problema común: WhatsApp cachea las imágenes
echo "4️⃣ Solución para el cache de WhatsApp..."
echo ""
echo "   ⚠️  WhatsApp cachea las imágenes de preview por varias horas/días."
echo "   Para forzar actualización, necesitamos agregar un parámetro de versión."
echo ""
echo "   Opciones:"
echo "   1) Agregar parámetro ?v=2 a la URL de la imagen en cotizador-cliente.html"
echo "   2) Esperar que WhatsApp actualice el cache (puede tardar horas)"
echo "   3) Usar una URL diferente temporalmente"
echo ""

# 5. Verificar meta tags en cotizador-cliente.html
echo "5️⃣ Verificando meta tags en cotizador-cliente.html..."
if [ -f "cotizador-cliente.html" ]; then
    OG_IMAGE=$(grep -i "og:image" cotizador-cliente.html | grep -o 'content="[^"]*"' | cut -d'"' -f2)
    if [ ! -z "$OG_IMAGE" ]; then
        echo "   ✅ Meta tag og:image encontrado: $OG_IMAGE"
        
        # Verificar si tiene parámetro de versión
        if echo "$OG_IMAGE" | grep -q "?"; then
            echo "   ✅ Ya tiene parámetro de versión"
        else
            echo "   ⚠️  No tiene parámetro de versión (recomendado agregar ?v=2)"
        fi
    else
        echo "   ❌ No se encontró meta tag og:image"
    fi
else
    echo "   ⚠️  No se encontró cotizador-cliente.html en el directorio actual"
fi
echo ""

echo "=========================================="
echo "✅ VERIFICACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "💡 RECOMENDACIONES:"
echo ""
echo "1. Agregar parámetro de versión a la URL de la imagen:"
echo "   Cambiar: https://dashboard.checkin24hs.com/og-cotizar.jpg"
echo "   Por:     https://dashboard.checkin24hs.com/og-cotizar.jpg?v=2"
echo ""
echo "2. Verificar que la imagen sea accesible públicamente"
echo "   (sin autenticación requerida)"
echo ""
echo "3. Esperar o forzar actualización del cache de WhatsApp:"
echo "   - Puede tardar varias horas"
echo "   - O usar una URL diferente temporalmente"
echo ""
