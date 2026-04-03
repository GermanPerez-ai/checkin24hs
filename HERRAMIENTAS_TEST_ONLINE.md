# Herramientas para Probar el Dashboard en Línea

## 🔍 Verificación Básica desde el Servidor

Ejecuta el script de verificación:

```bash
cd /root/checkin24hs
chmod +x VERIFICAR_DASHBOARD_ONLINE.sh
bash VERIFICAR_DASHBOARD_ONLINE.sh
```

## 🌐 Herramientas Online Gratuitas

### 1. **Verificar si el sitio está en línea**
- **Down For Everyone Or Just Me**: https://downforeveryoneorjustme.com/dashboard.checkin24hs.com
- **Is It Down Right Now**: https://www.isitdownrightnow.com/dashboard.checkin24hs.com.html

### 2. **Verificar velocidad y rendimiento**
- **PageSpeed Insights** (Google): https://pagespeed.web.dev/
  - Ingresa: `https://dashboard.checkin24hs.com`
  - Muestra velocidad en móvil y desktop
  
- **GTmetrix**: https://gtmetrix.com/
  - Ingresa la URL y obtén análisis de rendimiento

### 3. **Verificar SSL/Certificado**
- **SSL Labs SSL Test**: https://www.ssllabs.com/ssltest/
  - Ingresa: `dashboard.checkin24hs.com`
  - Muestra calificación del certificado SSL

- **SSL Checker**: https://www.sslshopper.com/ssl-checker.html
  - Verifica certificados SSL

### 4. **Verificar desde diferentes ubicaciones**
- **Uptrends**: https://www.uptrends.com/tools/uptime
  - Prueba desde múltiples ubicaciones geográficas

- **Site24x7**: https://www.site24x7.com/tools/website-monitoring.html
  - Monitoreo desde diferentes países

### 5. **Verificar headers HTTP**
- **Security Headers**: https://securityheaders.com/
  - Analiza headers de seguridad y caché

- **Header Checker**: https://www.webconfs.com/http-header-check.php
  - Muestra todos los headers HTTP

### 6. **Verificar desde móvil**
- **Responsive Design Checker**: https://responsivedesignchecker.com/
  - Prueba cómo se ve en diferentes dispositivos móviles

- **BrowserStack**: https://www.browserstack.com/responsive
  - Prueba en dispositivos reales (versión gratuita limitada)

## 📱 Pruebas Manuales Recomendadas

### Desde tu teléfono:
1. **Conecta a una red diferente** (WiFi de otra casa, datos móviles)
2. **Abre el navegador** y ve a: `https://dashboard.checkin24hs.com`
3. **Verifica que carga** correctamente
4. **Intenta iniciar sesión** y usar las funciones principales

### Desde otro ordenador:
1. **Abre el navegador** en otro ordenador
2. **Ve a**: `https://dashboard.checkin24hs.com`
3. **Abre las herramientas de desarrollador** (F12)
4. **Ve a la pestaña "Network" o "Red"**
5. **Recarga la página** (Ctrl+Shift+R o Cmd+Shift+R)
6. **Verifica los headers** de respuesta:
   - Debe tener: `Cache-Control: no-cache, no-store, must-revalidate`
   - Debe tener: `Pragma: no-cache`
   - Debe tener: `Expires: 0`

## 🔧 Comandos para Probar desde Línea de Comando

### Desde cualquier servidor Linux/Mac:

```bash
# Verificar que responde
curl -I https://dashboard.checkin24hs.com

# Ver headers completos
curl -v https://dashboard.checkin24hs.com 2>&1 | grep -i "cache\|pragma\|expires"

# Verificar contenido HTML
curl -s https://dashboard.checkin24hs.com | grep -i "checkin24hs\|panel"

# Verificar SSL
openssl s_client -servername dashboard.checkin24hs.com -connect dashboard.checkin24hs.com:443 </dev/null 2>/dev/null | openssl x509 -noout -subject -dates
```

### Desde PowerShell (Windows):

```powershell
# Verificar que responde
Invoke-WebRequest -Uri "https://dashboard.checkin24hs.com" -Method Head

# Ver headers
$response = Invoke-WebRequest -Uri "https://dashboard.checkin24hs.com"
$response.Headers

# Verificar contenido
$response.Content | Select-String -Pattern "Checkin24hs"
```

## ✅ Checklist de Verificación

- [ ] Dashboard carga correctamente desde el servidor
- [ ] Dashboard carga desde otro ordenador en la misma red
- [ ] Dashboard carga desde otro ordenador en red diferente
- [ ] Dashboard carga desde teléfono móvil (WiFi)
- [ ] Dashboard carga desde teléfono móvil (datos móviles)
- [ ] Headers anti-caché están presentes
- [ ] Certificado SSL es válido
- [ ] Tiempo de carga es razonable (< 3 segundos)
- [ ] Funcionalidades principales funcionan (login, navegación)

## 🐛 Si hay Problemas

### El dashboard no carga desde otros ordenadores:

1. **Verifica el firewall**:
   ```bash
   # En el servidor
   ufw status
   iptables -L -n | grep 443
   ```

2. **Verifica que Traefik está escuchando**:
   ```bash
   docker ps | grep traefik
   docker logs traefik --tail 50
   ```

3. **Verifica DNS**:
   ```bash
   # Desde otro ordenador
   nslookup dashboard.checkin24hs.com
   dig dashboard.checkin24hs.com
   ```

4. **Verifica certificado SSL**:
   ```bash
   openssl s_client -servername dashboard.checkin24hs.com -connect dashboard.checkin24hs.com:443 </dev/null
   ```






