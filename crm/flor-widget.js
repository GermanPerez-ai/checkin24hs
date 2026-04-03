// Widget flotante para integrar el chatbot Flor en cualquier página
// Checkin24hs - Agente de Conversación (Inspirado en Chatwoot)

(function() {
    'use strict';

    // Configuración del widget
    const widgetConfig = {
        position: 'bottom-right', // 'bottom-right', 'bottom-left', 'top-right', 'top-left'
        buttonColor: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        chatHeight: '600px',
        chatWidth: '450px',
        zIndex: 99999,
        initDelay: 1000, // Delay antes de mostrar el bubble
        bubbleShowDelay: 2000 // Delay para mostrar el botón
    };

    let isInitialized = false;
    let isReady = false;
    let userConfig = null;

    // Crear estilos CSS para el widget (inspirado en Chatwoot)
    function createWidgetStyles() {
        const style = document.createElement('style');
        style.textContent = `
            .flor-widget-container {
                position: fixed;
                bottom: 20px;
                right: 20px;
                z-index: ${widgetConfig.zIndex};
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
                font-size: 14px;
            }

            .flor-widget-bubble {
                width: 60px;
                height: 60px;
                border-radius: 50%;
                background: ${widgetConfig.buttonColor};
                color: white;
                border: none;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 32px;
                box-shadow: 0 2px 16px rgba(0,0,0,0.15), 0 4px 8px rgba(0,0,0,0.1);
                transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                position: relative;
                opacity: 0;
                transform: scale(0);
            }

            .flor-widget-bubble.visible {
                opacity: 1;
                transform: scale(1);
            }

            .flor-widget-bubble:hover {
                transform: scale(1.05);
                box-shadow: 0 4px 20px rgba(102, 126, 234, 0.4), 0 8px 12px rgba(0,0,0,0.15);
            }

            .flor-widget-bubble:active {
                transform: scale(0.95);
            }

            .flor-widget-bubble:focus {
                outline: none;
                box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.2);
            }

            .flor-widget-notification {
                position: absolute;
                top: -2px;
                right: -2px;
                min-width: 20px;
                height: 20px;
                background: #ff4444;
                border-radius: 10px;
                border: 2px solid white;
                display: none;
                align-items: center;
                justify-content: center;
                font-size: 11px;
                font-weight: 600;
                color: white;
                padding: 0 6px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.2);
            }

            .flor-widget-notification.active {
                display: flex;
                animation: pulseNotification 1s ease-in-out infinite;
            }

            @keyframes pulseNotification {
                0%, 100% { transform: scale(1); }
                50% { transform: scale(1.1); }
            }

            .flor-widget-window {
                position: fixed;
                bottom: 90px;
                right: 20px;
                width: ${widgetConfig.chatWidth};
                max-width: calc(100vw - 40px);
                height: ${widgetConfig.chatHeight};
                max-height: calc(100vh - 120px);
                background: white;
                border-radius: 12px 12px 0 12px;
                box-shadow: 0 8px 40px rgba(0,0,0,0.12), 0 2px 8px rgba(0,0,0,0.08);
                display: none;
                flex-direction: column;
                overflow: hidden;
                z-index: ${widgetConfig.zIndex + 1};
                opacity: 0;
                transform: translateY(10px) scale(0.95);
                transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            }

            .flor-widget-window.active {
                display: flex;
                opacity: 1;
                transform: translateY(0) scale(1);
            }

            .flor-widget-header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 16px 20px;
                display: flex;
                align-items: center;
                justify-content: space-between;
                min-height: 64px;
            }

            .flor-widget-header-left {
                display: flex;
                align-items: center;
                gap: 12px;
                flex: 1;
            }

            .flor-widget-avatar {
                width: 40px;
                height: 40px;
                border-radius: 50%;
                background: rgba(255,255,255,0.2);
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 20px;
                flex-shrink: 0;
            }

            .flor-widget-header-info h3 {
                font-size: 16px;
                font-weight: 600;
                margin: 0 0 2px 0;
                line-height: 1.2;
            }

            .flor-widget-header-info p {
                font-size: 12px;
                opacity: 0.9;
                margin: 0;
                line-height: 1.2;
            }

            .flor-widget-status {
                width: 8px;
                height: 8px;
                border-radius: 50%;
                background: #4caf50;
                flex-shrink: 0;
            }

            .flor-widget-header-actions {
                display: flex;
                gap: 8px;
                align-items: center;
            }

            .flor-widget-btn-icon {
                width: 32px;
                height: 32px;
                border-radius: 50%;
                border: none;
                background: rgba(255,255,255,0.2);
                color: white;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: background 0.2s;
                font-size: 18px;
                padding: 0;
            }

            .flor-widget-btn-icon:hover {
                background: rgba(255,255,255,0.3);
            }

            .flor-widget-body {
                flex: 1;
                display: flex;
                flex-direction: column;
                overflow: hidden;
                background: #f5f5f5;
            }

            @media (max-width: 500px) {
                .flor-widget-window {
                    bottom: 0;
                    right: 0;
                    left: 0;
                    width: 100%;
                    max-width: 100%;
                    height: 100vh;
                    max-height: 100vh;
                    border-radius: 0;
                }

                .flor-widget-bubble {
                    bottom: 10px;
                    right: 10px;
                }
            }

            /* Animación de entrada suave */
            @keyframes slideInUp {
                from {
                    opacity: 0;
                    transform: translateY(20px) scale(0.9);
                }
                to {
                    opacity: 1;
                    transform: translateY(0) scale(1);
                }
            }

            .flor-widget-bubble.slide-in {
                animation: slideInUp 0.4s cubic-bezier(0.4, 0, 0.2, 1) forwards;
            }
        `;
        document.head.appendChild(style);
    }

    // Crear el botón bubble del widget (estilo Chatwoot)
    function createWidgetBubble() {
        const bubble = document.createElement('button');
        bubble.className = 'flor-widget-bubble';
        bubble.innerHTML = '🌸';
        bubble.setAttribute('aria-label', 'Abrir chat con Flor');
        bubble.setAttribute('title', 'Habla con Flor - Asistente Virtual');
        bubble.setAttribute('role', 'button');
        bubble.setAttribute('tabindex', '0');

        // Agregar notificación badge
        const notification = document.createElement('div');
        notification.className = 'flor-widget-notification';
        bubble.appendChild(notification);

        // Agregar efecto de entrada
        setTimeout(() => {
            bubble.classList.add('visible', 'slide-in');
        }, widgetConfig.bubbleShowDelay);

        return bubble;
    }

    // Crear el contenedor del chat (estilo Chatwoot)
    function createChatWindow() {
        const window = document.createElement('div');
        window.className = 'flor-widget-window';
        window.id = 'florWidgetWindow';

        // Header del chat
        const header = document.createElement('div');
        header.className = 'flor-widget-header';
        
        const headerLeft = document.createElement('div');
        headerLeft.className = 'flor-widget-header-left';
        
        const avatar = document.createElement('div');
        avatar.className = 'flor-widget-avatar';
        avatar.innerHTML = '🌸';
        
        const headerInfo = document.createElement('div');
        headerInfo.className = 'flor-widget-header-info';
        headerInfo.innerHTML = `
            <h3>Flor</h3>
            <p>Asistente Virtual</p>
        `;
        
        const status = document.createElement('div');
        status.className = 'flor-widget-status';
        status.setAttribute('title', 'En línea');
        
        headerLeft.appendChild(avatar);
        headerLeft.appendChild(headerInfo);
        headerLeft.appendChild(status);
        
        const headerActions = document.createElement('div');
        headerActions.className = 'flor-widget-header-actions';
        
        // Botón de minimizar
        const minimizeBtn = document.createElement('button');
        minimizeBtn.className = 'flor-widget-btn-icon';
        minimizeBtn.innerHTML = '−';
        minimizeBtn.setAttribute('title', 'Minimizar');
        minimizeBtn.setAttribute('aria-label', 'Minimizar chat');
        minimizeBtn.onclick = () => toggleChat();
        
        // Botón de cerrar
        const closeBtn = document.createElement('button');
        closeBtn.className = 'flor-widget-btn-icon';
        closeBtn.innerHTML = '×';
        closeBtn.setAttribute('title', 'Cerrar');
        closeBtn.setAttribute('aria-label', 'Cerrar chat');
        closeBtn.onclick = () => toggleChat();
        
        headerActions.appendChild(minimizeBtn);
        headerActions.appendChild(closeBtn);
        
        header.appendChild(headerLeft);
        header.appendChild(headerActions);
        
        // Body del chat - usar iframe para mantener funcionalidad
        const body = document.createElement('div');
        body.className = 'flor-widget-body';
        
        const iframe = document.createElement('iframe');
        iframe.src = 'flor-chatbot.html';
        iframe.setAttribute('frameborder', '0');
        iframe.setAttribute('allow', 'microphone');
        iframe.style.cssText = 'width: 100%; height: 100%; border: none;';
        
        body.appendChild(iframe);
        
        window.appendChild(header);
        window.appendChild(body);

        return window;
    }

    // Toggle del chat
    function toggleChat() {
        const window = document.getElementById('florWidgetWindow');
        const bubble = document.querySelector('.flor-widget-bubble');
        
        if (window) {
            window.classList.toggle('active');
            
            // Cambiar ícono del botón cuando está abierto
            if (bubble) {
                if (window.classList.contains('active')) {
                    bubble.innerHTML = '✕';
                    bubble.setAttribute('title', 'Cerrar chat');
                } else {
                    bubble.innerHTML = '🌸';
                    bubble.setAttribute('title', 'Habla con Flor - Asistente Virtual');
                }
            }
        }
    }

    // Configurar usuario (similar a Chatwoot setUser)
    function setUser(identifier, config = {}) {
        userConfig = { identifier, ...config };
        console.log('[Flor] 📧 Configurando usuario:', identifier);
        console.log('[Flor] ⏰ Timestamp:', new Date().toISOString());
        
        // Guardar configuración de usuario en localStorage
        localStorage.setItem('flor_user_config', JSON.stringify(userConfig));
        
        isReady = true;
        console.log('[Flor] ✅ Usuario configurado');
        
        return true;
    }

    // Inicializar el widget (con polling similar a Chatwoot)
    function initWidget() {
        if (isInitialized) {
            console.log('[Flor] 🛡️ Ya inicializado, omitiendo duplicado');
            return;
        }

        console.log('[Flor] 🔄 Inicializando widget...');
        console.log('[Flor] ⏰ Timestamp:', new Date().toISOString());

        // Crear estilos
        createWidgetStyles();

        // Crear contenedor principal
        const container = document.createElement('div');
        container.className = 'flor-widget-container';
        container.id = 'florWidgetContainer';

        // Crear bubble button
        const bubble = createWidgetBubble();
        bubble.onclick = toggleChat;
        bubble.onkeypress = (e) => {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                toggleChat();
            }
        };
        container.appendChild(bubble);

        // Crear ventana de chat
        const window = createChatWindow();
        container.appendChild(window);

        // Agregar al body
        document.body.appendChild(container);

        isInitialized = true;
        console.log('[Flor] ✅ Widget inicializado');

        // Simular carga y mostrar bubble después de delay
        setTimeout(() => {
            console.log('[Flor] ✅ Bubble mostrado después de inicialización');
            console.log('[Flor] ✅ Widget listo para interacción');
        }, widgetConfig.bubbleShowDelay);

        // Cerrar al hacer clic fuera en móviles
        if (window.innerWidth <= 500) {
            window.addEventListener('click', (e) => {
                if (e.target === window) {
                    toggleChat();
                }
            });
        }
    }

    // Polling para verificar si el widget está listo (similar a Chatwoot)
    function waitForWidgetReady(callback, maxAttempts = 10) {
        let attempts = 0;
        const checkReady = setInterval(() => {
            attempts++;
            if (isReady || attempts >= maxAttempts) {
                clearInterval(checkReady);
                if (callback) callback();
            }
        }, 200);
    }

    // Inicializar cuando el DOM esté listo (con delay similar a Chatwoot)
    function startInitialization() {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                setTimeout(initWidget, widgetConfig.initDelay);
            });
        } else {
            setTimeout(initWidget, widgetConfig.initDelay);
        }
    }

    // Iniciar
    startInitialization();

    // Exponer API global (similar a Chatwoot)
    window.FlorWidget = {
        open: () => {
            const window = document.getElementById('florWidgetWindow');
            if (window && !window.classList.contains('active')) {
                toggleChat();
            }
        },
        close: () => {
            const window = document.getElementById('florWidgetWindow');
            if (window && window.classList.contains('active')) {
                toggleChat();
            }
        },
        show: () => {
            const window = document.getElementById('florWidgetWindow');
            if (window) window.classList.add('active');
        },
        hide: () => {
            const window = document.getElementById('florWidgetWindow');
            if (window) window.classList.remove('active');
        },
        setUser: setUser,
        toggle: toggleChat,
        isReady: () => isReady,
        reset: () => {
            localStorage.removeItem('flor_user_config');
            userConfig = null;
            isReady = false;
        }
    };

    // Logging para debugging (similar a Chatwoot)
    console.log('[Flor] 🎯 Widget SDK cargado');
    console.log('[Flor] ⏰ Timestamp:', new Date().toISOString());

})();

