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
const WHATSAPP_API_KEY = (process.env.WHATSAPP_API_KEY || '').trim().replace(/[\r\n]/g, '');

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
        
        // La respuesta tiene formato: { connected: true, whatsapp: "connected", ... }
        const isConnected = statusResponse.data.connected === true || 
                           statusResponse.data.whatsapp === 'connected';
        
        if (!isConnected) {
            console.error('❌ WhatsApp no está conectado');
            console.error(`   Estado actual: connected=${statusResponse.data.connected}, whatsapp=${statusResponse.data.whatsapp}`);
            console.error('\n💡 Asegúrate de que el servidor de WhatsApp esté corriendo y conectado.');
            console.error('   Para conectar, escanea el QR en: ' + WHATSAPP_API_URL);
            process.exit(1);
        }
        
        console.log('✅ WhatsApp conectado');
        console.log(`   📱 Teléfono: ${statusResponse.data.phone || 'desconocido'}`);
        console.log(`   👤 Nombre: ${statusResponse.data.name || 'desconocido'}\n');
        
        // Intentar obtener grupos desde el endpoint /api/groups
        console.log('🔍 Obteniendo lista de grupos...\n');
        
        try {
            const groupsResponse = await axios.get(`${WHATSAPP_API_URL}/api/groups`, {
                timeout: 10000,
                headers: headers
            });
            
            if (groupsResponse.data.success && groupsResponse.data.groups) {
                const groups = groupsResponse.data.groups;
                
                if (groups.length === 0) {
                    console.log('⚠️  No se encontraron grupos de WhatsApp');
                    console.log('   Verifica que el número conectado esté en grupos.\n');
                } else {
                    console.log(`✅ Encontrados ${groups.length} grupo(s):\n`);
                    console.log('═'.repeat(70));
                    
                    groups.forEach((group, index) => {
                        console.log(`\n${index + 1}. 📱 ${group.subject}`);
                        console.log(`   ID: ${group.id}`);
                        console.log(`   Participantes: ${group.size || 'desconocido'}`);
                    });
                    
                    console.log('\n' + '═'.repeat(70));
                    console.log('\n💡 Para usar uno de estos grupos:');
                    console.log('   1. Copia el ID del grupo deseado');
                    console.log('   2. Agrégalo al archivo .env:\n');
                    console.log('      WHATSAPP_GROUP_ID=120363123456789012@g.us\n');
                }
            } else {
                throw new Error('Respuesta inválida del servidor');
            }
        } catch (groupsError) {
            // Si el endpoint no existe, dar instrucciones alternativas
            console.log('⚠️  No se pudo obtener la lista de grupos automáticamente');
            console.log(`   Error: ${groupsError.message}\n`);
            console.log('📋 Opciones para obtener el ID del grupo:\n');
            
            console.log('OPCIÓN 1: Revisar los logs del servidor de Baileys');
            console.log('──────────────────────────────────────────────────');
            console.log('1. Envía un mensaje a cualquier grupo desde el celular conectado');
            console.log('2. Revisa los logs del servidor de WhatsApp:');
            console.log('   pm2 logs whatsapp-1 --lines 50');
            console.log('3. Busca líneas como: "Mensaje recibido de: 120363...@g.us"');
            console.log('4. Copia ese ID (formato: 120363123456789012@g.us)\n');
            
            console.log('OPCIÓN 2: Agregar el endpoint /api/groups al servidor');
            console.log('──────────────────────────────────────────────────');
            console.log('Este PR ya incluye el endpoint necesario.');
            console.log('Redeploy el servidor WhatsApp y vuelve a ejecutar este script.\n');
        }
        
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
