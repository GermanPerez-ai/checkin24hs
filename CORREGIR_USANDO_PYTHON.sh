#!/bin/bash
cd /root/checkin24hs

echo "=== CORRECCIÓN USANDO PYTHON ==="
echo ""

# Encontrar contenedor
CONTAINER=$(docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    echo "❌ No se encontró contenedor"
    exit 1
fi

echo "Contenedor: $CONTAINER"
echo ""

# Paso 1: Verificar estado actual
echo "1. Verificando estado actual..."
echo "   Línea 24521:"
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""

# Paso 2: Copiar archivo correcto
if [ -f "deploy/dashboard.html" ]; then
    echo "2. Copiando archivo correcto..."
    docker cp deploy/dashboard.html "${CONTAINER}:/app/dashboard.html"
    echo "   ✅ Archivo copiado"
    sleep 2
else
    echo "❌ Archivo deploy/dashboard.html no existe"
    exit 1
fi

# Paso 3: Usar Python para corregir de manera más precisa
echo "3. Corrigiendo usando Python..."
docker exec "$CONTAINER" python3 << 'PYTHON_SCRIPT'
import re

# Leer el archivo
with open('/app/dashboard.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Contar ocurrencias antes
before_count = len(re.findall(r"select\('id, chat_id, body, created_at, from_me'\)", content))
before_count += len(re.findall(r'select\("id, chat_id, body, created_at, from_me"\)', content))

print(f"   Encontradas {before_count} instancias de 'from_me' incorrecto")

# Reemplazar select con from_me por is_from_me
content = re.sub(r"select\('id, chat_id, body, created_at, from_me'\)", "select('id, chat_id, body, created_at, is_from_me')", content)
content = re.sub(r'select\("id, chat_id, body, created_at, from_me"\)', 'select("id, chat_id, body, created_at, is_from_me")', content)
content = re.sub(r"\.select\('id, chat_id, body, created_at, from_me'\)", ".select('id, chat_id, body, created_at, is_from_me')", content)
content = re.sub(r'\.select\("id, chat_id, body, created_at, from_me"\)', '.select("id, chat_id, body, created_at, is_from_me")', content)

# Corregir variaciones múltiples
content = re.sub(r'is_is_is_from_me', 'is_from_me', content)
content = re.sub(r'is_is_from_me', 'is_from_me', content)

# Contar ocurrencias después
after_count = len(re.findall(r"select\('id, chat_id, body, created_at, from_me'\)", content))
after_count += len(re.findall(r'select\("id, chat_id, body, created_at, from_me"\)', content))

print(f"   Quedan {after_count} instancias de 'from_me' incorrecto después de la corrección")

# Escribir el archivo corregido
with open('/app/dashboard.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("   ✅ Archivo corregido usando Python")
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo "   ✅ Python ejecutado correctamente"
else
    echo "   ⚠️ Python no disponible, usando sed..."
    docker exec "$CONTAINER" sed -i "s/select('id, chat_id, body, created_at, from_me')/select('id, chat_id, body, created_at, is_from_me')/g" /app/dashboard.html
    docker exec "$CONTAINER" sed -i 's/select("id, chat_id, body, created_at, from_me")/select("id, chat_id, body, created_at, is_from_me")/g' /app/dashboard.html
fi

echo ""

# Paso 4: Verificar resultado
echo "4. Verificando resultado..."
echo "   Línea 24521:"
docker exec "$CONTAINER" sed -n '24521p' /app/dashboard.html
echo ""

# Verificar que no hay from_me incorrecto
if docker exec "$CONTAINER" grep -n "from_me" /app/dashboard.html | grep -v "is_from_me" | head -3; then
    echo "   ⚠️ AÚN HAY 'from_me' INCORRECTO"
else
    echo "   ✅ No hay 'from_me' incorrecto"
fi

echo ""

# Paso 5: Reiniciar contenedor completo
echo "5. Reiniciando contenedor completo..."
docker restart "$CONTAINER"
echo "   ✅ Contenedor reiniciado"
echo "   Esperando 20 segundos..."
sleep 20

# Verificar que está corriendo
if docker ps --filter "name=checkin24hs_dashboard" --format "{{.Names}}" | grep -q "$CONTAINER"; then
    echo "   ✅ Contenedor está corriendo"
    
    sleep 5
    if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "   ✅ Node.js está corriendo"
    else
        echo "   ⚠️ Esperando más tiempo..."
        sleep 10
        if docker exec "$CONTAINER" pgrep -f "node.*server.js" > /dev/null 2>&1; then
            echo "   ✅ Node.js está corriendo ahora"
        fi
    fi
fi

echo ""
echo "=== COMPLETADO ==="
echo ""
echo "⚠️ IMPORTANTE:"
echo "1. Cierra TODAS las pestañas del dashboard"
echo "2. Abre en modo incógnito (Ctrl+Shift+N)"
echo "3. Presiona Ctrl+Shift+R para forzar recarga"
echo "4. Verifica en la consola que la URL tenga 'is_from_me'"


