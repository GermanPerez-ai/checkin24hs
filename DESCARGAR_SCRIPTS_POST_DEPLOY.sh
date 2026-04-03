#!/bin/bash
# Script para descargar los scripts de post-deploy desde GitHub

cd ~/checkin24hs

echo "Descargando scripts desde GitHub..."
echo ""

# Descargar cada script
curl -s -L -o PROCESO_DEPLOY_COMPLETO.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/PROCESO_DEPLOY_COMPLETO.sh
curl -s -L -o ACTUALIZAR_ARCHIVO_SERVIDOR.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/ACTUALIZAR_ARCHIVO_SERVIDOR.sh
curl -s -L -o REAPLICAR_TRAEFIK_LABELS.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/REAPLICAR_TRAEFIK_LABELS.sh
curl -s -L -o VERIFICAR_POST_DEPLOY_COMPLETO.sh https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/VERIFICAR_POST_DEPLOY_COMPLETO.sh

# Dar permisos de ejecución
chmod +x PROCESO_DEPLOY_COMPLETO.sh
chmod +x ACTUALIZAR_ARCHIVO_SERVIDOR.sh
chmod +x REAPLICAR_TRAEFIK_LABELS.sh
chmod +x VERIFICAR_POST_DEPLOY_COMPLETO.sh

echo "✅ Scripts descargados y con permisos de ejecución"
echo ""
echo "Scripts disponibles:"
ls -lh *.sh | grep -E "PROCESO_DEPLOY|ACTUALIZAR_ARCHIVO|REAPLICAR_TRAEFIK|VERIFICAR_POST"
