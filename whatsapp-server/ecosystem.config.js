// Configuración PM2 para WhatsApp 1 (única instancia en uso)
module.exports = {
  apps: [
    {
      name: 'whatsapp-1',
      script: './whatsapp-server-baileys.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 3001,
        INSTANCE_NUMBER: 1,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4'
      },
      error_file: './logs/whatsapp-1-error.log',
      out_file: './logs/whatsapp-1-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    }
  ]
};

