/**
 * WhatsApp Integration Fix v3.0
 * Este archivo sobrescribe TODAS las funciones de WhatsApp
 * para garantizar que funcionen correctamente
 */

(function() {
    'use strict';
    
    console.log('📱 WhatsApp Fix v3.0 - Cargando...');
    
    // URL del servidor WhatsApp - FIJA
    const WHATSAPP_SERVER = 'https://whatsapp.checkin24hs.com';
    const API_STATUS = WHATSAPP_SERVER + '/api/status';
    const API_QR = WHATSAPP_SERVER + '/api/qr';
    
    // Sobrescribir checkWhatsAppConnection
    window.checkWhatsAppConnection = async function() {
        console.log('🔄 [v3.0] checkWhatsAppConnection - URL:', API_STATUS);
        
        const btn = document.querySelector('button[onclick="checkWhatsAppConnection()"]');
        const originalText = btn ? btn.innerHTML : '';
        
        try {
            if (btn) {
                btn.innerHTML = '⏳ Verificando...';
                btn.disabled = true;
            }
            
            const response = await fetch(API_STATUS, {
                method: 'GET',
                headers: { 'Accept': 'application/json' }
            });
            
            console.log('📡 Status:', response.status);
            
            if (!response.ok) {
                throw new Error('Error HTTP: ' + response.status);
            }
            
            const data = await response.json();
            console.log('✅ Respuesta:', data);
            
            if (data.connected) {
                alert('✅ WhatsApp Conectado!\n\nUsuario: ' + (data.userName || '-') + '\nTeléfono: ' + (data.phoneNumber || '-'));
            } else if (data.qrCode) {
                alert('📲 Servidor OK\n\nEsperando escaneo de QR.\nHaz clic en "Agregar conexión" para ver el código.');
            } else {
                alert('⚠️ Servidor disponible\n\nWhatsApp: ' + (data.whatsapp || 'desconectado'));
            }
            
        } catch (error) {
            console.error('❌ Error:', error);
            alert('❌ Error de conexión\n\n' + error.message + '\n\nVerifica que el servidor WhatsApp esté funcionando en:\n' + WHATSAPP_SERVER);
        } finally {
            if (btn) {
                btn.innerHTML = originalText;
                btn.disabled = false;
            }
        }
    };
    
    // Función para mostrar el QR
    window.showWhatsAppQR = async function(trayName) {
        console.log('🔄 [v3.0] showWhatsAppQR - Tray:', trayName);
        
        const qrContainer = document.getElementById('whatsapp-qr-code');
        if (!qrContainer) {
            console.error('No se encontró el contenedor del QR');
            return;
        }
        
        qrContainer.innerHTML = '<div style="text-align:center;padding:20px;"><span style="font-size:48px;">⏳</span><p>Cargando QR...</p></div>';
        
        try {
            const url = API_QR + '?tray=' + encodeURIComponent(trayName || 'default');
            console.log('📡 Obteniendo QR de:', url);
            
            const response = await fetch(url, {
                method: 'GET',
                headers: { 'Accept': 'application/json' }
            });
            
            if (!response.ok) {
                throw new Error('Error HTTP: ' + response.status);
            }
            
            const data = await response.json();
            console.log('📱 Respuesta QR:', data);
            
            if (data.status === 'connected') {
                qrContainer.innerHTML = '<div style="text-align:center;padding:20px;"><span style="font-size:64px;">✅</span><p style="color:#25D366;font-weight:bold;">WhatsApp Conectado</p></div>';
                return;
            }
            
            if (data.qrImage) {
                // Usar la URL de imagen del QR
                qrContainer.innerHTML = '<img src="' + data.qrImage + '" style="width:256px;height:256px;border-radius:8px;border:3px solid #25D366;" alt="Código QR" onerror="this.onerror=null;this.src=\'https://api.qrserver.com/v1/create-qr-code/?size=256x256&data=ERROR\';">';
            } else if (data.qr) {
                // Generar imagen del QR usando API externa
                const qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=256x256&data=' + encodeURIComponent(data.qr);
                qrContainer.innerHTML = '<img src="' + qrImageUrl + '" style="width:256px;height:256px;border-radius:8px;border:3px solid #25D366;" alt="Código QR">';
            } else if (data.status === 'initializing') {
                qrContainer.innerHTML = '<div style="text-align:center;padding:20px;"><span style="font-size:48px;">⏳</span><p>Iniciando servidor...</p><p style="font-size:12px;color:#666;">El QR aparecerá en unos segundos</p></div>';
                // Reintentar en 3 segundos
                setTimeout(function() { window.showWhatsAppQR(trayName); }, 3000);
            } else {
                qrContainer.innerHTML = '<div style="text-align:center;padding:20px;"><span style="font-size:48px;">❓</span><p>Estado desconocido</p><button onclick="window.showWhatsAppQR(\'' + (trayName || 'default') + '\')" style="padding:10px 20px;background:#25D366;color:white;border:none;border-radius:5px;cursor:pointer;">Reintentar</button></div>';
            }
            
        } catch (error) {
            console.error('❌ Error obteniendo QR:', error);
            qrContainer.innerHTML = '<div style="text-align:center;padding:20px;"><span style="font-size:48px;">❌</span><p style="color:red;">Error: ' + error.message + '</p><button onclick="window.showWhatsAppQR(\'' + (trayName || 'default') + '\')" style="padding:10px 20px;background:#25D366;color:white;border:none;border-radius:5px;cursor:pointer;">Reintentar</button></div>';
        }
    };
    
    // Sobrescribir startWhatsAppConnection
    window.startWhatsAppConnection = async function() {
        const trayNameInput = document.getElementById('new-whatsapp-tray-name');
        const trayName = trayNameInput ? trayNameInput.value.trim() : 'default';
        
        if (!trayName) {
            alert('⚠️ Por favor ingresa un nombre para la bandeja');
            return;
        }
        
        console.log('🔄 [v3.0] startWhatsAppConnection - Tray:', trayName);
        
        // Mostrar paso 2 (QR)
        const step1 = document.getElementById('whatsapp-step-1');
        const step2 = document.getElementById('whatsapp-step-2');
        
        if (step1) step1.style.display = 'none';
        if (step2) step2.style.display = 'block';
        
        // Mostrar el QR
        await window.showWhatsAppQR(trayName);
        
        // Verificar conexión periódicamente
        window.checkWhatsAppConnectionStatus(trayName);
    };
    
    // Verificar estado de conexión periódicamente
    window.checkWhatsAppConnectionStatus = function(trayName) {
        let attempts = 0;
        const maxAttempts = 60;
        
        const checkInterval = setInterval(async function() {
            attempts++;
            
            if (attempts > maxAttempts) {
                clearInterval(checkInterval);
                alert('⏱️ Tiempo de espera agotado. Intenta nuevamente.');
                return;
            }
            
            try {
                const response = await fetch(API_STATUS, {
                    method: 'GET',
                    headers: { 'Accept': 'application/json' }
                });
                
                if (response.ok) {
                    const data = await response.json();
                    if (data.connected) {
                        clearInterval(checkInterval);
                        
                        // Mostrar éxito
                        const step2 = document.getElementById('whatsapp-step-2');
                        const step3 = document.getElementById('whatsapp-step-3');
                        if (step2) step2.style.display = 'none';
                        if (step3) step3.style.display = 'block';
                        
                        alert('✅ ¡WhatsApp conectado exitosamente!\n\nUsuario: ' + (data.userName || '-') + '\nTeléfono: ' + (data.phoneNumber || '-'));
                    }
                }
            } catch (e) {
                // Ignorar errores, seguir intentando
            }
        }, 2000);
    };
    
    console.log('✅ WhatsApp Fix v3.0 - Funciones sobrescritas correctamente');
    console.log('📱 Servidor configurado:', WHATSAPP_SERVER);
    
})();

