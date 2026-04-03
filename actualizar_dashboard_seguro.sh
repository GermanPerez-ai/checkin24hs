#!/bin/bash

# Script seguro para actualizar dashboard.html
# Hace backup antes de modificar

echo "=========================================="
echo "🔒 Actualización Segura de Dashboard"
echo "=========================================="
echo ""

DASHBOARD_PATH="$HOME/checkin24hs/dashboard.html"
BACKUP_DIR="$HOME/checkin24hs/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/dashboard_backup_$TIMESTAMP.html"

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# 1. Verificar que el archivo existe
if [ ! -f "$DASHBOARD_PATH" ]; then
    echo "❌ ERROR: No se encontró dashboard.html en $DASHBOARD_PATH"
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

# 3. Verificar tamaño del archivo
FILE_SIZE=$(stat -f%z "$DASHBOARD_PATH" 2>/dev/null || stat -c%s "$DASHBOARD_PATH" 2>/dev/null)
echo "📊 Tamaño del archivo: $FILE_SIZE bytes"
echo ""

# 4. Mostrar opciones
echo "=========================================="
echo "Opciones de actualización:"
echo "=========================================="
echo ""
echo "1. Copiar desde GitHub (recomendado)"
echo "2. Corregir solo los mensajes de puerto (mínimo)"
echo "3. Solo hacer backup (no modificar)"
echo ""
read -p "Selecciona una opción (1-3): " opcion

case $opcion in
    1)
        echo ""
        echo "📥 Descargando desde GitHub..."
        cd ~/checkin24hs
        git pull
        if [ $? -eq 0 ]; then
            echo "✅ Archivo actualizado desde GitHub"
        else
            echo "❌ ERROR: No se pudo actualizar desde GitHub"
            echo "⚠️  Restaurando backup..."
            cp "$BACKUP_FILE" "$DASHBOARD_PATH"
            exit 1
        fi
        ;;
    2)
        echo ""
        echo "🔧 Corrigiendo solo mensajes de puerto..."
        sed -i 's/puerto 3001/puerto 4001/g' "$DASHBOARD_PATH"
        sed -i 's/puerto 3002/puerto 4002/g' "$DASHBOARD_PATH"
        sed -i 's/puerto 3003/puerto 4003/g' "$DASHBOARD_PATH"
        sed -i 's/puerto 3004/puerto 4004/g' "$DASHBOARD_PATH"
        echo "✅ Mensajes de puerto corregidos"
        ;;
    3)
        echo ""
        echo "✅ Backup creado. No se modificó el archivo."
        exit 0
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

# 5. Verificar que el archivo sigue siendo válido
echo ""
echo "🔍 Verificando archivo..."
NEW_SIZE=$(stat -f%z "$DASHBOARD_PATH" 2>/dev/null || stat -c%s "$DASHBOARD_PATH" 2>/dev/null)

if [ "$NEW_SIZE" -lt 1000 ]; then
    echo "❌ ERROR: El archivo parece estar corrupto (muy pequeño)"
    echo "⚠️  Restaurando backup..."
    cp "$BACKUP_FILE" "$DASHBOARD_PATH"
    exit 1
fi

# Verificar que tiene contenido HTML básico
if ! grep -q "<!DOCTYPE html\|<html" "$DASHBOARD_PATH"; then
    echo "❌ ERROR: El archivo no parece ser HTML válido"
    echo "⚠️  Restaurando backup..."
    cp "$BACKUP_FILE" "$DASHBOARD_PATH"
    exit 1
fi

echo "✅ Archivo verificado correctamente"
echo ""

# 6. Reiniciar dashboard
echo "🔄 Reiniciando dashboard..."
pm2 restart dashboard
sleep 3

# 7. Verificar que el dashboard está corriendo
DASHBOARD_STATUS=$(pm2 jlist | grep -A 5 '"name":"dashboard"' | grep '"status"' | cut -d'"' -f4)
if [ "$DASHBOARD_STATUS" = "online" ]; then
    echo "✅ Dashboard reiniciado correctamente"
else
    echo "⚠️  ADVERTENCIA: Dashboard no está online. Estado: $DASHBOARD_STATUS"
    echo "⚠️  Revisa los logs con: pm2 logs dashboard"
fi

echo ""
echo "=========================================="
echo "📊 RESUMEN"
echo "=========================================="
echo "✅ Backup creado: $BACKUP_FILE"
echo "✅ Archivo actualizado"
echo "✅ Dashboard reiniciado"
echo ""
echo "🌐 Prueba acceder a: https://dashboard.checkin24hs.com"
echo ""
echo "🔄 Si algo falla, puedes restaurar el backup con:"
echo "   cp $BACKUP_FILE $DASHBOARD_PATH"
echo "   pm2 restart dashboard"
echo "=========================================="

