#!/bin/bash
# Verifica si la web en producción (www.checkin24hs.com) tiene los cambios de Flor estilo WhatsApp.
# Uso: bash scripts/verificar_flor_web_servidor.sh
# También podés ejecutarlo desde tu PC (no hace falta estar en el servidor).

BASE_URL="${1:-https://www.checkin24hs.com}"
echo "=== Verificando Flor en: $BASE_URL ==="

FAIL=0

# 1. flor-ai-service.js debe contener FLOR_REGLAS_PRIORIDAD y buildHotelsBlockWhatsAppStyle
echo -n "  flor-ai-service.js (estilo WhatsApp): "
FLOR_JS=$(curl -sL "${BASE_URL}/flor-ai-service.js" 2>/dev/null || true)
if echo "$FLOR_JS" | grep -q "FLOR_REGLAS_PRIORIDAD"; then
  echo "OK (FLOR_REGLAS_PRIORIDAD encontrado)"
else
  echo "FALLO - No se encontró FLOR_REGLAS_PRIORIDAD. ¿Desplegaste después de hacer push?"
  FAIL=1
fi
if echo "$FLOR_JS" | grep -q "buildHotelsBlockWhatsAppStyle"; then
  echo "  buildHotelsBlockWhatsAppStyle: OK"
else
  echo "  buildHotelsBlockWhatsAppStyle: FALLO"
  FAIL=1
fi

# 2. flor-knowledge-base.js debe cargar promptGeneral y flor_info
echo -n "  flor-knowledge-base.js (promptGeneral + flor_info): "
KB_JS=$(curl -sL "${BASE_URL}/flor-knowledge-base.js" 2>/dev/null || true)
if echo "$KB_JS" | grep -q "promptGeneral"; then
  echo "OK (promptGeneral)"
else
  echo "FALLO - No se encontró promptGeneral"
  FAIL=1
fi
if echo "$KB_JS" | grep -q "flor_info"; then
  echo "  flor_info en select: OK"
else
  echo "  flor_info: FALLO"
  FAIL=1
fi

# 3. flor-chatbot.html debe tener florConfigReady (saludo después de config)
echo -n "  flor-chatbot.html (saludo tras config): "
CHATBOT_HTML=$(curl -sL "${BASE_URL}/flor-chatbot.html" 2>/dev/null || true)
if echo "$CHATBOT_HTML" | grep -q "florConfigReady"; then
  echo "OK"
else
  echo "FALLO - No se encontró florConfigReady"
  FAIL=1
fi

echo ""
if [ $FAIL -eq 0 ]; then
  echo "=== Resultado: La web en el servidor SÍ tiene los cambios de Flor (estilo WhatsApp). ==="
  exit 0
else
  echo "=== Resultado: La web en el servidor NO tiene todos los cambios. ==="
  echo "Pasos: 1) En tu PC: git add . && git commit -m 'Flor web igual WhatsApp' && git push origin main"
  echo "       2) En el servidor: cd /root/checkin24hs && git pull origin main && bash scripts/deploy_web_servidor.sh"
  echo "       3) Volver a ejecutar este script para verificar."
  exit 1
fi
