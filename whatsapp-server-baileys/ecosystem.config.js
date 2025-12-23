module.exports = {
  apps: [
    {
      name: 'whatsapp-1',
      script: './whatsapp-server-baileys.js',
      env: {
        INSTANCE_NUMBER: '1',
        PORT: '3001',
        NODE_ENV: 'production'
      },
      error_file: './logs/whatsapp-1-error.log',
      out_file: './logs/whatsapp-1-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'whatsapp-2',
      script: './whatsapp-server-baileys.js',
      env: {
        INSTANCE_NUMBER: '2',
        PORT: '3002',
        NODE_ENV: 'production'
      },
      error_file: './logs/whatsapp-2-error.log',
      out_file: './logs/whatsapp-2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'whatsapp-3',
      script: './whatsapp-server-baileys.js',
      env: {
        INSTANCE_NUMBER: '3',
        PORT: '3003',
        NODE_ENV: 'production'
      },
      error_file: './logs/whatsapp-3-error.log',
      out_file: './logs/whatsapp-3-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'whatsapp-4',
      script: './whatsapp-server-baileys.js',
      env: {
        INSTANCE_NUMBER: '4',
        PORT: '3004',
        NODE_ENV: 'production'
      },
      error_file: './logs/whatsapp-4-error.log',
      out_file: './logs/whatsapp-4-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M'
    }
  ]
};

