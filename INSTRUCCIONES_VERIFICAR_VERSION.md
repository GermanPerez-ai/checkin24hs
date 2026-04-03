# Instrucciones para Verificar Versión y Display

## Problema
- El versionado no aparece en la web
- Necesitamos verificar si el último redeploy actualizó a la versión más reciente (Build #5)

## Pasos para Verificar

### 1. Conectarse por SSH al servidor
```bash
ssh root@tu-servidor
cd ~/checkin24hs
```

### 2. Ejecutar el script de verificación
```bash
cat > VERIFICAR_VERSION_COMPLETA.sh << 'EOF'
#!/bin/bash
SERVICE_NAME="checkin24hs_dashboard"
DOMAIN="dashboard.checkin24hs.com"

echo "=========================================="
echo "VERIFICAR VERSION COMPLETA"
echo "=========================================="
echo ""

echo "=== 1. Buscar contenedor activo ==="
CONTAINER=$(docker ps --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" --format "{{.Names}}" | head -1)
if [ -z "$CONTAINER" ]; then
    CONTAINER=$(docker ps | grep dashboard | awk '{print $NF}' | head -1)
fi
if [ -z "$CONTAINER" ]; then
    echo "ERROR: No se encontro contenedor"
    exit 1
fi
echo "OK: Contenedor: $CONTAINER"
echo ""

echo "=== 2. Version en contenedor ==="
docker exec "$CONTAINER" grep -E "DASHBOARD_VERSION|DASHBOARD_BUILD_NUMBER|DASHBOARD_BUILD" /app/dashboard.html | head -3
echo ""

echo "=== 3. Display de version en HTML ==="
if docker exec "$CONTAINER" grep -q "version-display" /app/dashboard.html; then
    echo "OK: Display encontrado"
    docker exec "$CONTAINER" grep -A 3 "version-display" /app/dashboard.html | head -4
else
    echo "ERROR: Display NO encontrado"
fi
echo ""

echo "=== 4. JavaScript que actualiza version ==="
if docker exec "$CONTAINER" grep -q "version-number" /app/dashboard.html; then
    echo "OK: JavaScript encontrado"
    docker exec "$CONTAINER" grep -B 2 -A 5 "version-numberEl" /app/dashboard.html | head -8
else
    echo "ERROR: JavaScript NO encontrado"
fi
echo ""

echo "=== 5. Version desde HTTP ==="
HTTP_VERSION=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
HTTP_BUILD=$(curl -s "http://$DOMAIN" 2>/dev/null | grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" | grep -oP "\d+" | head -1 || echo "No encontrada")
echo "Version HTTP: $HTTP_VERSION"
echo "Build HTTP: #$HTTP_BUILD"
echo ""

echo "=== 6. Comparar versiones ==="
CONTAINER_VERSION=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_VERSION\s*=\s*'[^']+'" /app/dashboard.html 2>/dev/null | grep -oP "'[^']+'" | tr -d "'" | head -1 || echo "No encontrada")
CONTAINER_BUILD=$(docker exec "$CONTAINER" grep -oP "window\.DASHBOARD_BUILD_NUMBER\s*=\s*\d+" /app/dashboard.html 2>/dev/null | grep -oP "\d+" | head -1 || echo "No encontrada")
echo "Version contenedor: $CONTAINER_VERSION"
echo "Build contenedor: #$CONTAINER_BUILD"
echo "Version HTTP: $HTTP_VERSION"
echo "Build HTTP: #$HTTP_BUILD"
if [ "$CONTAINER_BUILD" = "5" ]; then
    echo "OK: Version actualizada (Build #5)"
else
    echo "ADVERTENCIA: Version no es la mas reciente (esperado: #5, encontrado: #$CONTAINER_BUILD)"
fi
echo ""

echo "=========================================="
echo "OK: Verificacion completada"
echo "=========================================="
EOF
chmod +x VERIFICAR_VERSION_COMPLETA.sh
bash VERIFICAR_VERSION_COMPLETA.sh
```

## Posibles Problemas y Soluciones

### Problema 1: Versión no es Build #5
**Solución**: Hacer redeploy desde EasyPanel
1. Ve a EasyPanel → Servicio 'dashboard'
2. Haz clic en 'Deploy' o 'Redeploy'
3. Espera 2-5 minutos

### Problema 2: Display de versión NO encontrado en HTML
**Solución**: El archivo en el contenedor es antiguo. Necesitas:
1. Verificar que GitHub tenga la versión correcta
2. Hacer redeploy desde EasyPanel

### Problema 3: JavaScript NO encontrado
**Solución**: Similar al problema 2, hacer redeploy

### Problema 4: Display existe pero no se muestra en la web
**Posibles causas**:
1. **CSS ocultando el elemento**: Verificar en la consola del navegador si el elemento existe pero está oculto
2. **JavaScript no se ejecuta**: Verificar en la consola si hay errores
3. **Caché del navegador**: Hacer hard refresh (Ctrl+F5)

## Verificar en el Navegador

1. Abre la consola del navegador (F12)
2. Ejecuta estos comandos:
```javascript
// Verificar variables de versión
console.log('Version:', window.DASHBOARD_VERSION);
console.log('Build:', window.DASHBOARD_BUILD_NUMBER);

// Verificar si el elemento existe
var versionDisplay = document.getElementById('version-display');
console.log('Display existe:', !!versionDisplay);
if (versionDisplay) {
    console.log('Display visible:', versionDisplay.offsetParent !== null);
    console.log('Display HTML:', versionDisplay.innerHTML);
}

// Verificar elementos hijos
var versionNumber = document.getElementById('version-number');
var buildNumber = document.getElementById('build-number');
console.log('Version number existe:', !!versionNumber);
console.log('Build number existe:', !!buildNumber);
if (versionNumber) console.log('Version number texto:', versionNumber.textContent);
if (buildNumber) console.log('Build number texto:', buildNumber.textContent);
```

## Si el Display No Aparece

Si el display existe en el HTML pero no se muestra, puede ser un problema de CSS. Verifica:

1. **En la consola del navegador**, ejecuta:
```javascript
var el = document.getElementById('version-display');
if (el) {
    var styles = window.getComputedStyle(el);
    console.log('Display:', styles.display);
    console.log('Visibility:', styles.visibility);
    console.log('Opacity:', styles.opacity);
    console.log('Height:', styles.height);
    console.log('Width:', styles.width);
}
```

2. **Si está oculto**, fuerza la visibilidad temporalmente:
```javascript
var el = document.getElementById('version-display');
if (el) {
    el.style.display = 'block';
    el.style.visibility = 'visible';
    el.style.opacity = '1';
}
```
