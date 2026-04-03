#!/bin/bash

# Script para verificar qué puertos de correo están disponibles

echo "=== Verificando puertos de correo ==="

SERVER_IP="72.61.58.240"

echo ""
echo "Verificando puertos IMAP:"
echo "Puerto 993 (IMAP SSL):"
timeout 3 bash -c "echo > /dev/tcp/$SERVER_IP/993" 2>&1 && echo "  ✅ ACCESIBLE" || echo "  ❌ No accesible"

echo "Puerto 143 (IMAP sin SSL):"
timeout 3 bash -c "echo > /dev/tcp/$SERVER_IP/143" 2>&1 && echo "  ✅ ACCESIBLE" || echo "  ❌ No accesible"

echo ""
echo "Verificando puertos SMTP:"
echo "Puerto 587 (SMTP):"
timeout 3 bash -c "echo > /dev/tcp/$SERVER_IP/587" 2>&1 && echo "  ✅ ACCESIBLE" || echo "  ❌ No accesible"

echo "Puerto 465 (SMTP SSL):"
timeout 3 bash -c "echo > /dev/tcp/$SERVER_IP/465" 2>&1 && echo "  ✅ ACCESIBLE" || echo "  ❌ No accesible"

echo "Puerto 25 (SMTP estándar):"
timeout 3 bash -c "echo > /dev/tcp/$SERVER_IP/25" 2>&1 && echo "  ✅ ACCESIBLE" || echo "  ❌ No accesible"

echo ""
echo "=== Verificación completada ==="
echo ""
echo "Recomendación:"
echo "  - Si puerto 993 está accesible: Usa SSL (puerto 993)"
echo "  - Si solo puerto 143 está accesible: Usa sin SSL (puerto 143)"
echo "  - Si ningún puerto está accesible: No hay servidor de correo configurado"






