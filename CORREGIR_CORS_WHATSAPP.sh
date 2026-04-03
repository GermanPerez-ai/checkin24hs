#!/bin/bash

echo "=========================================="
echo "🔧 CORRIGIENDO CORS EN SERVIDORES WHATSAPP"
echo "=========================================="
echo ""

# Obtener todos los contenedores de WhatsApp
CONTAINERS=$(docker ps --filter "name=whatsapp" --format "{{.Names}}")

if [ -z "$CONTAINERS" ]; then
    echo "❌ No se encontraron contenedores de WhatsApp"
    exit 1
fi

echo "📋 Contenedores encontrados:"
echo "$CONTAINERS"
echo ""

# Aplicar correcciones a cada contenedor
for CONTAINER in $CONTAINERS; do
    echo "🔧 Corrigiendo CORS en $CONTAINER..."
    
    # Crear script Node.js para aplicar correcciones
    docker exec $CONTAINER bash -c 'cat > /tmp/corregir_cors.js << '\''EOF'\''
const fs = require("fs");
const path = require("path");

const filePath = "/app/whatsapp-server.js";
console.log("📄 Leyendo archivo:", filePath);

let content = fs.readFileSync(filePath, "utf8");

// Verificar si ya tiene las correcciones
if (content.includes("// CORRECCIÓN: Asegurar headers CORS explícitamente")) {
    console.log("✅ El archivo ya tiene las correcciones de CORS");
} else {
    console.log("🔧 Aplicando correcciones de CORS...");
    
    // Reemplazar el endpoint /api/status
    const statusPattern = /app\.get\(\[.api\/status.*?res\.json\(\{[^}]+connected:[^}]+lastActivity:[^}]+\}\);/s;
    const statusReplacement = `app.get(['/api/status', '/status'], async (req, res) => {
    // CORRECCIÓN: Asegurar headers CORS explícitamente
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
    
    // Manejar solicitudes OPTIONS (preflight)
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    
    const cardNumber = req.query.card || req.query.cardNumber;
    
    let phoneNumber = '-';
    let userName = '-';
    
    if (clientReady) {
        try {
            const info = await client.info;
            if (info) {
                phoneNumber = info.wid ? info.wid.user : '-';
                userName = info.pushname || '-';
            }
        } catch (e) {
            console.log('No se pudo obtener info del cliente');
        }
    }
    
    // Respuesta compatible con el dashboard (usa 'phone' y 'name' en lugar de 'phoneNumber' y 'userName')
    res.json({
        connected: clientReady,
        whatsapp: clientReady ? 'connected' : 'disconnected',
        flor: CONFIG.FLOR_ENABLED ? 'active' : 'inactive',
        autoReply: CONFIG.AUTO_REPLY,
        qrCode: qrCodeData ? \`https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=\${encodeURIComponent(qrCodeData)}\` : null,
        phone: phoneNumber,  // Compatible con dashboard
        name: userName,      // Compatible con dashboard
        phoneNumber: phoneNumber,  // Mantener compatibilidad
        userName: userName,  // Mantener compatibilidad
        lastActivity: new Date().toLocaleString('es-AR'),
        card: cardNumber || CONFIG.INSTANCE_NUMBER
    });
});`;
    
    // Reemplazar el endpoint /api/qr
    const qrPattern = /app\.get\(\[.api\/qr.*?res\.json\(\{[^}]+\}\);/s;
    const qrReplacement = `app.get(['/api/qr', '/qr'], (req, res) => {
    // CORRECCIÓN: Asegurar headers CORS explícitamente
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
    
    // Manejar solicitudes OPTIONS (preflight)
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    
    if (clientReady) {
        res.json({ status: 'connected', qr: null });
    } else if (qrCodeData) {
        res.json({ 
            status: 'waiting_scan', 
            qr: qrCodeData,
            qrImage: \`https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=\${encodeURIComponent(qrCodeData)}\`
        });
    } else {
        res.json({ status: 'initializing', qr: null });
    }
});`;
    
    // Aplicar reemplazos usando regex más específico
    content = content.replace(
        /app\.get\(\[.api\/status.*?lastActivity: new Date\(\)\.toLocaleString\('es-AR'\)\s*\}\);/s,
        statusReplacement
    );
    
    content = content.replace(
        /app\.get\(\[.api\/qr.*?res\.json\(\{ status: 'initializing', qr: null \}\);/s,
        qrReplacement
    );
    
    fs.writeFileSync(filePath, content, "utf8");
    console.log("✅ Correcciones aplicadas");
}

console.log("✅ Proceso completado");
EOF'
    
    # Ejecutar el script Node.js
    docker exec $CONTAINER node /tmp/corregir_cors.js
    
    if [ $? -eq 0 ]; then
        echo "✅ CORS corregido en $CONTAINER"
        echo "🔄 Reiniciando contenedor..."
        docker restart $CONTAINER
        echo "✅ Contenedor $CONTAINER reiniciado"
    else
        echo "❌ Error corrigiendo CORS en $CONTAINER"
    fi
    
    echo ""
done

echo "=========================================="
echo "✅ CORRECCIÓN DE CORS COMPLETADA"
echo "=========================================="
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Espera unos segundos a que los contenedores se reinicien"
echo "2. Prueba hacer clic en los botones de WhatsApp en el dashboard"
echo "3. El error de CORS debería estar resuelto"
echo ""




