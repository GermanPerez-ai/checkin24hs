#!/usr/bin/env node
/**
 * Tests para el parser y filtro de correos
 */

const assert = require('assert');
const { isReservationRelated, cleanEmailText, extractEmailInfo } = require('./monitor');

console.log('🧪 Ejecutando tests del parser...\n');

// Test 1: Detectar correos relacionados con reservas
console.log('Test 1: Detectar correos relacionados con reservas');

const reservationEmail = {
    subject: 'Re: Consulta de reserva Hotel Puyehue',
    text: 'Confirmamos la modificación de fechas para la reserva',
    inReplyTo: '<original@example.com>',
    references: ['<original@example.com>']
};

const result1 = isReservationRelated(reservationEmail);
assert.ok(result1.isRelated, 'Debería detectar correo relacionado con reservas');
assert.ok(result1.isReply, 'Debería detectar que es una respuesta');

console.log('   ✅ Detecta correos de reservas correctamente\n');

// Test 2: Filtrar correos no relacionados
console.log('Test 2: Filtrar correos no relacionados');

const spamEmail = {
    subject: 'Oferta especial de marketing',
    text: 'Compre ahora con descuento',
    inReplyTo: null,
    references: []
};

const result2 = isReservationRelated(spamEmail);
assert.strictEqual(result2, false, 'Debería filtrar correos no relacionados');

console.log('   ✅ Filtra spam correctamente\n');

// Test 3: Detectar palabras clave (modificación)
console.log('Test 3: Detectar palabras clave');

const modificationEmail = {
    subject: 'Modificación de reserva',
    text: 'Hemos procesado tu solicitud',
    inReplyTo: '<original@example.com>'
};

const result3 = isReservationRelated(modificationEmail);
assert.ok(result3.isRelated, 'Debería detectar "modificación"');

console.log('   ✅ Detecta palabras clave correctamente\n');

// Test 4: Detectar cancelaciones/anulaciones
console.log('Test 4: Detectar cancelaciones');

const cancellationEmail = {
    subject: 'Re: Anulación de reserva #12345',
    text: 'Confirmamos la anulación',
    inReplyTo: '<original@example.com>'
};

const result4 = isReservationRelated(cancellationEmail);
assert.ok(result4.isRelated, 'Debería detectar "anulación"');

console.log('   ✅ Detecta cancelaciones correctamente\n');

// Test 5: Limpiar texto (remover citas)
console.log('Test 5: Limpiar texto de correo');

const dirtyText = `Confirmamos la reserva para el 15 de marzo.

Saludos,
Hotel Manager

--
Firma del hotel

> El 10/03/2024, usuario@example.com escribió:
> Quiero hacer una reserva`;

const cleaned = cleanEmailText(dirtyText);
assert.ok(!cleaned.includes('escribió:'), 'Debería remover citas');
assert.ok(!cleaned.includes('Firma del hotel'), 'Debería remover firmas');
assert.ok(cleaned.includes('Confirmamos la reserva'), 'Debería mantener contenido principal');

console.log('   ✅ Limpia texto correctamente\n');

// Test 6: Extraer información del correo
console.log('Test 6: Extraer información del correo');

const parsedEmail = {
    messageId: '<test123@example.com>',
    subject: 'Re: Reserva Hotel XYZ',
    text: 'Confirmamos su reserva',
    from: {
        value: [{
            name: 'Hotel XYZ',
            address: 'reservas@hotelxyz.com'
        }]
    },
    date: new Date()
};

const info = extractEmailInfo(parsedEmail);
assert.strictEqual(info.messageId, '<test123@example.com>');
assert.strictEqual(info.from, 'reservas@hotelxyz.com');
assert.strictEqual(info.fromName, 'Hotel XYZ');
assert.strictEqual(info.subject, 'Re: Reserva Hotel XYZ');

console.log('   ✅ Extrae información correctamente\n');

// Test 7: Casos especiales (acentos y variaciones)
console.log('Test 7: Casos especiales');

const accentEmail = {
    subject: 'Confirmacion de reserva',
    text: 'Todo ok',
    inReplyTo: '<original@example.com>'
};

const result7 = isReservationRelated(accentEmail);
assert.ok(result7.isRelated, 'Debería detectar "confirmacion" sin tilde');

console.log('   ✅ Maneja acentos correctamente\n');

// Test 8: Vouchers y cupos
console.log('Test 8: Vouchers y cupos');

const voucherEmail = {
    subject: 'Envío de voucher',
    text: 'Adjunto el voucher',
    inReplyTo: '<original@example.com>'
};

const result8 = isReservationRelated(voucherEmail);
assert.ok(result8.isRelated, 'Debería detectar "voucher"');

const cupoEmail = {
    subject: 'Re: Consulta de cupo',
    text: 'Tenemos disponibilidad',
    inReplyTo: '<original@example.com>'
};

const result9 = isReservationRelated(cupoEmail);
assert.ok(result9.isRelated, 'Debería detectar "cupo"');

console.log('   ✅ Detecta vouchers y cupos correctamente\n');

console.log('✅ Todos los tests pasaron correctamente!\n');
