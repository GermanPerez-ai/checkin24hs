#!/usr/bin/env python3
"""
Script para actualizar dashboard.html en el contenedor Docker
Ejecutar en el servidor después de subir el archivo deploy/dashboard.html
"""

import subprocess
import os
import sys

def main():
    print("=" * 50)
    print("🔍 ACTUALIZANDO DASHBOARD EN EL SERVIDOR")
    print("=" * 50)
    print("")
    
    # 1. Verificar archivo local
    print("1️⃣ Verificando archivo local...")
    local_file = "deploy/dashboard.html"
    
    if not os.path.exists(local_file):
        print(f"❌ No se encontró: {local_file}")
        print("   Asegúrate de estar en /root/checkin24hs")
        sys.exit(1)
    
    with open(local_file, 'r', encoding='utf-8') as f:
        content = f.read()
        if 'Cargando hoteles para selector (knowledge/policies)' in content:
            print("✅ Archivo local tiene los cambios")
        else:
            print("❌ Archivo local NO tiene los cambios")
            print("   Necesitas subir el archivo desde tu máquina Windows")
            sys.exit(1)
    
    # 2. Buscar contenedor
    print("")
    print("2️⃣ Buscando contenedor del dashboard...")
    result = subprocess.run(
        ['docker', 'ps', '--filter', 'name=dashboard', '--format', '{{.ID}}'],
        capture_output=True, text=True
    )
    
    container_id = result.stdout.strip().split('\n')[0] if result.stdout.strip() else None
    
    if not container_id:
        print("❌ No se encontró contenedor del dashboard")
        print("   Buscando todos los contenedores...")
        result = subprocess.run(['docker', 'ps'], capture_output=True, text=True)
        print(result.stdout)
        sys.exit(1)
    
    print(f"✅ Contenedor encontrado: {container_id}")
    
    # 3. Buscar ruta del dashboard
    print("")
    print("3️⃣ Buscando ruta del dashboard en el contenedor...")
    paths = ['/app/dashboard.html', '/usr/share/nginx/html/dashboard.html', '/var/www/html/dashboard.html']
    
    dashboard_path = None
    for path in paths:
        result = subprocess.run(
            ['docker', 'exec', container_id, 'test', '-f', path],
            capture_output=True
        )
        if result.returncode == 0:
            dashboard_path = path
            print(f"✅ Encontrado en: {path}")
            break
    
    if not dashboard_path:
        print("⚠️ No se encontró, usando /app/dashboard.html")
        dashboard_path = "/app/dashboard.html"
    
    # 4. Verificar versión actual
    print("")
    print("4️⃣ Verificando versión en el contenedor...")
    result = subprocess.run(
        ['docker', 'exec', container_id, 'grep', '-q', 
         'Cargando hoteles para selector (knowledge/policies)', dashboard_path],
        capture_output=True
    )
    
    needs_update = result.returncode != 0
    
    if not needs_update:
        print("✅ Contenedor tiene la versión actualizada")
    else:
        print("❌ Contenedor NO tiene la versión actualizada")
    
    # 5. Actualizar si es necesario
    if needs_update:
        print("")
        print("5️⃣ Actualizando archivo en el contenedor...")
        
        # Crear backup
        import datetime
        backup_path = f"{dashboard_path}.backup.{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
        subprocess.run(['docker', 'exec', container_id, 'cp', dashboard_path, backup_path], 
                      capture_output=True)
        print(f"✅ Backup creado: {backup_path}")
        
        # Copiar archivo
        print("📤 Copiando archivo al contenedor...")
        result = subprocess.run(
            ['docker', 'cp', local_file, f"{container_id}:{dashboard_path}"],
            capture_output=True, text=True
        )
        
        if result.returncode == 0:
            print("✅ Archivo copiado correctamente")
            
            # Verificar
            result = subprocess.run(
                ['docker', 'exec', container_id, 'grep', '-q',
                 'Cargando hoteles para selector (knowledge/policies)', dashboard_path],
                capture_output=True
            )
            
            if result.returncode == 0:
                print("✅ Verificación: Archivo actualizado correctamente")
                
                # Reiniciar contenedor
                print("")
                print("6️⃣ Reiniciando contenedor...")
                subprocess.run(['docker', 'restart', container_id], capture_output=True)
                
                import time
                time.sleep(5)
                
                # Verificar que está corriendo
                result = subprocess.run(
                    ['docker', 'ps', '--filter', f'id={container_id}', '--format', '{{.ID}}'],
                    capture_output=True, text=True
                )
                
                if result.stdout.strip():
                    print("✅ Contenedor reiniciado y corriendo")
                else:
                    print("⚠️ El contenedor no está corriendo")
            else:
                print("❌ Error: El archivo no se actualizó correctamente")
                sys.exit(1)
        else:
            print(f"❌ Error al copiar archivo: {result.stderr}")
            sys.exit(1)
    else:
        print("")
        print("✅ No se necesita actualizar, el contenedor ya tiene la versión correcta")
    
    print("")
    print("=" * 50)
    print("✅ ACTUALIZACIÓN COMPLETA")
    print("=" * 50)
    print("")
    print("📋 Próximos pasos:")
    print("   1. Limpia la caché del navegador (Ctrl+Shift+R o Ctrl+F5)")
    print("   2. Recarga la página del dashboard")
    print("   3. Ve a Flor IA → Pestaña '📚 Conocimiento'")
    print("   4. Selecciona un hotel del selector")
    print("   5. Deberías ver toda la información del hotel")
    print("")
    print("🔍 Para verificar en la consola del navegador (F12):")
    print("   - Deberías ver: '🔄 Cargando hoteles para selector...'")
    print("   - Deberías ver: '🏨 Cargando hoteles para selector de Flor...'")
    print("   - Deberías ver: '✅ X hoteles cargados desde Supabase para selector'")
    print("   - Al seleccionar hotel: '🔍 loadSelectedHotelKnowledge ejecutándose...'")
    print("=" * 50)

if __name__ == "__main__":
    main()



