#!/bin/bash
# Copia y pega este comando completo en el servidor

cd /root/checkin24hs && python3 << 'PYEOF'
import subprocess
import os
import sys
import datetime
import time

def main():
    print("=" * 50)
    print("ACTUALIZANDO DASHBOARD EN EL SERVIDOR")
    print("=" * 50)
    print("")
    
    # 1. Verificar archivo local
    print("1. Verificando archivo local...")
    local_file = "deploy/dashboard.html"
    
    if not os.path.exists(local_file):
        print(f"ERROR: No se encontro: {local_file}")
        print("   Asegurate de estar en /root/checkin24hs")
        sys.exit(1)
    
    with open(local_file, 'r', encoding='utf-8') as f:
        content = f.read()
        if 'Cargando hoteles para selector (knowledge/policies)' in content:
            print("OK: Archivo local tiene los cambios")
        else:
            print("ERROR: Archivo local NO tiene los cambios")
            print("   Necesitas subir el archivo desde tu maquina Windows")
            sys.exit(1)
    
    # 2. Buscar contenedor
    print("")
    print("2. Buscando contenedor del dashboard...")
    result = subprocess.run(
        ['docker', 'ps', '--filter', 'name=dashboard', '--format', '{{.ID}}'],
        capture_output=True, text=True
    )
    
    container_id = result.stdout.strip().split('\n')[0] if result.stdout.strip() else None
    
    if not container_id:
        print("ERROR: No se encontro contenedor del dashboard")
        print("   Buscando todos los contenedores...")
        result = subprocess.run(['docker', 'ps'], capture_output=True, text=True)
        print(result.stdout)
        sys.exit(1)
    
    print(f"OK: Contenedor encontrado: {container_id}")
    
    # 3. Buscar ruta del dashboard
    print("")
    print("3. Buscando ruta del dashboard en el contenedor...")
    paths = ['/app/dashboard.html', '/usr/share/nginx/html/dashboard.html', '/var/www/html/dashboard.html']
    
    dashboard_path = None
    for path in paths:
        result = subprocess.run(
            ['docker', 'exec', container_id, 'test', '-f', path],
            capture_output=True
        )
        if result.returncode == 0:
            dashboard_path = path
            print(f"OK: Encontrado en: {path}")
            break
    
    if not dashboard_path:
        print("ADVERTENCIA: No se encontro, usando /app/dashboard.html")
        dashboard_path = "/app/dashboard.html"
    
    # 4. Verificar versión actual
    print("")
    print("4. Verificando version en el contenedor...")
    result = subprocess.run(
        ['docker', 'exec', container_id, 'grep', '-q', 
         'Cargando hoteles para selector (knowledge/policies)', dashboard_path],
        capture_output=True
    )
    
    needs_update = result.returncode != 0
    
    if not needs_update:
        print("OK: Contenedor tiene la version actualizada")
    else:
        print("ERROR: Contenedor NO tiene la version actualizada")
    
    # 5. Actualizar si es necesario
    if needs_update:
        print("")
        print("5. Actualizando archivo en el contenedor...")
        
        # Crear backup
        backup_path = f"{dashboard_path}.backup.{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
        subprocess.run(['docker', 'exec', container_id, 'cp', dashboard_path, backup_path], 
                      capture_output=True)
        print(f"OK: Backup creado: {backup_path}")
        
        # Copiar archivo
        print("Copiando archivo al contenedor...")
        result = subprocess.run(
            ['docker', 'cp', local_file, f"{container_id}:{dashboard_path}"],
            capture_output=True, text=True
        )
        
        if result.returncode == 0:
            print("OK: Archivo copiado correctamente")
            
            # Verificar
            result = subprocess.run(
                ['docker', 'exec', container_id, 'grep', '-q',
                 'Cargando hoteles para selector (knowledge/policies)', dashboard_path],
                capture_output=True
            )
            
            if result.returncode == 0:
                print("OK: Verificacion: Archivo actualizado correctamente")
                
                # Reiniciar contenedor
                print("")
                print("6. Reiniciando contenedor...")
                subprocess.run(['docker', 'restart', container_id], capture_output=True)
                
                time.sleep(5)
                
                # Verificar que está corriendo
                result = subprocess.run(
                    ['docker', 'ps', '--filter', f'id={container_id}', '--format', '{{.ID}}'],
                    capture_output=True, text=True
                )
                
                if result.stdout.strip():
                    print("OK: Contenedor reiniciado y corriendo")
                else:
                    print("ADVERTENCIA: El contenedor no esta corriendo")
            else:
                print("ERROR: El archivo no se actualizo correctamente")
                sys.exit(1)
        else:
            print(f"ERROR: Error al copiar archivo: {result.stderr}")
            sys.exit(1)
    else:
        print("")
        print("OK: No se necesita actualizar, el contenedor ya tiene la version correcta")
    
    print("")
    print("=" * 50)
    print("ACTUALIZACION COMPLETA")
    print("=" * 50)
    print("")
    print("Proximos pasos:")
    print("   1. Limpia la cache del navegador (Ctrl+Shift+R o Ctrl+F5)")
    print("   2. Recarga la pagina del dashboard")
    print("   3. Ve a Flor IA -> Pestana 'Conocimiento'")
    print("   4. Selecciona un hotel del selector")
    print("   5. Deberias ver toda la informacion del hotel")
    print("=" * 50)

if __name__ == "__main__":
    main()
PYEOF
