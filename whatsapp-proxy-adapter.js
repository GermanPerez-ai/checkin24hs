/**
 * 🔒 WhatsApp Proxy Adapter
 * 
 * Este script intercepta las llamadas al servidor WhatsApp y las redirige
 * al proxy local (serve-dashboard.js) que agrega la API key de forma segura.
 * 
 * Incluir este script en dashboard.html ANTES de cualquier código que llame
 * al servidor WhatsApp.
 * 
 * USO:
 * <script src="./whatsapp-proxy-adapter.js"></script>
 */

(function() {
    'use strict';

    // Detectar si estamos en un entorno con proxy local
    const isLocalDashboard = window.location.hostname === 'dashboard.checkin24hs.com' || 
                            window.location.hostname === 'localhost' ||
                            window.location.hostname.includes('easypanel');

    // Mapeo de rutas del servidor WhatsApp al proxy local
    const PROXY_ROUTES = {
        '/api/send': '/api/whatsapp-proxy/send',
        '/api/send-audio': '/api/whatsapp-proxy/send-audio',
        '/api/send-media': '/api/whatsapp-proxy/send-media',
        '/api/status': '/api/whatsapp-proxy/status',
        '/api/qr': '/api/whatsapp-proxy/qr'
    };

    // URLs del servidor WhatsApp que deben ser proxeadas
    const WHATSAPP_HOSTS = [
        'whatsapp.checkin24hs.com',
        'api1.checkin24hs.com'
    ];

    /**
     * Verifica si una URL debe ser proxeada
     */
    function shouldProxy(url) {
        if (!isLocalDashboard) return false;
        
        try {
            const urlObj = new URL(url, window.location.origin);
            const hostname = urlObj.hostname;
            const pathname = urlObj.pathname;
            
            // Verificar si es una URL del servidor WhatsApp
            const isWhatsAppHost = WHATSAPP_HOSTS.some(host => hostname.includes(host));
            
            // Verificar si es una ruta que necesita proxy
            const needsProxy = Object.keys(PROXY_ROUTES).some(route => pathname.includes(route));
            
            return isWhatsAppHost && needsProxy;
        } catch (e) {
            return false;
        }
    }

    /**
     * Convierte una URL del servidor WhatsApp a URL del proxy local
     */
    function convertToProxyUrl(url) {
        try {
            const urlObj = new URL(url, window.location.origin);
            const pathname = urlObj.pathname;
            
            // Buscar la ruta que coincida
            for (const [original, proxy] of Object.entries(PROXY_ROUTES)) {
                if (pathname.includes(original)) {
                    // Reemplazar con la ruta del proxy
                    return proxy;
                }
            }
            
            return url;
        } catch (e) {
            console.error('Error convirtiendo URL a proxy:', e);
            return url;
        }
    }

    /**
     * Interceptar fetch global
     */
    const originalFetch = window.fetch;
    window.fetch = function(url, options = {}) {
        if (shouldProxy(url)) {
            const proxyUrl = convertToProxyUrl(url);
            console.log(`🔒 Proxeando llamada WhatsApp: ${url} → ${proxyUrl}`);
            return originalFetch(proxyUrl, options);
        }
        return originalFetch(url, options);
    };

    /**
     * Interceptar XMLHttpRequest (por si algún código viejo lo usa)
     */
    const OriginalXHR = window.XMLHttpRequest;
    window.XMLHttpRequest = function() {
        const xhr = new OriginalXHR();
        const originalOpen = xhr.open;
        
        xhr.open = function(method, url, async, user, password) {
            let finalUrl = url;
            
            if (shouldProxy(url)) {
                finalUrl = convertToProxyUrl(url);
                console.log(`🔒 Proxeando XHR WhatsApp: ${url} → ${finalUrl}`);
            }
            
            return originalOpen.call(this, method, finalUrl, async, user, password);
        };
        
        return xhr;
    };

    console.log('✅ WhatsApp Proxy Adapter inicializado');
    console.log(`   Modo proxy: ${isLocalDashboard ? 'ACTIVADO' : 'DESACTIVADO'}`);
    if (isLocalDashboard) {
        console.log(`   Las llamadas a ${WHATSAPP_HOSTS.join(', ')} serán proxeadas`);
    }
})();
