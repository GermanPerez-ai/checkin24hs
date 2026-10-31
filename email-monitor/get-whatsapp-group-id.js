#!/usr/bin/env node
/**
 * Script helper para obtener el ID de un grupo de WhatsApp
 * 
 * Uso:
 *   node get-whatsapp-group-id.js
 * 
 * Requisitos:
 *   - El servidor de WhatsApp debe estar corriendo
 *   - WHATSAPP_API_URL debe estar configurado en .env
 */

require('dotenv').config();
const axios = require('axios');

const WHATSAPP_API_URL = process.env.WHATSAPP_API_URL || 'http://localhost:3001';
const WHATSAPP_API_KEY = process.env.WHATSAPP_API_KEY;

async function getGroupInfo() {
    console.log('🔍 Obteniendo información de grupos de WhatsApp...\n');
    console.log(`📡 Conectando a: ${WHATSAPP_API_URL}\n`);
    
    if (!WHATSAPP_API_KEY) {
        console.warn('⚠️  WHATSAPP_API_KEY no configurada en .env');
        console.warn('   Si el servidor requiere autenticación, esta llamada fallará.\n');
    }
    
    try {
        // Verificar estado de conexión
        const headers = {};
        if (WHATSAPP_API_KEY) {
            headers['x-api-key'] = WHATSAPP_API_KEY;
        }
        
        const statusResponse = await axios.get(`${WHATSAPP_API_URL}/api/status`, {
            timeout: 5000,
            headers: headers
        });
        
        if (statusResponse.data.status !== 'open') {
            console.error('❌ WhatsApp no está conectado');
            console.error(`   Estado actual: ${statusResponse.data.status}`);
            console.error('\n💡 Asegúrate de que el servidor de WhatsApp esté corriendo y conectado.');
            console.error('   Para conectar, escanea el QR en: ' + WHATSAPP_API_URL);
            process.exit(1);
        }
        
        console.log('✅ WhatsApp conectado\n');
        console.log('📋 Para obtener el ID del grupo, tienes dos opciones:\n');
        
        console.log('OPCIÓN 1: Revisar los logs del servidor de Baileys');
        console.log('──────────────────────────────────────────────────');
        console.log('1. Envía un mensaje a cualquier grupo desde el celular conectado');
        console.log('2. Revisa los logs del servidor de WhatsApp:');
        console.log('   pm2 logs whatsapp-1 --lines 50');
        console.log('3. Busca líneas como: "Mensaje recibido de: 120363...@g.us"');
        console.log('4. Copia ese ID (formato: 120363123456789012@g.us)\n');
        
        console.log('OPCIÓN 2: Usar el endpoint /api/groups (si está disponible)');
        console.log('──────────────────────────────────────────────────');
        console.log('Si el servidor tiene un endpoint de grupos, puedes hacer:');
        console.log('   curl ' + WHATSAPP_API_URL + '/api/groups');
        console.log('   (Este endpoint debe agregarse al servidor si no existe)\n');
        
        console.log('OPCIÓN 3: Agregar código temporal al servidor');
        console.log('──────────────────────────────────────────────────');
        console.log('Agrega este código al archivo whatsapp-server-baileys.js');
        console.log('después de que se conecte (dentro del handler connection.update):');
        console.log('');
        console.log('   if (update.connection === "open") {');
        console.log('       const groups = await sock.groupFetchAllParticipating();');
        console.log('       console.log("📱 Grupos disponibles:");');
        console.log('       Object.values(groups).forEach(g => {');
        console.log('           console.log(`   ${g.subject}: ${g.id}`);');
        console.log('       });');
        console.log('   }');
        console.log('\nLuego reinicia el servidor y busca en los logs.\n');
        
        console.log('Una vez que tengas el ID del grupo (ej: 120363123456789012@g.us),');
        console.log('agrégalo al archivo .env:\n');
        console.log('   WHATSAPP_GROUP_ID=120363123456789012@g.us\n');
        
    } catch (error) {
        if (error.code === 'ECONNREFUSED') {
            console.error('❌ No se pudo conectar al servidor de WhatsApp');
            console.error(`   URL: ${WHATSAPP_API_URL}`);
            console.error('\n💡 Verifica que:');
            console.error('   1. El servidor de WhatsApp esté corriendo');
            console.error('   2. El puerto sea correcto (default: 3001)');
            console.error('   3. WHATSAPP_API_URL en .env sea correcta\n');
        } else {
            console.error('❌ Error:', error.message);
        }
        process.exit(1);
    }
}

getGroupInfo();
