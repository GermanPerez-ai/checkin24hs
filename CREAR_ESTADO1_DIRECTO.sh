#!/bin/bash
# Comandos directos para crear estado1

cd /root/checkin24hs

BACKUP_DIR="/root/checkin24hs/backups/estado1"
mkdir -p "$BACKUP_DIR"

echo "=========================================="
echo "Creando punto de restauracion estado1"
echo "=========================================="
echo ""

# 1. Backup del archivo dashboard.html
echo "1. Guardando dashboard.html..."
cp dashboard.html "$BACKUP_DIR/dashboard.html"
echo "   OK: dashboard.html guardado"
echo ""

# 2. Backup del contenedor actual
echo "2. Guardando estado del contenedor..."
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    echo "   Contenedor: $CONTAINER_ID"
    
    # Copiar dashboard.html del contenedor
    docker cp ${CONTAINER_ID}:/app/dashboard.html "$BACKUP_DIR/dashboard.html.contenedor" 2>/dev/null && echo "   OK: Copiado del contenedor" || echo "   Advertencia: No se pudo copiar del contenedor"
    
    # Guardar información del contenedor
    docker inspect $CONTAINER_ID > "$BACKUP_DIR/contenedor_info.json" 2>/dev/null && echo "   OK: Info del contenedor guardada" || echo "   Advertencia: No se pudo guardar info"
else
    echo "   Advertencia: No hay contenedor corriendo"
fi
echo ""

# 3. Guardar información del servicio Docker
echo "3. Guardando informacion del servicio..."
docker service inspect checkin24hs_dashboard > "$BACKUP_DIR/servicio_info.json" 2>/dev/null && echo "   OK: Info del servicio guardada" || echo "   Advertencia: No se pudo guardar info del servicio"
echo ""

# 4. Crear script de restauración
echo "4. Creando script de restauracion..."
cat > "$BACKUP_DIR/restaurar_estado1.sh" << 'RESTORE_EOF'
#!/bin/bash
echo "=========================================="
echo "Restaurando desde estado1"
echo "=========================================="
BACKUP_DIR="/root/checkin24hs/backups/estado1"
cp "$BACKUP_DIR/dashboard.html" /root/checkin24hs/dashboard.html
CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
docker cp /root/checkin24hs/dashboard.html ${CONTAINER_ID}:/app/dashboard.html
docker service update --force checkin24hs_dashboard
sleep 30
NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
docker cp /root/checkin24hs/dashboard.html ${NEW_CONTAINER_ID}:/app/dashboard.html
echo "Restauracion completada. Recarga con Ctrl+F5"
RESTORE_EOF

chmod +x "$BACKUP_DIR/restaurar_estado1.sh"
echo "   OK: Script de restauracion creado"
echo ""

# 5. Crear archivo de información
cat > "$BACKUP_DIR/info.txt" << INFO_EOF
Punto de restauracion: estado1
Fecha de creacion: $(date)
Descripcion: Estado funcional antes de correcciones de emojis y funciones globales

Para restaurar ejecutar:
  bash /root/checkin24hs/backups/estado1/restaurar_estado1.sh
INFO_EOF

echo "5. Informacion guardada"
echo ""

echo "=========================================="
echo "Punto de restauracion estado1 creado"
echo "=========================================="
echo ""
echo "Ubicacion: $BACKUP_DIR"
echo ""
echo "Para restaurar en el futuro ejecuta:"
echo "  bash /root/checkin24hs/backups/estado1/restaurar_estado1.sh"
echo ""


