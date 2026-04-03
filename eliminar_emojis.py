#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Script para eliminar emojis de console.log en dashboard.html"""

import re
import sys

def eliminar_emojis_console_log(archivo):
    """Elimina emojis de todas las llamadas a console.log, console.error, etc."""
    
    # Leer el archivo
    with open(archivo, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Lista de emojis a eliminar
    emojis = ['🎫', '🤖', '✅', '💾', '🔄', '📊', '☁️', '⚠️', '❌', '🔐', '📁']
    
    # Eliminar cada emoji del contenido
    for emoji in emojis:
        # Buscar console.log/error/warn/info que contengan el emoji
        # Patrón: console.XXX('...emoji...') o console.XXX("...emoji...") o console.XXX(`...emoji...`)
        patterns = [
            # Comillas simples
            (rf"console\.(log|error|warn|info)\('([^']*){re.escape(emoji)}([^']*)'\)", 
             r"console.\1('\2\3')"),
            # Comillas dobles
            (rf'console\.(log|error|warn|info)\("([^"]*){re.escape(emoji)}([^"]*)"\)', 
             r'console.\1("\2\3")'),
            # Template literals (backticks)
            (rf'console\.(log|error|warn|info)\(`([^`]*){re.escape(emoji)}([^`]*)`\)', 
             r'console.\1(`\2\3`)'),
        ]
        
        for pattern, replacement in patterns:
            content = re.sub(pattern, replacement, content)
    
    # También eliminar emojis sueltos en cualquier console.XXX
    # Esto captura casos donde el emoji está en medio de una expresión más compleja
    for emoji in emojis:
        # Buscar console.XXX(...) y eliminar el emoji de todo el contenido entre paréntesis
        def eliminar_emoji_del_match(match):
            texto_completo = match.group(0)
            return texto_completo.replace(emoji, '')
        
        content = re.sub(r'console\.(log|error|warn|info)\([^)]*\)', eliminar_emoji_del_match, content)
    
    # Guardar el archivo
    with open(archivo, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Emojis eliminados de console.log en {archivo}")

if __name__ == '__main__':
    archivo = 'dashboard.html'
    eliminar_emojis_console_log(archivo)


