#!/bin/bash

# Script simple para corregir solo el mensaje de puerto
# Hace backup automático antes de modificar

echo "=========================================="
echo "🔧 Corrección Segura del Mensaje de Puerto"
echo "=========================================="
echo ""

DASHBOARD_PATH="$HOME/checkin24hs/dashboard.html"
BACKUP_FILE="$HOME/checkin24hs/dashboard.html.backup_$(date +%Y%m%d_%H%M%S)"

# 1. Verificar que el archivo existe
if [ ! -f "$DASHBOARD_PATH" ]; then
    echo "❌ ERROR: No se encontró dashboard.html"
    exit 1
fi

echo "✅ Archivo encontrado: $DASHBOARD_PATH"
echo ""

# 2. Crear backup
echo "📦 Creando backup..."
cp "$DASHBOARD_PATH" "$BACKUP_FILE"
if [ $? -eq 0 ]; then
    echo "✅ Backup creado: $BACKUP_FILE"
    echo ""
else
    echo "❌ ERROR: No se pudo crear el backup"
    exit 1
fi

# 3. Verificar tamaño antes
SIZE_BEFORE=$(stat -f%z "$DASHBOARD_PATH" 2>/dev/null || stat -c%s "$DASHBOARD_PATH" 2>/dev/null)
echo "📊 Tamaño antes: $SIZE_BEFORE bytes"
echo ""

# 4. Buscar si existe el mensaje con puerto 3001
echo "🔍 Buscando mensajes con puerto 3001..."
if grep -q "puerto 3001\|puerto 3002\|puerto 3003\|puerto 3004" "$DASHBOARD_PATH"; then
    echo "✅ Se encontraron mensajes con puertos antiguos"
    echo ""
    
    # 5. Corregir solo los mensajes de error
    echo "🔧 Corrigiendo mensajes..."
    sed -i 's/Verifica que el servidor esté corriendo en el puerto 3001/Verifica que el servidor esté corriendo en el puerto 4001/g' "$DASHBOARD_PATH"
    sed -i 's/Verifica que el servidor esté corriendo en el puerto 3002/Verifica que el servidor esté corriendo en el puerto 4002/g' "$DASHBOARD_PATH"
    sed -i 's/Verifica que el servidor esté corriendo en el puerto 3003/Verifica que el servidor esté corriendo en el puerto 4003/g' "$DASHBOARD_PATH"
    sed -i 's/Verifica que el servidor esté corriendo en el puerto 3004/Verifica que el servidor esté corriendo en el puerto 4004/g' "$DASHBOARD_PATH"
    
    # También corregir variaciones del mensaje
    sed -i 's/puerto 3001/puerto 4001/g' "$DASHBOARD_PATH"
    sed -i 's/puerto 3002/puerto 4002/g' "$DASHBOARD_PATH"
    sed -i 's/puerto 3003/puerto 4003/g' "$DASHBOARD_PATH"
    sed -i 's/puerto 3004/puerto 4004/g' "$DASHBOARD_PATH"
    
    echo "✅ Mensajes corregidos"
else
    echo "ℹ️  No se encontraron mensajes con puertos antiguos"
    echo "   (Puede que ya estén corregidos o el mensaje esté en otro lugar)"
fi

# 6. Verificar tamaño después
SIZE_AFTER=$(stat -f%z "$DASHBOARD_PATH" 2>/dev/null || stat -c%s "$DASHBOARD_PATH" 2>/dev/null)
echo ""
echo "📊 Tamaño después: $SIZE_AFTER bytes"

# 7. Verificar que el archivo sigue siendo válido
echo ""
echo "🔍 Verificando archivo..."
if ! grep -q "<!DOCTYPE html\|<html" "$DASHBOARD_PATH"; then
    echo "❌ ERROR: El archivo no parece ser HTML válido"
    echo "⚠️  Restaurando backup..."
    cp "$BACKUP_FILE" "$DASHBOARD_PATH"
    exit 1
fi

echo "✅ Archivo verificado correctamente"
echo ""

# 8. Reiniciar dashboard
echo "🔄 Reiniciando dashboard..."
pm2 restart dashboard
sleep 3

# 9. Verificar estado
DASHBOARD_STATUS=$(pm2 jlist 2>/dev/null | grep -A 5 '"name":"dashboard"' | grep '"status"' | cut -d'"' -f4 || echo "unknown")
if [ "$DASHBOARD_STATUS" = "online" ]; then
    echo "✅ Dashboard reiniciado correctamente"
else
    echo "⚠️  ADVERTENCIA: Revisa el estado del dashboard con: pm2 status"
fi

echo ""
echo "=========================================="
echo "✅ PROCESO COMPLETADO"
echo "=========================================="
echo ""
echo "📦 Backup guardado en:"
echo "   $BACKUP_FILE"
echo ""
echo "🌐 Prueba acceder a:"
echo "   https://dashboard.checkin24hs.com"
echo ""
echo "🔄 Si algo falla, restaura el backup con:"
echo "   cp $BACKUP_FILE $DASHBOARD_PATH"
echo "   pm2 restart dashboard"
echo ""
echo "=========================================="

