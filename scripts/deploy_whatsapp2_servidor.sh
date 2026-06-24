#!/bin/bash
# Atajo: despliega WhatsApp Línea 2.
# Uso: cd /root/checkin24hs && bash scripts/deploy_whatsapp2_servidor.sh
exec "$(dirname "$0")/deploy_whatsapp_linea_servidor.sh" 2
