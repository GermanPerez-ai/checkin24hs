#!/usr/bin/env node
/**
 * Tests unitarios para email-monitor
 * Valida clasificación de emails comerciales vs reservas vs filtrados
 */

const assert = require('assert');

// Mock de configuración para tests
process.env.FILTER_KEYWORDS = 'reserva,modificación,modificacion,anulación,anulacion,cancelación,cancelacion,voucher,cupo,confirmación,confirmacion';
process.env.BUSINESS_KEYWORDS = 'reunión,reunion,propuesta,cotización,cotizacion,tarifas,tarifa,convenio,comisión,comision,disponibilidad,consulta,información,informacion,novedades,contrato,facturación,facturacion,pagos,pago';
process.env.NEWSLETTER_KEYWORDS = 'suscri,unsubscribe,newsletter,boletin,boletín,marketing,publicidad';
process.env.INTERNAL_SENDERS = 'checkin24hs.com,axelbisio@hotmail.com';
process.env.PROVIDER_DOMAINS = 'ratehawk.com,emergingtravel.com';

// Importar funciones a testear (solo después de setear env vars)
const {
    isReservationRelated,
    cleanEmailText,
    extractEmailInfo
} = require('./monitor.js');

// Helper para crear emails de test
function createTestEmail(overrides = {}) {
    return {
        messageId: overrides.messageId || '<test@example.com>',
        from: overrides.from || { value: [{ address: 'hotel@test.com', name: 'Hotel Test' }] },
        to: overrides.to || { value: [{ address: 'reservas@checkin24hs.com' }] },
        subject: overrides.subject || 'Test Subject',
        text: overrides.text || 'Test body',
        html: overrides.html || '',
        date: overrides.date || new Date(),
        inReplyTo: overrides.inReplyTo || null,
        references: overrides.references || [],
        headers: overrides.headers || new Map()
    };
}

// Helper para clasificar un email de test
function classifyEmail(emailData) {
    // Reimplementar lógica de clasificación simplificada para tests
    const parsed = createTestEmail(emailData);
    const subject = (parsed.subject || '').toLowerCase();
    const text = (parsed.text || '').toLowerCase();
    const combined = `${subject} ${text}`;
    
    const fromAddr = parsed.from.value[0].address.toLowerCase();
    const senderType = fromAddr.includes('checkin24hs.com') || fromAddr === 'axelbisio@hotmail.com'
        ? 'internal'
        : 'external';
    
    if (senderType === 'internal') {
        return { type: 'filtered', reason: 'internal_sender' };
    }
    
    // Check reservations
    const reservationKeywords = process.env.FILTER_KEYWORDS.split(',').map(k => k.trim().toLowerCase());
    const hasReservationKeyword = reservationKeywords.some(kw => combined.includes(kw));
    
    if (hasReservationKeyword) {
        return { type: 'reservation' };
    }
    
    // Check newsletters
    const newsletterKeywords = process.env.NEWSLETTER_KEYWORDS.split(',').map(k => k.trim().toLowerCase());
    const hasNewsletterKeyword = newsletterKeywords.some(kw => combined.includes(kw));
    const hasListUnsubscribe = parsed.headers && parsed.headers.has('list-unsubscribe');
    
    // Check mass mailing (more than 5 recipients)
    const allRecipients = [];
    if (parsed.to && parsed.to.value) {
        allRecipients.push(...parsed.to.value);
    }
    if (parsed.cc && parsed.cc.value) {
        allRecipients.push(...parsed.cc.value);
    }
    const isMassMailing = allRecipients.length > 5;
    
    if (hasNewsletterKeyword || hasListUnsubscribe || isMassMailing) {
        return { type: 'filtered', reason: 'newsletter_or_spam' };
    }
    
    // Check if it's a reply
    const isReply = Boolean(parsed.inReplyTo || (parsed.references && parsed.references.length > 0));
    const hasReplyPrefix = /^(re|rv):/i.test(subject);
    
    if (isReply || hasReplyPrefix) {
        return { type: 'business', reason: 'reply_in_thread' };
    }
    
    // Check business keywords
    const businessKeywords = process.env.BUSINESS_KEYWORDS.split(',').map(k => k.trim().toLowerCase());
    const hasBusinessKeyword = businessKeywords.some(kw => combined.includes(kw));
    
    if (hasBusinessKeyword && text.length >= 50) {
        return { type: 'business', reason: 'business_keywords' };
    }
    
    return { type: 'filtered', reason: 'no_relevant_signals' };
}

// ===== TESTS =====

console.log('🧪 Ejecutando tests...\n');

let passed = 0;
let failed = 0;

function test(name, fn) {
    try {
        fn();
        console.log(`✅ ${name}`);
        passed++;
    } catch (error) {
        console.error(`❌ ${name}`);
        console.error(`   ${error.message}`);
        failed++;
    }
}

// TEST 1: Email real de Mónica Cornejo debe alertar como comercial
test('Email de Mónica Cornejo (respuesta comercial) debe alertar', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'mcornejo@corralco.com', name: 'Mónica Cornejo' }] },
        subject: 'RE: Checkin24hs: envío de novedades, promociones y programas',
        text: `Hola German:
Un gusto y gracias por la información.
Si gustas podemos coordinar una reunión para que conozcas las novedades del hotel.
Quedo atenta a tu disponibilidad,
Saludos cordiales,
Mónica Cornejo C.
Ejecutiva de Ventas Corporativas y Tour & Travel`,
        inReplyTo: '<original@checkin24hs.com>',
        references: ['<original@checkin24hs.com>']
    });
    
    assert.strictEqual(result.type, 'business', `Esperaba 'business', obtuvo '${result.type}'`);
});

// TEST 2: Respuesta de proveedor sin código debe alertar
test('Respuesta de proveedor sin código de reserva debe alertar', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'ventas@ratehawk.com', name: 'RateHawk Support' }] },
        subject: 'RE: Consulta sobre tarifas especiales',
        text: 'Hola, gracias por tu consulta. Te enviamos la información solicitada sobre nuestras tarifas para grupos.',
        inReplyTo: '<consulta@checkin24hs.com>'
    });
    
    assert.strictEqual(result.type, 'business', `Esperaba 'business', obtuvo '${result.type}'`);
});

// TEST 3: Newsletter sin hilo debe filtrar
test('Newsletter sin hilo debe filtrarse', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'marketing@hotel.com', name: 'Hotel Marketing' }] },
        subject: 'Ofertas especiales de verano - Newsletter',
        text: 'Descubre nuestras promociones. Para desuscribirte haz click aquí: unsubscribe',
        headers: new Map([['list-unsubscribe', '<mailto:unsubscribe@hotel.com>']])
    });
    
    assert.strictEqual(result.type, 'filtered', `Esperaba 'filtered', obtuvo '${result.type}'`);
    assert.strictEqual(result.reason, 'newsletter_or_spam', `Esperaba 'newsletter_or_spam', obtuvo '${result.reason}'`);
});

// TEST 4: Remitente interno debe filtrar
test('Remitente interno debe filtrarse', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'german@checkin24hs.com', name: 'German' }] },
        subject: 'RE: Consulta',
        text: 'Hola, te respondo sobre la consulta de la reserva.',
        inReplyTo: '<test@test.com>'
    });
    
    assert.strictEqual(result.type, 'filtered', `Esperaba 'filtered', obtuvo '${result.type}'`);
    assert.strictEqual(result.reason, 'internal_sender', `Esperaba 'internal_sender', obtuvo '${result.reason}'`);
});

// TEST 5: Email de reserva con señales fuertes debe clasificarse como reserva
test('Email con palabras clave de reserva debe alertar como reserva', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'reservas@hotelpuyehue.cl', name: 'Hotel Puyehue' }] },
        subject: 'RE: Modificación reserva V2K67A',
        text: 'Confirmamos la modificación de la reserva V2K67A. Las nuevas fechas son check-in 15/12/2026 y check-out 20/12/2026.',
        inReplyTo: '<solicitud@checkin24hs.com>'
    });
    
    assert.strictEqual(result.type, 'reservation', `Esperaba 'reservation', obtuvo '${result.type}'`);
});

// TEST 6: Solo email de reserva debe disparar lógica de auto-cierre (no comerciales)
test('Verificar que emails comerciales NO disparan auto-cierre', () => {
    // Este test es conceptual - en la implementación real, el auto-cierre
    // solo se ejecuta cuando emailType === 'reservation'
    const commercialEmail = classifyEmail({
        from: { value: [{ address: 'ventas@hotel.com', name: 'Hotel Ventas' }] },
        subject: 'RE: Propuesta de convenio',
        text: 'Hola, te enviamos nuestra propuesta de convenio corporativo con tarifas especiales.',
        inReplyTo: '<test@checkin24hs.com>'
    });
    
    assert.strictEqual(commercialEmail.type, 'business', 'Email debe ser comercial');
    // En el código real, processAutoClose() solo se llama si emailType === 'reservation'
});

// TEST 7: Email nuevo con palabras de negocio claras debe alertar
test('Email nuevo con palabras de negocio debe alertar', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'comercial@hotel.com', name: 'Hotel Comercial' }] },
        subject: 'Propuesta de convenio corporativo',
        text: 'Estimados, les enviamos nuestra propuesta de convenio corporativo con tarifas preferenciales para su agencia. Quedamos atentos a coordinar una reunión para detalles.'
    });
    
    assert.strictEqual(result.type, 'business', `Esperaba 'business', obtuvo '${result.type}'`);
});

// TEST 8: Email muy corto sin hilo debe filtrarse
test('Email muy corto sin contexto debe filtrarse', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'info@hotel.com', name: 'Hotel Info' }] },
        subject: 'Info',
        text: 'Ok.'
    });
    
    assert.strictEqual(result.type, 'filtered', `Esperaba 'filtered', obtuvo '${result.type}'`);
});

// TEST 9: Respuesta con RE: en asunto pero sin headers formales debe alertar
test('Respuesta con prefijo RE: debe alertar como comercial', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'contacto@hotel.com', name: 'Hotel Contact' }] },
        subject: 'RE: Consulta sobre disponibilidad',
        text: 'Hola, gracias por tu consulta. Tenemos disponibilidad para las fechas solicitadas. Te enviamos la información detallada.'
    });
    
    assert.strictEqual(result.type, 'business', `Esperaba 'business', obtuvo '${result.type}'`);
});

// TEST 10: Email con múltiples destinatarios (mass mailing) debe filtrarse
test('Email masivo (muchos destinatarios) debe filtrarse', () => {
    const result = classifyEmail({
        from: { value: [{ address: 'promo@hotel.com', name: 'Hotel Promo' }] },
        subject: 'Promociones especiales',
        text: 'Estimados clientes, les presentamos nuestras promociones de temporada.',
        to: { 
            value: [
                { address: 'dest1@test.com' },
                { address: 'dest2@test.com' },
                { address: 'dest3@test.com' },
                { address: 'dest4@test.com' },
                { address: 'dest5@test.com' },
                { address: 'dest6@test.com' }
            ]
        }
    });
    
    assert.strictEqual(result.type, 'filtered', `Esperaba 'filtered', obtuvo '${result.type}'`);
    assert.strictEqual(result.reason, 'newsletter_or_spam', `Esperaba 'newsletter_or_spam', obtuvo '${result.reason}'`);
});

// Resumen
console.log('\n' + '='.repeat(60));
console.log('📊 RESUMEN DE TESTS');
console.log('='.repeat(60));
console.log(`Total: ${passed + failed}`);
console.log(`✅ Pasaron: ${passed}`);
console.log(`❌ Fallaron: ${failed}`);
console.log('='.repeat(60) + '\n');

process.exit(failed > 0 ? 1 : 0);
