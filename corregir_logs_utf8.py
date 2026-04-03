#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para corregir problemas de codificación UTF-8 en console.log del dashboard.html
"""

import re
import sys
from datetime import datetime

DASHBOARD_PATH = "deploy/dashboard.html"
BACKUP_FILE = f"deploy/dashboard.html.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

# Diccionario de correcciones UTF-8
CORRECCIONES = {
    # Problemas de codificación UTF-8 comunes
    r'est\?': 'está',
    r'funci\?n': 'función',
    r'vac\?o': 'vacío',
    r'DIAGN\?STICO': 'DIAGNÓSTICO',
    r'AUTOM\?TICO': 'AUTOMÁTICO',
    r'\?ltimas': 'últimas',
    r'estad\?sticas': 'estadísticas',
    r'D\?a': 'Día',
    r'\?Coincide': '¿Coincide',
    r'c\?digo': 'código',
    r'nuevo est\?': 'nuevo está',
    r'es funci\?n': 'es función',
    r'mensaje vac\?o': 'mensaje vacío',
    r'Promedio/D\?a': 'Promedio/Día',
    r'configuraci\?n': 'configuración',
    r'verificaci\?n': 'verificación',
    r'autenticaci\?n': 'autenticación',
    r'reservaci\?n': 'reservación',
    r'actualizaci\?n': 'actualización',
    r'eliminaci\?n': 'eliminación',
    r'creaci\?n': 'creación',
    r'edici\?n': 'edición',
    r'selecci\?n': 'selección',
    r'aplicaci\?n': 'aplicación',
    r'operaci\?n': 'operación',
    r'instalaci\?n': 'instalación',
    r'configuraci\?n': 'configuración',
    r'presentaci\?n': 'presentación',
    r'preparaci\?n': 'preparación',
    r'confirmaci\?n': 'confirmación',
    r'cancelaci\?n': 'cancelación',
    r'validaci\?n': 'validación',
    r'generaci\?n': 'generación',
    r'ejecuci\?n': 'ejecución',
    r'construcci\?n': 'construcción',
    r'destrucci\?n': 'destrucción',
    r'producci\?n': 'producción',
    r'reducci\?n': 'reducción',
    r'introducci\?n': 'introducción',
    r'instrucci\?n': 'instrucción',
    r'construcci\?n': 'construcción',
    r'destrucci\?n': 'destrucción',
    r'producci\?n': 'producción',
    r'reducci\?n': 'reducción',
    r'introducci\?n': 'introducción',
    r'instrucci\?n': 'instrucción',
}

def corregir_console_logs(content):
    """
    Corrige problemas de codificación UTF-8 solo dentro de console.log/warn/error
    """
    lineas = content.split('\n')
    lineas_corregidas = []
    
    for linea in lineas:
        # Si la línea contiene console.log/warn/error, aplicar correcciones
        if re.search(r'console\.(log|warn|error)', linea):
            linea_corregida = linea
            # Aplicar todas las correcciones
            for patron, reemplazo in CORRECCIONES.items():
                linea_corregida = re.sub(patron, reemplazo, linea_corregida, flags=re.IGNORECASE)
            lineas_corregidas.append(linea_corregida)
        else:
            lineas_corregidas.append(linea)
    
    return '\n'.join(lineas_corregidas)

def main():
    print("=== Crear backup ===")
    try:
        with open(DASHBOARD_PATH, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
        
        # Crear backup
        with open(BACKUP_FILE, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Backup: {BACKUP_FILE}")
    except Exception as e:
        print(f"❌ Error al crear backup: {e}")
        sys.exit(1)
    
    print("")
    print("=== Corregir codificación UTF-8 en console.log ===")
    
    # Corregir console.log
    content_corregido = corregir_console_logs(content)
    
    # Guardar el archivo corregido
    try:
        with open(DASHBOARD_PATH, 'w', encoding='utf-8') as f:
            f.write(content_corregido)
        print("✅ Correcciones aplicadas")
    except Exception as e:
        print(f"❌ Error al guardar archivo: {e}")
        sys.exit(1)
    
    print("")
    print("PROXIMOS PASOS:")
    print("1. Revisa el archivo para verificar las correcciones")
    print("2. Ejecuta ACTUALIZAR_VERSION_Y_SUBIR.ps1 para subir los cambios")
    print("")

if __name__ == "__main__":
    main()
