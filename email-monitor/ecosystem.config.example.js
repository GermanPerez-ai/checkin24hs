/**
 * Configuración PM2 para el monitor de correo
 * 
 * Para agregar al ecosystem.config.js existente de whatsapp-server-baileys/
 */

const path = require('path');

module.exports = {
  apps: [
    // ... apps existentes (whatsapp-1, whatsapp-2, etc.) ...
    
    // Monitor de correo - revisa cada 15 minutos
    {
      name: 'email-monitor',
      script: path.join(__dirname, '..', 'email-monitor', 'monitor.js'),
      cwd: path.join(__dirname, '..', 'email-monitor'),
      env: {
        NODE_ENV: 'production'
      },
      cron_restart: '*/15 * * * *',  // Cada 15 minutos
      autorestart: false,  // No reiniciar automáticamente (cron lo maneja)
      error_file: path.join(__dirname, 'logs', 'email-monitor-error.log'),
      out_file: path.join(__dirname, 'logs', 'email-monitor-out.log'),
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      max_memory_restart: '200M'
    }
  ]
};
