#!/bin/bash
# Script para verificar los 3 procesos y copiar la versión correcta directamente

echo "==========================================="
echo "🔍 Verificando 3 Procesos de Actualización"
echo "==========================================="
echo ""

# Función para imprimir mensajes
print_success() {
    echo -e "\033[0;32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[0;31m❌ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠️  $1\033[0m"
}

print_info() {
    echo -e "ℹ️  $1"
}

# 1. Verificar que el código está en GitHub
echo "1️⃣ PROCESO 1: Verificando código en GitHub..."
echo ""

GITHUB_URL="https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html"

# Descargar una muestra del archivo desde GitHub
print_info "Descargando muestra desde GitHub..."
GITHUB_BUILD_TS=$(curl -s "$GITHUB_URL" 2>/dev/null | grep -oP 'window\.BUILD_TIMESTAMP\s*=\s*["\047][^"\047]*["\047]' | head -1 || echo "")
GITHUB_VERSION=$(curl -s "$GITHUB_URL" 2>/dev/null | grep -oP 'window\.DASHBOARD_VERSION\s*=\s*["\047][^"\047]*["\047]' | head -1 || echo "")

if [ -n "$GITHUB_BUILD_TS" ]; then
    print_success "Código en GitHub tiene BUILD_TIMESTAMP:"
    echo "   $GITHUB_BUILD_TS" | sed 's/^/      /'
else
    print_error "No se encontró BUILD_TIMESTAMP en GitHub"
    echo "   URL probada: $GITHUB_URL"
fi

if [ -n "$GITHUB_VERSION" ]; then
    print_success "Código en GitHub tiene DASHBOARD_VERSION:"
    echo "   $GITHUB_VERSION" | sed 's/^/      /'
else
    print_error "No se encontró DASHBOARD_VERSION en GitHub"
fi

echo ""

# 2. Verificar qué tiene EasyPanel/el contenedor
echo "2️⃣ PROCESO 2: Verificando qué tiene el contenedor..."
echo ""

CONTAINER_ID=$(docker ps --filter "name=dashboard" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    print_error "No se encontró contenedor del dashboard"
    exit 1
fi

print_info "Contenedor: $CONTAINER_ID"

CONTAINER_BUILD_TS=$(docker exec "$CONTAINER_ID" grep -oP 'window\.BUILD_TIMESTAMP\s*=\s*["\047][^"\047]*["\047]' /app/dashboard.html 2>/dev/null | head -1 || echo "")
CONTAINER_VERSION=$(docker exec "$CONTAINER_ID" grep -oP 'window\.DASHBOARD_VERSION\s*=\s*["\047][^"\047]*["\047]' /app/dashboard.html 2>/dev/null | head -1 || echo "")

if [ -n "$CONTAINER_BUILD_TS" ]; then
    print_success "Contenedor tiene BUILD_TIMESTAMP:"
    echo "   $CONTAINER_BUILD_TS" | sed 's/^/      /'
else
    print_error "Contenedor NO tiene BUILD_TIMESTAMP (versión antigua)"
fi

if [ -n "$CONTAINER_VERSION" ]; then
    print_success "Contenedor tiene DASHBOARD_VERSION:"
    echo "   $CONTAINER_VERSION" | sed 's/^/      /'
else
    print_error "Contenedor NO tiene DASHBOARD_VERSION (versión antigua)"
fi

echo ""

# 3. Comparar versiones
echo "3️⃣ PROCESO 3: Comparando versiones..."
echo ""

if [ -z "$CONTAINER_BUILD_TS" ] && [ -n "$GITHUB_BUILD_TS" ]; then
    print_warning "⚠️  DESFASE DETECTADO:"
    print_warning "   GitHub tiene la versión nueva"
    print_warning "   El contenedor tiene versión antigua"
    print_warning ""
    print_info "EasyPanel NO está descargando la versión nueva desde GitHub"
    echo ""
    
    # Preguntar si quiere copiar directamente
    echo "==========================================="
    echo "🔄 SOLUCIÓN: Copiar versión directamente"
    echo "==========================================="
    echo ""
    print_info "¿Quieres copiar la versión nueva directamente al contenedor?"
    print_warning "NOTA: Esto es una solución temporal. Los cambios se perderán"
    print_warning "cuando EasyPanel haga un nuevo deploy."
    echo ""
    read -p "¿Continuar? (s/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo ""
        print_info "Descargando dashboard.html desde GitHub..."
        
        # Crear directorio temporal
        TEMP_DIR=$(mktemp -d)
        TEMP_FILE="$TEMP_DIR/dashboard.html"
        
        # Descargar desde GitHub
        if curl -s -o "$TEMP_FILE" "$GITHUB_URL"; then
            print_success "Archivo descargado correctamente"
            
            # Verificar tamaño
            FILE_SIZE=$(stat -c%s "$TEMP_FILE" 2>/dev/null || stat -f%z "$TEMP_FILE" 2>/dev/null || echo "unknown")
            print_info "Tamaño del archivo: $FILE_SIZE bytes"
            
            # Copiar al contenedor
            echo ""
            print_info "Copiando al contenedor..."
            if docker cp "$TEMP_FILE" "$CONTAINER_ID:/app/dashboard.html"; then
                print_success "Archivo copiado correctamente"
                
                # Verificar que se copió
                echo ""
                print_info "Verificando que se copió correctamente..."
                NEW_BUILD_TS=$(docker exec "$CONTAINER_ID" grep -oP 'window\.BUILD_TIMESTAMP\s*=\s*["\047][^"\047]*["\047]' /app/dashboard.html 2>/dev/null | head -1 || echo "")
                
                if [ -n "$NEW_BUILD_TS" ]; then
                    print_success "✅ BUILD_TIMESTAMP ahora presente:"
                    echo "   $NEW_BUILD_TS" | sed 's/^/      /'
                    echo ""
                    print_success "✅ La versión nueva está ahora en el contenedor"
                    echo ""
                    print_warning "⚠️  RECORDATORIO:"
                    print_warning "   Esta es una solución temporal."
                    print_warning "   Los cambios se perderán cuando EasyPanel haga deploy."
                    print_warning "   Para solución permanente, configura EasyPanel para usar GitHub."
                else
                    print_error "No se encontró BUILD_TIMESTAMP después de copiar"
                fi
                
                # Limpiar
                rm -rf "$TEMP_DIR"
            else
                print_error "Error al copiar el archivo al contenedor"
                rm -rf "$TEMP_DIR"
                exit 1
            fi
        else
            print_error "Error al descargar el archivo desde GitHub"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        echo ""
        print_info "Operación cancelada"
        echo ""
        print_info "Para solución permanente:"
        print_info "   1. Ve a EasyPanel"
        print_info "   2. Verifica que el servicio esté configurado para usar GitHub"
        print_info "   3. Haz un nuevo Deploy"
    fi
else
    if [ -n "$CONTAINER_BUILD_TS" ] && [ -n "$GITHUB_BUILD_TS" ]; then
        if [ "$CONTAINER_BUILD_TS" = "$GITHUB_BUILD_TS" ]; then
            print_success "✅ Las versiones coinciden"
        else
            print_warning "⚠️  Las versiones son diferentes"
            echo "   GitHub: $GITHUB_BUILD_TS"
            echo "   Contenedor: $CONTAINER_BUILD_TS"
        fi
    fi
fi

echo ""
echo "==========================================="
echo "📋 Resumen"
echo "==========================================="
echo ""
echo "PROCESO 1 (GitHub):"
if [ -n "$GITHUB_BUILD_TS" ]; then
    echo "   ✅ Código actualizado en GitHub"
else
    echo "   ❌ Código NO encontrado en GitHub"
fi
echo ""
echo "PROCESO 2 (EasyPanel/Contenedor):"
if [ -n "$CONTAINER_BUILD_TS" ]; then
    echo "   ✅ Contenedor tiene versión con BUILD_TIMESTAMP"
else
    echo "   ❌ Contenedor tiene versión antigua"
fi
echo ""
echo "PROCESO 3 (Servidor):"
echo "   ℹ️  El servidor lee desde /app/dashboard.html en el contenedor"
echo ""
