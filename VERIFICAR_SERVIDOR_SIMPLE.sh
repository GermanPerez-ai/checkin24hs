#!/bin/bash

CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)

echo "=========================================="
echo "🔍 VERIFICANDO SERVIDOR WHATSAPP"
echo "=========================================="
echo "Contenedor: $CONTAINER"
echo ""

# Crear script temporal dentro del contenedor
docker exec "$CONTAINER" sh -c 'cat > /tmp/test-server.js << "EOF"
const http = require("http");
http.get("http://localhost:3001/api/status?card=1", (res) => {
    let data = "";
    res.on("data", (chunk) => { data += chunk; });
    res.on("end", () => {
        console.log("✅ Servidor responde - Status:", res.statusCode);
        console.log("Respuesta:", data.substring(0, 300));
    });
}).on("error", (e) => {
    console.error("❌ Error:", e.message);
});
EOF
node /tmp/test-server.js'

echo ""
echo "=========================================="
echo "📋 VERIFICANDO LOGS RECIENTES:"
echo "=========================================="
docker logs "$CONTAINER" --tail 20

echo ""
echo "=========================================="
echo "📋 VERIFICANDO PROCESOS:"
echo "=========================================="
docker exec "$CONTAINER" ps aux | grep node



