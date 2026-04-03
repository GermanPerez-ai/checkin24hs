#!/bin/bash
# Corregir signos "?" y problemas de codificación en dashboard.html del servidor

DASHBOARD_PATH="/root/checkin24hs/dashboard.html"
BACKUP_FILE="/root/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "🔧 CORREGIR SIGNOS '?' Y CODIFICACIÓN"
echo "=========================================="
echo ""

# Crear backup
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
echo "✅ Backup creado: $BACKUP_FILE"
echo ""

# Verificar encoding del archivo
echo "=== Verificar encoding ==="
file -i "$DASHBOARD_PATH" | head -1
echo ""

# Corregir problemas de codificación UTF-8
echo "=== Corregir problemas de codificación ==="

# Corregir "verificaciÃ³n" -> "verificación"
sed -i 's/verificaciÃ³n/verificación/g' "$DASHBOARD_PATH"
echo "✅ Corregido: verificaciÃ³n -> verificación"

# Corregir "funciÃ³n" -> "función"
sed -i 's/funciÃ³n/función/g' "$DASHBOARD_PATH"
echo "✅ Corregido: funciÃ³n -> función"

# Corregir "estÃ¡" -> "está"
sed -i 's/estÃ¡/está/g' "$DASHBOARD_PATH"
echo "✅ Corregido: estÃ¡ -> está"

# Corregir "cargÃ³" -> "cargó"
sed -i 's/cargÃ³/cargó/g' "$DASHBOARD_PATH"
echo "✅ Corregido: cargÃ³ -> cargó"

# Corregir "contraseÃ±a" -> "contraseña"
sed -i 's/contraseÃ±a/contraseña/g' "$DASHBOARD_PATH"
echo "✅ Corregido: contraseÃ±a -> contraseña"

# Corregir "cÃ³digo" -> "código"
sed -i 's/cÃ³digo/código/g' "$DASHBOARD_PATH"
echo "✅ Corregido: cÃ³digo -> código"

# Corregir "nuevo" con problemas de codificación
sed -i 's/nuevo estÃ¡/nuevo está/g' "$DASHBOARD_PATH"
sed -i 's/NO se cargÃ³/NO se cargó/g' "$DASHBOARD_PATH"
echo "✅ Corregido: otros problemas de codificación"
echo ""

# Corregir signos "?" que deberían ser emojis o texto
echo "=== Corregir signos '?' ==="

# Corregir "? Variable" -> "✅ Variable" (en console.log)
sed -i "s/console\.log('? Variable/console.log('✅ Variable/g" "$DASHBOARD_PATH"
echo "✅ Corregido: ? Variable -> ✅ Variable"

# Corregir "??" en console.log que deberían ser emojis
sed -i "s/console\.log('??/console.log('🔍/g" "$DASHBOARD_PATH"
sed -i 's/console\.log("??/console.log("🔍/g' "$DASHBOARD_PATH"
echo "✅ Corregido: ?? en console.log -> 🔍"

# Corregir "? Todas" -> "✅ Todas"
sed -i "s/console\.log('? Todas/console.log('✅ Todas/g" "$DASHBOARD_PATH"
echo "✅ Corregido: ? Todas -> ✅ Todas"

# Corregir "? Variable" en console.error
sed -i "s/console\.error('? Variable/console.error('⚠️ Variable/g" "$DASHBOARD_PATH"
echo "✅ Corregido: ? Variable en error -> ⚠️ Variable"
echo ""

# Verificar correcciones
echo "=== Verificar correcciones ==="
echo "Buscando problemas restantes..."
PROBLEMAS=$(grep -c "verificaciÃ³n\|funciÃ³n\|estÃ¡\|cargÃ³\|contraseÃ±a\|cÃ³digo" "$DASHBOARD_PATH" 2>/dev/null || echo "0")
if [ "$PROBLEMAS" -eq "0" ]; then
    echo "✅ No se encontraron más problemas de codificación"
else
    echo "⚠️  Aún hay $PROBLEMAS problemas de codificación"
fi
echo ""

# Copiar al contenedor
echo "=== Copiar al contenedor ==="
CONTAINER=$(docker service ps checkin24hs_dashboard --format "{{.Name}}" --no-trunc | head -1)
if [ -n "$CONTAINER" ]; then
    echo "Contenedor: $CONTAINER"
    docker cp "$DASHBOARD_PATH" "$CONTAINER:/app/dashboard.html"
    if [ $? -eq 0 ]; then
        echo "✅ Archivo copiado al contenedor"
    else
        echo "❌ Error al copiar al contenedor"
    fi
else
    echo "⚠️  No se encontró contenedor"
fi
echo ""

echo "=========================================="
echo "✅ Corrección completada"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Reinicia el servicio: docker service update --force checkin24hs_dashboard"
echo "2. Recarga la página con Ctrl+F5"
echo "3. Verifica que los signos '?' hayan desaparecido"
echo ""
