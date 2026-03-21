/**
 * PM2: ejecuta SIEMPRE el archivo canónico del repo (no hay segunda copia del .js).
 * @see README.md en esta carpeta
 */
const path = require('path');

const serverDir = path.join(__dirname, '..', 'whatsapp-server');
const script = path.join(serverDir, 'whatsapp-server-baileys.js');

module.exports = {
  apps: [
    {
      name: 'whatsapp-1',
      script,
      cwd: serverDir,
      env: {
        INSTANCE_NUMBER: '1',
        PORT: '3001',
        NODE_ENV: 'production'
      },
      error_file: path.join(__dirname, 'logs', 'whatsapp-1-error.log'),
      out_file: path.join(__dirname, 'logs', 'whatsapp-1-out.log'),
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'whatsapp-2',
      script,
      cwd: serverDir,
      env: {
        INSTANCE_NUMBER: '2',
        PORT: '3002',
        NODE_ENV: 'production'
      },
      error_file: path.join(__dirname, 'logs', 'whatsapp-2-error.log'),
      out_file: path.join(__dirname, 'logs', 'whatsapp-2-out.log'),
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'whatsapp-3',
      script,
      cwd: serverDir,
      env: {
        INSTANCE_NUMBER: '3',
        PORT: '3003',
        NODE_ENV: 'production'
      },
      error_file: path.join(__dirname, 'logs', 'whatsapp-3-error.log'),
      out_file: path.join(__dirname, 'logs', 'whatsapp-3-out.log'),
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'whatsapp-4',
      script,
      cwd: serverDir,
      env: {
        INSTANCE_NUMBER: '4',
        PORT: '3004',
        NODE_ENV: 'production'
      },
      error_file: path.join(__dirname, 'logs', 'whatsapp-4-error.log'),
      out_file: path.join(__dirname, 'logs', 'whatsapp-4-out.log'),
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M'
    }
  ]
};
