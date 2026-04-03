#!/bin/bash
# =====================================================
# PROCESO DE DEPLOY COMPLETO
# =====================================================
# Este script ejecuta todos los pasos necesarios después del deploy:
# 1. Actualiza el archivo dashboard.html en el servidor
# 2. Reaplica las labels de Traefik
# 3. Verifica que todo esté correcto
# =====================================================

set -e

echo "=========================================="
echo "PROCESO DE DEPLOY COMPLETO"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =====================================================
# PASO 1: ACTUALIZAR ARCHIVO
# =====================================================
echo -e "${BLUE}=========================================="
echo "PASO 1: ACTUALIZAR ARCHIVO"
echo "==========================================${NC}"
echo ""

if [ -f "ACTUALIZAR_ARCHIVO_SERVIDOR.sh" ]; then
    bash ACTUALIZAR_ARCHIVO_SERVIDOR.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ ERROR en actualización de archivo${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ ERROR: No se encontró ACTUALIZAR_ARCHIVO_SERVIDOR.sh${NC}"
    exit 1
fi

echo ""
sleep 5

# =====================================================
# PASO 2: REAPLICAR TRAEFIK LABELS
# =====================================================
echo -e "${BLUE}=========================================="
echo "PASO 2: REAPLICAR TRAEFIK LABELS"
echo "==========================================${NC}"
echo ""

if [ -f "REAPLICAR_TRAEFIK_LABELS.sh" ]; then
    bash REAPLICAR_TRAEFIK_LABELS.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ ERROR en reaplicación de labels${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ ERROR: No se encontró REAPLICAR_TRAEFIK_LABELS.sh${NC}"
    exit 1
fi

echo ""
sleep 10

# =====================================================
# PASO 3: VERIFICAR TODO
# =====================================================
echo -e "${BLUE}=========================================="
echo "PASO 3: VERIFICAR TODO"
echo "==========================================${NC}"
echo ""

if [ -f "VERIFICAR_POST_DEPLOY_COMPLETO.sh" ]; then
    bash VERIFICAR_POST_DEPLOY_COMPLETO.sh
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Algunas verificaciones fallaron${NC}"
        echo "💡 Revisa los mensajes anteriores"
    fi
else
    echo -e "${RED}❌ ERROR: No se encontró VERIFICAR_POST_DEPLOY_COMPLETO.sh${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✅ PROCESO DE DEPLOY COMPLETO FINALIZADO"
echo "==========================================${NC}"
echo ""
