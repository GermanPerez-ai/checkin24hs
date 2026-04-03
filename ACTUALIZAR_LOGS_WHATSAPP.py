#!/usr/bin/env python3
import re

file_path = "deploy/dashboard.html"
print("📖 Leyendo archivo...")

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Verificar si ya tiene los cambios
if any("buildApiUrl (updateStatus) - URL recibida" in line for line in lines):
    print("✅ El archivo ya tiene los cambios")
else:
    print("⚠️ El archivo NO tiene los cambios")
    print("🔍 Buscando función buildApiUrl en updateWhatsAppStatus...")
    
    # Buscar la línea que define buildApiUrl
    new_lines = []
    i = 0
    found = False
    while i < len(lines):
        line = lines[i]
        
        # Si encontramos la función buildApiUrl en updateWhatsAppStatus
        if 'const buildApiUrl = (baseUrl, instanceNum, endpoint = \'status\') => {' in line and not found:
            found = True
            # Encontrar la indentación
            indent = len(line) - len(line.lstrip())
            
            # Buscar dónde está const instPort
            j = i + 1
            while j < len(lines) and 'const instPort' not in lines[j]:
                j += 1
            
            if j < len(lines):
                # Insertar los logs después de const instPort
                new_lines.append(line)  # La línea de definición de buildApiUrl
                new_lines.append(lines[i+1])  # La línea de const instPort
                
                # Insertar logs de depuración
                new_lines.append(' ' * (indent + 4) + 'console.log(`🔧 buildApiUrl (updateStatus) - URL recibida: ${baseUrl}, instancia: ${instanceNum}, endpoint: ${endpoint}`);\n')
                new_lines.append(' ' * (indent + 4) + '\n')
                new_lines.append(' ' * (indent + 4) + '// Limpiar la URL: remover puerto si existe y obtener solo el dominio/IP base\n')
                new_lines.append(' ' * (indent + 4) + 'let cleanUrl = baseUrl.replace(/:\\d+$/, \'\');\n')
                new_lines.append(' ' * (indent + 4) + 'const protocol = cleanUrl.startsWith(\'https\') ? \'https\' : \'http\';\n')
                new_lines.append(' ' * (indent + 4) + 'const urlWithoutProtocol = cleanUrl.replace(/^https?:\\/\\//, \'\');\n')
                new_lines.append(' ' * (indent + 4) + '\n')
                new_lines.append(' ' * (indent + 4) + 'console.log(`🔧 buildApiUrl (updateStatus) - URL limpia: ${cleanUrl}, sin protocolo: ${urlWithoutProtocol}`);\n')
                new_lines.append(' ' * (indent + 4) + '\n')
                new_lines.append(' ' * (indent + 4) + '// Detectar si es dominio o IP\n')
                new_lines.append(' ' * (indent + 4) + 'const isDomainUrl = /^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}/.test(urlWithoutProtocol) &&\n')
                new_lines.append(' ' * (indent + 8) + '!/^\\d+\\.\\d+\\.\\d+\\.\\d+/.test(urlWithoutProtocol.split(\':\')[0]);\n')
                new_lines.append(' ' * (indent + 4) + '\n')
                new_lines.append(' ' * (indent + 4) + 'console.log(`🔧 buildApiUrl (updateStatus) - ¿Es dominio?: ${isDomainUrl}`);\n')
                new_lines.append(' ' * (indent + 4) + '\n')
                new_lines.append(' ' * (indent + 4) + 'if (isDomainUrl) {\n')
                new_lines.append(' ' * (indent + 8) + '// Estrategia 1: Subdominios\n')
                new_lines.append(' ' * (indent + 8) + 'const domainParts = urlWithoutProtocol.split(\'.\');\n')
                new_lines.append(' ' * (indent + 8) + 'let baseDomain;\n')
                new_lines.append(' ' * (indent + 8) + 'if (domainParts.length >= 2) {\n')
                new_lines.append(' ' * (indent + 12) + 'baseDomain = domainParts.slice(-2).join(\'.\');\n')
                new_lines.append(' ' * (indent + 12) + '} else {\n')
                new_lines.append(' ' * (indent + 12) + 'baseDomain = urlWithoutProtocol;\n')
                new_lines.append(' ' * (indent + 8) + '}\n')
                new_lines.append(' ' * (indent + 8) + '\n')
                new_lines.append(' ' * (indent + 8) + 'console.log(`🔧 buildApiUrl (updateStatus) - Dominio base extraído: ${baseDomain}`);\n')
                new_lines.append(' ' * (indent + 8) + '\n')
                new_lines.append(' ' * (indent + 8) + 'const subdomain = `api${instanceNum}`;\n')
                new_lines.append(' ' * (indent + 8) + 'const finalUrl = `${protocol}://${subdomain}.${baseDomain}/api/${endpoint}`;\n')
                new_lines.append(' ' * (indent + 8) + 'console.log(`🔗 Intentando con subdominio: ${finalUrl}`);\n')
                new_lines.append(' ' * (indent + 8) + 'return finalUrl;\n')
                new_lines.append(' ' * (indent + 4) + '} else {\n')
                new_lines.append(' ' * (indent + 8) + 'const finalUrl = `${cleanUrl}:${instPort}/api/${endpoint}`;\n')
                new_lines.append(' ' * (indent + 8) + 'console.log(`🔗 Intentando con IP y puerto: ${finalUrl}`);\n')
                new_lines.append(' ' * (indent + 8) + 'return finalUrl;\n')
                new_lines.append(' ' * (indent + 4) + '}\n')
                
                # Saltar las líneas viejas hasta encontrar el cierre de la función
                i = j + 1
                # Buscar el cierre };
                while i < len(lines) and '};' not in lines[i]:
                    i += 1
                new_lines.append(lines[i])  # Agregar el };
                i += 1
                continue
        
        new_lines.append(line)
        i += 1
    
    if found:
        print("✅ Función encontrada y actualizada")
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print("✅ Archivo guardado")
    else:
        print("❌ No se encontró la función buildApiUrl para actualizar")
        print("   El archivo puede tener una estructura diferente")

print()
print("Verificando...")
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()
    if "buildApiUrl (updateStatus) - URL recibida" in content:
        print("✅ El archivo ahora tiene los cambios")
    else:
        print("❌ El archivo aún NO tiene los cambios")



