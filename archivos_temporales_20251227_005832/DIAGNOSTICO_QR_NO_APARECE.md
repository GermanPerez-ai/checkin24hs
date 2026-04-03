# 🔍 Diagnóstico: QR No Aparece

## Problema
El QR no aparece cuando se hace clic en "Conectar" en las tarjetas de WhatsApp.

## Pasos de Diagnóstico

### 1. Verificar que la función existe
Ejecuta en la consola del navegador (F12):

```javascript
// Verificar funciones disponibles
console.log('connectWhatsApp:', typeof window.connectWhatsApp);
console.log('getServerURL:', typeof window.getServerURL);

// Verificar URL configurada
const serverUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl');
console.log('URL configurada:', serverUrl);

// Verificar URL construida para tarjeta 1
if (typeof window.getServerURL === 'function') {
    const url1 = window.getServerURL(1);
    console.log('URL para tarjeta 1:', url1);
}
```

### 2. Verificar estado de los botones
Ejecuta en la consola:

```javascript
// Verificar botones
for (let i = 1; i <= 4; i++) {
    const btn = document.getElementById(`whatsapp-${i}-connect-btn`);
    if (btn) {
        console.log(`Botón ${i}:`, {
            existe: !!btn,
            texto: btn.textContent,
            deshabilitado: btn.disabled,
            onclick: btn.getAttribute('onclick'),
            tieneListener: btn.onclick !== null
        });
    } else {
        console.log(`Botón ${i}: NO ENCONTRADO`);
    }
}
```

### 3. Probar conexión manualmente
Ejecuta en la consola:

```javascript
// Probar conexión manual
if (typeof window.connectWhatsApp === 'function') {
    console.log('🚀 Ejecutando connectWhatsApp(1) manualmente...');
    window.connectWhatsApp(1);
} else {
    console.error('❌ connectWhatsApp no está disponible');
}
```

### 4. Verificar estado de las tarjetas
Ejecuta en la consola:

```javascript
// Verificar estado guardado
const cardData = JSON.parse(localStorage.getItem('whatsappCards') || '{"1":{},"2":{},"3":{},"4":{}}');
console.log('Estado de tarjetas:', cardData);
```

### 5. Probar URL del servidor directamente
Ejecuta en la consola:

```javascript
// Probar URL del servidor
async function probarURL() {
    const serverUrl = localStorage.getItem('whatsappServerURL') || localStorage.getItem('whatsappServerUrl') || 'http://configwp.checkin24hs.com';
    let urlFinal = serverUrl.trim();
    
    // Convertir HTTP a HTTPS si el dashboard está en HTTPS
    if (window.location.protocol === 'https:' && urlFinal.startsWith('http://')) {
        urlFinal = urlFinal.replace('http://', 'https://');
    }
    
    // Agregar ruta
    urlFinal = `${urlFinal}/api1/api/qr?card=1`;
    
    console.log('🔗 Probando URL:', urlFinal);
    
    try {
        const response = await fetch(urlFinal, {
            method: 'GET',
            credentials: 'omit'
        });
        console.log('✅ Respuesta del servidor:', response.status, response.statusText);
        const data = await response.json();
        console.log('📦 Datos recibidos:', data);
    } catch (error) {
        console.error('❌ Error al conectar:', error);
    }
}

probarURL();
```

## Soluciones Posibles

### Solución 1: Verificar URL del servidor
1. Abre la consola del navegador (F12)
2. Ejecuta el paso 5 arriba
3. Si hay un error, verifica que el servidor esté funcionando

### Solución 2: Forzar reconexión
Ejecuta en la consola:

```javascript
// Limpiar estado y reconectar
localStorage.removeItem('whatsappCards');
localStorage.setItem('whatsappServerURL', 'https://configwp.checkin24hs.com');
console.log('✅ Estado limpiado. Ahora haz clic en "Conectar" nuevamente.');
```

### Solución 3: Verificar que el servidor responda
Desde el servidor, ejecuta:

```bash
# Verificar que el servicio WhatsApp esté corriendo
curl -k https://configwp.checkin24hs.com/api1/api/qr?card=1

# O desde el host directamente
curl http://127.0.0.1:4001/api/qr?card=1
```

### Solución 4: Recargar la página
Si nada funciona, recarga la página completamente (Ctrl+F5) y vuelve a intentar.

## Información a Recopilar

Si el problema persiste, ejecuta todos los pasos de diagnóstico y comparte:

1. Resultados del paso 1 (funciones disponibles)
2. Resultados del paso 2 (estado de botones)
3. Resultados del paso 3 (prueba manual)
4. Resultados del paso 5 (prueba de URL)
5. Cualquier error que aparezca en la consola


