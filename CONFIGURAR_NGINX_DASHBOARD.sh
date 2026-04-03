#!/bin/bash
# Configurar Nginx para dashboard.checkin24hs.com

echo "=== 1. Crear configuración de Nginx ==="
sudo tee /etc/nginx/sites-available/dashboard.checkin24hs.com > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name dashboard.checkin24hs.com;
    
    # Logs
    access_log /var/log/nginx/dashboard-access.log;
    error_log /var/log/nginx/dashboard-error.log;
    
    # Proxy al servicio del dashboard en puerto 3000
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

echo "✅ Configuración creada"

echo ""
echo "=== 2. Crear enlace simbólico ==="
sudo ln -sf /etc/nginx/sites-available/dashboard.checkin24hs.com /etc/nginx/sites-enabled/dashboard.checkin24hs.com

echo "✅ Enlace creado"

echo ""
echo "=== 3. Verificar sintaxis ==="
sudo nginx -t

echo ""
echo "=== 4. Iniciar Nginx ==="
sudo systemctl start nginx
sudo systemctl enable nginx

echo ""
echo "=== 5. Verificar estado ==="
sudo systemctl status nginx --no-pager | head -10

echo ""
echo "=== 6. Verificar que esté escuchando ==="
sudo netstat -tulpn | grep ":80" || sudo ss -tulpn | grep ":80"

echo ""
echo "✅ Configuración completada!"
echo "El dashboard debería estar accesible en: https://dashboard.checkin24hs.com"

