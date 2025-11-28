// Script para agregar soporte multiidioma automáticamente
function addMultiLanguageSupport() {
    console.log('🌐 Agregando soporte multiidioma...');
    
    // Textos que necesitan traducción
    const translations = {
        'Iniciar Sesión': {
            en: 'Sign In',
            pt: 'Entrar'
        },
        'Crear Cuenta': {
            en: 'Create Account',
            pt: 'Criar Conta'
        },
        'Email': {
            en: 'Email',
            pt: 'Email'
        },
        'Contraseña': {
            en: 'Password',
            pt: 'Senha'
        },
        'O continúa con:': {
            en: 'Or continue with:',
            pt: 'Ou continue com:'
        },
        'Google': {
            en: 'Google',
            pt: 'Google'
        },
        'Facebook': {
            en: 'Facebook',
            pt: 'Facebook'
        },
        'o': {
            en: 'or',
            pt: 'ou'
        },
        'Continuar sin registro': {
            en: 'Continue without registration',
            pt: 'Continuar sem registro'
        },
        'Accede a todas las funciones sin crear cuenta': {
            en: 'Access all features without creating an account',
            pt: 'Acesse todas as funções sem criar conta'
        },
        'Nombre': {
            en: 'Name',
            pt: 'Nome'
        },
        'Teléfono': {
            en: 'Phone',
            pt: 'Telefone'
        },
        'Confirmar Contraseña': {
            en: 'Confirm Password',
            pt: 'Confirmar Senha'
        },
        'O regístrate con:': {
            en: 'Or register with:',
            pt: 'Ou registre-se com:'
        },
        'Tu centro de reservas 24/7': {
            en: 'Your 24/7 booking center',
            pt: 'Seu centro de reservas 24/7'
        }
    };
    
    // Función para agregar traducciones a un elemento
    function addTranslationsToElement(element, originalText) {
        if (!translations[originalText]) return;
        
        // Crear elementos para cada idioma
        const esSpan = document.createElement('span');
        esSpan.setAttribute('data-lang', 'es');
        esSpan.textContent = originalText;
        
        const enSpan = document.createElement('span');
        enSpan.setAttribute('data-lang', 'en');
        enSpan.textContent = translations[originalText].en;
        
        const ptSpan = document.createElement('span');
        ptSpan.setAttribute('data-lang', 'pt');
        ptSpan.textContent = translations[originalText].pt;
        
        // Limpiar el contenido original y agregar las traducciones
        element.innerHTML = '';
        element.appendChild(esSpan);
        element.appendChild(enSpan);
        element.appendChild(ptSpan);
    }
    
    // Buscar y procesar elementos de texto
    const textElements = document.querySelectorAll('h1, h2, h3, p, label, button, span');
    
    textElements.forEach(element => {
        const text = element.textContent.trim();
        if (translations[text]) {
            addTranslationsToElement(element, text);
        }
    });
    
    console.log('✅ Soporte multiidioma agregado');
}

// Ejecutar cuando el DOM esté listo
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addMultiLanguageSupport);
} else {
    addMultiLanguageSupport();
} 