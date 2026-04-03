#!/bin/bash
# Script para crear el archivo .env en el servidor

cd /etc/easypanel/projects/checkin24hs/dashboard/code

cat > .env << 'EOF'
GEMINI_API_KEY=AIzaSyDvza5tlt0fjEgTamUKG1ZjTuqU8qjCaxI
GEMINI_MODEL=gemini-2.5-flash
EOF

echo "✅ Archivo .env creado"
cat .env
