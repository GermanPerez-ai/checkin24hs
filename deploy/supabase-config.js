// ============================================
// CONFIGURACIÓN DE SUPABASE
// ============================================
// IMPORTANTE: Reemplaza estos valores con tus credenciales de Supabase
// Puedes encontrarlas en: https://supabase.com/dashboard/project/[tu-proyecto]/settings/api

const SUPABASE_CONFIG = {
    // URL de tu proyecto Supabase
    url: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
    
    // Clave pública (anon key) - Segura para usar en el frontend
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4'
};

// Validar que las credenciales estén configuradas
if (SUPABASE_CONFIG.url === 'TU_SUPABASE_URL_AQUI' || SUPABASE_CONFIG.anonKey === 'TU_SUPABASE_ANON_KEY_AQUI') {
    console.warn('⚠️ ATENCIÓN: Configura tus credenciales de Supabase en supabase-config.js');
    console.warn('📖 Ve a: https://supabase.com/dashboard para obtener tus credenciales');
}

// Exportar configuración
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SUPABASE_CONFIG;
} else {
    window.SUPABASE_CONFIG = SUPABASE_CONFIG;
}

