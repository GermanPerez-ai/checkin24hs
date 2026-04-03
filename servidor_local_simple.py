#!/usr/bin/env python3
"""
Servidor HTTP simple para abrir el verificador sin problemas de CORS
Uso: python servidor_local_simple.py
Luego abre: http://localhost:8000/verificar_servidores_whatsapp.html
"""

import http.server
import socketserver
import os
import webbrowser
from pathlib import Path

PORT = 8000

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Agregar headers CORS para permitir peticiones
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def do_OPTIONS(self):
        # Manejar preflight requests
        self.send_response(200)
        self.end_headers()

def main():
    # Cambiar al directorio del script
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    Handler = MyHTTPRequestHandler
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        url = f"http://localhost:{PORT}/verificar_servidores_whatsapp.html"
        print("=" * 60)
        print("🚀 Servidor HTTP local iniciado")
        print("=" * 60)
        print(f"📍 Puerto: {PORT}")
        print(f"🌐 Abre en tu navegador:")
        print(f"   {url}")
        print("=" * 60)
        print("\n⏹️  Presiona Ctrl+C para detener el servidor\n")
        
        # Intentar abrir automáticamente en el navegador
        try:
            webbrowser.open(url)
            print("✅ Navegador abierto automáticamente\n")
        except:
            print("⚠️  No se pudo abrir el navegador automáticamente\n")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n⏹️  Servidor detenido")

if __name__ == "__main__":
    main()
