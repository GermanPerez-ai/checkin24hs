#!/bin/bash
# Script bash para verificar y subir WhatsApp a GitHub
# Ejecutar desde la carpeta raíz del proyecto

echo "🔍 Verificando archivos de WhatsApp..."

# Verificar que estamos en el directorio correcto
if [ ! -d "whatsapp-server" ]; then
    echo "❌ Error: No se encontró la carpeta whatsapp-server"
    echo "   Asegúrate de ejecutar este script desde la raíz del proyecto"
    exit 1
fi

# Verificar archivos necesarios
echo ""
echo "📋 Verificando archivos necesarios..."
archivos_necesarios=(
    "whatsapp-server/whatsapp-server.js"
    "whatsapp-server/package.json"
    "whatsapp-server/Dockerfile"
    "whatsapp-server/README.md"
)

archivos_faltantes=()

for archivo in "${archivos_necesarios[@]}"; do
    if [ -f "$archivo" ]; then
        echo "  ✅ $archivo"
    else
        echo "  ❌ $archivo (FALTA)"
        archivos_faltantes+=("$archivo")
    fi
done

if [ ${#archivos_faltantes[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Faltan algunos archivos necesarios:"
    for archivo in "${archivos_faltantes[@]}"; do
        echo "   - $archivo"
    done
    echo ""
    read -p "¿Deseas continuar de todos modos? (S/N): " continuar
    if [ "$continuar" != "S" ] && [ "$continuar" != "s" ]; then
        exit 1
    fi
fi

# Verificar estado de Git
echo ""
echo "🔍 Verificando estado de Git..."
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git no está instalado"
    exit 1
fi

git_status=$(git status --porcelain whatsapp-server/ 2>&1)

if [ -n "$git_status" ]; then
    echo "📝 Archivos modificados o sin seguimiento:"
    echo "$git_status"
    echo ""
    read -p "¿Deseas agregar estos archivos a Git? (S/N): " agregar
    if [ "$agregar" = "S" ] || [ "$agregar" = "s" ]; then
        echo ""
        echo "➕ Agregando archivos a Git..."
        git add whatsapp-server/
        echo "✅ Archivos agregados"
        
        echo ""
        read -p "💬 Ingresa un mensaje para el commit (Enter para usar el predeterminado): " mensaje
        if [ -z "$mensaje" ]; then
            mensaje="Agregar servidor WhatsApp con integración Flor IA"
        fi
        
        echo ""
        echo "📝 Creando commit..."
        git commit -m "$mensaje"
        echo "✅ Commit creado"
        
        echo ""
        read -p "🚀 ¿Deseas subir los cambios a GitHub? (S/N): " subir
        if [ "$subir" = "S" ] || [ "$subir" = "s" ]; then
            echo ""
            echo "⬆️  Subiendo a GitHub..."
            git push origin main
            if [ $? -eq 0 ]; then
                echo "✅ ¡Archivos subidos exitosamente a GitHub!"
            else
                echo "❌ Error al subir a GitHub"
                echo "   Verifica tu conexión y permisos de GitHub"
            fi
        fi
    fi
else
    echo "✅ Todos los archivos de WhatsApp ya están en Git"
    
    # Verificar si hay cambios sin commitear
    git_status_all=$(git status --porcelain 2>&1)
    if [ -n "$git_status_all" ]; then
        echo ""
        echo "⚠️  Hay otros archivos modificados:"
        echo "$git_status_all"
    else
        echo ""
        echo "✅ No hay cambios pendientes"
    fi
fi

echo ""
echo "✅ Verificación completada"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Verifica en GitHub que los archivos estén presentes"
echo "   2. En EasyPanel, configura la ruta: /whatsapp-server"
echo "   3. Despliega el servicio"

