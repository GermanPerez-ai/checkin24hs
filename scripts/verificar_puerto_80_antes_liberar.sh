#!/bin/bash
# Verificar qué usa el puerto 80 y qué sirve Apache antes de liberarlo para Traefik.
# Ejecutar en el servidor: bash scripts/verificar_puerto_80_antes_liberar.sh

set -e

echo "=============================================="
echo "1. QUÉ PROCESO USA EL PUERTO 80"
echo "=============================================="
sudo ss -tlnp | grep ':80 ' || echo "(nada en 80)"
echo ""

echo "=============================================="
echo "2. SITIOS APACHE HABILITADOS"
echo "=============================================="
ls -la /etc/apache2/sites-enabled/ 2>/dev/null || echo "No hay sites-enabled o no es Apache"
echo ""

echo "=============================================="
echo "3. CONTENIDO DE CADA SITIO HABILITADO"
echo "=============================================="
for f in /etc/apache2/sites-enabled/*; do
  [ -f "$f" ] || continue
  echo "--- $f ---"
  grep -E 'ServerName|DocumentRoot|ProxyPass|Listen|VirtualHost' "$f" 2>/dev/null || cat "$f"
  echo ""
done

echo "=============================================="
echo "4. ÚLTIMAS PETICIONES A APACHE (access.log)"
echo "=============================================="
if [ -f /var/log/apache2/access.log ]; then
  echo "Últimas 20 líneas:"
  tail -20 /var/log/apache2/access.log
else
  echo "No se encontró /var/log/apache2/access.log"
fi
echo ""

echo "=============================================="
echo "5. PUERTOS 80 Y 443 (resumen)"
echo "=============================================="
sudo ss -tlnp | grep -E ':80 |:443 '
echo ""
echo "Si en :80 solo ves apache2 y son sitios por defecto (000-default),"
echo "es seguro deshabilitarlos para que Traefik use el 80."
