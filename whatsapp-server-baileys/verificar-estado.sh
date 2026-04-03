#!/bin/bash

echo "=========================================="
echo "VERIFICACIÓN COMPLETA DE BAILEYS"
echo "=========================================="
echo ""

echo "1. ESTADO DE PM2:"
pm2 status
echo ""

echo "2. RESPUESTA DE STATUS (WhatsApp 1):"
curl -s http://localhost:3001/api/status
echo ""
echo ""

echo "3. LOGS DE WHATSAPP-1 (últimas 30 líneas):"
pm2 logs whatsapp-1 --lines 30 --nostream
echo ""

echo "4. VERIFICAR TODAS LAS INSTANCIAS:"
for i in 1 2 3 4; do
  echo "=== WhatsApp $i ==="
  curl -s http://localhost:300$i/api/status
  echo ""
done

echo "5. PUERTOS ABIERTOS:"
netstat -tulpn | grep -E "3001|3002|3003|3004"
echo ""
