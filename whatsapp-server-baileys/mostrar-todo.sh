#!/bin/bash

clear
echo "=========================================="
echo "ESTADO COMPLETO DE BAILEYS"
echo "=========================================="
echo ""

echo "1. PM2 STATUS:"
echo "----------------------------------------"
pm2 status
echo ""

echo "2. STATUS API (WhatsApp 1):"
echo "----------------------------------------"
curl -s http://localhost:3001/api/status
echo ""
echo ""

echo "3. QR CODE (WhatsApp 1):"
echo "----------------------------------------"
curl -s http://localhost:3001/api/qr
echo ""
echo ""

echo "4. LOGS (WhatsApp 1 - últimas 50 líneas):"
echo "----------------------------------------"
pm2 logs whatsapp-1 --lines 50 --nostream
echo ""

echo "5. TODAS LAS INSTANCIAS:"
echo "----------------------------------------"
for i in 1 2 3 4; do
  echo "WhatsApp $i:"
  curl -s http://localhost:300$i/api/status
  echo ""
done

echo "6. PUERTOS:"
echo "----------------------------------------"
netstat -tulpn | grep -E "3001|3002|3003|3004" || ss -tulpn | grep -E "3001|3002|3003|3004"
echo ""

echo "=========================================="
echo "FIN - Presiona Enter para salir"
echo "=========================================="


