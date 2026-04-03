#!/usr/bin/env python3
"""
Script para actualizar directamente el código de WhatsApp en el servidor
"""

import re
import subprocess
import sys

print("=" * 60)
print("🔧 ACTUALIZANDO CÓDIGO DE WHATSAPP EN EL SERVIDOR")
print("=" * 60)
print()

# 1. Leer archivo
file_path = "/root/checkin24hs/deploy/dashboard.html"
print(f"📖 Leyendo archivo: {file_path}")

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
except Exception as e:
    print(f"❌ Error leyendo archivo: {e}")
    sys.exit(1)

# 2. Verificar si ya tiene los cambios
if "buildApiUrl (updateStatus) - URL recibida" in content:
    print("✅ El archivo ya tiene los cambios")
    sys.exit(0)

# 3. Buscar la función buildApiUrl dentro de updateWhatsAppStatus
print("🔍 Buscando función buildApiUrl en updateWhatsAppStatus...")

# Patrón para encontrar la función buildApiUrl dentro de updateWhatsAppStatus
pattern = r'(// Función auxiliar para construir URL según el tipo\s+const buildApiUrl = \(baseUrl, instanceNum, endpoint = \'status\'\) => \{[^}]+const instPort = 3000 \+ instanceNum;[^}]+)(// Limpiar la URL: remover puerto si existe)'

match = re.search(pattern, content, re.DOTALL)
if not match:
    print("⚠️ No se encontró el patrón exacto, intentando búsqueda más flexible...")
    # Buscar una versión más simple
    pattern = r'(const buildApiUrl = \(baseUrl, instanceNum, endpoint = \'status\'\) => \{[\s\S]{0,500}?)(\s+\}\;)'
    match = re.search(pattern, content)
    
if match:
    old_code = match.group(0)
    print(f"✅ Encontrada función buildApiUrl (longitud: {len(old_code)} caracteres)")
    
    # Crear nuevo código con logs de depuración
    new_code = '''        // Función auxiliar para construir URL según el tipo
        const buildApiUrl = (baseUrl, instanceNum, endpoint = 'status') => {
            const instPort = 3000 + instanceNum;
            
            console.log(`🔧 buildApiUrl (updateStatus) - URL recibida: ${baseUrl}, instancia: ${instanceNum}, endpoint: ${endpoint}`);
            
            // Limpiar la URL: remover puerto si existe y obtener solo el dominio/IP base
            let cleanUrl = baseUrl.replace(/:\\d+$/, ''); // Remover puerto al final
            const protocol = cleanUrl.startsWith('https') ? 'https' : 'http';
            const urlWithoutProtocol = cleanUrl.replace(/^https?:\\/\\//, '');
            
            console.log(`🔧 buildApiUrl (updateStatus) - URL limpia: ${cleanUrl}, sin protocolo: ${urlWithoutProtocol}`);
            
            // Detectar si es dominio o IP
            const isDomainUrl = /^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}/.test(urlWithoutProtocol) && 
                               !/^\\d+\\.\\d+\\.\\d+\\.\\d+/.test(urlWithoutProtocol.split(':')[0]);
            
            console.log(`🔧 buildApiUrl (updateStatus) - ¿Es dominio?: ${isDomainUrl}`);
            
            if (isDomainUrl) {
                // Estrategia 1: Subdominios
                // Extraer el dominio base (sin subdominio inicial si existe)
                const domainParts = urlWithoutProtocol.split('.');
                let baseDomain;
                
                // Si tiene al menos 2 partes (ej: checkin24hs.com), usar las últimas 2 como dominio base
                if (domainParts.length >= 2) {
                    baseDomain = domainParts.slice(-2).join('.'); // Últimas 2 partes
                } else {
                    baseDomain = urlWithoutProtocol; // Fallback
                }
                
                console.log(`🔧 buildApiUrl (updateStatus) - Dominio base extraído: ${baseDomain}`);
                
                // Construir subdominio para la instancia
                const subdomain = `api${instanceNum}`;
                const finalUrl = `${protocol}://${subdomain}.${baseDomain}/api/${endpoint}`;
                console.log(`🔗 Intentando con subdominio: ${finalUrl}`);
                return finalUrl;
            } else {
                // Para IPs, usar puerto directamente
                const finalUrl = `${cleanUrl}:${instPort}/api/${endpoint}`;
                console.log(`🔗 Intentando con IP y puerto: ${finalUrl}`);
                return finalUrl;
            }
        };'''
    
    # Reemplazar en el contenido
    content = content.replace(old_code, new_code)
    print("✅ Código reemplazado")
else:
    print("❌ No se encontró la función buildApiUrl para reemplazar")
    print("   El archivo puede tener una estructura diferente")
    sys.exit(1)

# 4. Guardar archivo
print(f"💾 Guardando archivo: {file_path}")
try:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ Archivo guardado correctamente")
except Exception as e:
    print(f"❌ Error guardando archivo: {e}")
    sys.exit(1)

# 5. Verificar que se guardó correctamente
if "buildApiUrl (updateStatus) - URL recibida" in content:
    print("✅ Verificación: Los cambios están en el archivo")
else:
    print("⚠️ Advertencia: Los cambios pueden no haberse guardado correctamente")

print()
print("=" * 60)
print("✅ ACTUALIZACIÓN COMPLETA")
print("=" * 60)
print()
print("📋 Próximos pasos:")
print("1. Actualizar el contenedor:")
print("   CONTAINER_ID=$(docker ps --filter \"name=dashboard\" --format \"{{.ID}}\" | head -1)")
print("   DASHBOARD_PATH=\"/app/dashboard.html\"")
print("   docker exec $CONTAINER_ID test -f \"$DASHBOARD_PATH\" || DASHBOARD_PATH=\"/usr/share/nginx/html/dashboard.html\"")
print("   docker cp deploy/dashboard.html \"${CONTAINER_ID}:${DASHBOARD_PATH}\"")
print("   docker restart $CONTAINER_ID")
print()
print("2. En el navegador:")
print("   - Limpia localStorage: localStorage.removeItem('whatsapp_server_url')")
print("   - Recarga con Ctrl+Shift+R")
print("   - Guarda la URL: https://api1.checkin24hs.com")



