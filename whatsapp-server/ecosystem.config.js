// Configuración PM2 para múltiples instancias de WhatsApp
module.exports = {
  apps: [
    {
      name: 'whatsapp-1',
      script: './whatsapp-server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 4001,
        INSTANCE_NUMBER: 1,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4',
        PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
      },
      error_file: './logs/whatsapp-1-error.log',
      out_file: './logs/whatsapp-1-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    },
    {
      name: 'whatsapp-2',
      script: './whatsapp-server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 4002,
        INSTANCE_NUMBER: 2,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4',
        PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
      },
      error_file: './logs/whatsapp-2-error.log',
      out_file: './logs/whatsapp-2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    },
    {
      name: 'whatsapp-3',
      script: './whatsapp-server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 4003,
        INSTANCE_NUMBER: 3,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4',
        PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
      },
      error_file: './logs/whatsapp-3-error.log',
      out_file: './logs/whatsapp-3-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    },
    {
      name: 'whatsapp-4',
      script: './whatsapp-server.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        PORT: 4004,
        INSTANCE_NUMBER: 4,
        NODE_ENV: 'production',
        SUPABASE_URL: 'https://lmoeuyasuvoqhtvhkyia.supabase.co',
        SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4',
        PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
      },
      error_file: './logs/whatsapp-4-error.log',
      out_file: './logs/whatsapp-4-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '1G'
    }
  ]
};

