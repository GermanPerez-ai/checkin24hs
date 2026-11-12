#!/usr/bin/env node
/**
 * Tests portal Puyehue: por cada reserva llegan 2 mails (agencia + huésped).
 * Solo la copia de AGENCIA debe ir a WhatsApp, con Pasajero y Agente.
 */

const assert = require('assert');
const { parsePuyehuePortalEmail, isPuyehueGuestCopy } = require('./monitor');

console.log('🧪 Ejecutando tests del portal Puyehue...\n');

const SUBJECT = 'Confirmación de Reserva Hotel Puyehue VKUFZE';
const FROM = 'reservas@hotelpuyehue.cl';

const AGENCY_TEXT = `Gracias por completar su reserva en Puyehue.

Su código de reserva es VKUFZE.

Esta reserva para Hotel Termas de Puyehue
Hotel                Hotel Termas de Puyehue
Pasajeros            4 adultos + 1 infante
Check-in             sáb 05 diciembre, 2026
Check-out            mar 08 diciembre, 2026
TOTAL                US$ 2.625,00
Total neto (sin comisión IVA incluído)   US$ 2.625,00

Información de Contacto

Pasajero MARIA PRUEBA SANTOS
Agente     GERMAN PEREZ
Agencia Canopy Promociones
Email      reservas@tustermas.com
Teléfono +540000000000
País       Argentina

Políticas de Anulación
Toda anulación deberá ser solicitada indicando nombre del pasajero y código de reserva.
Es responsabilidad de la agencia comunicar por mail la anulación.`;

const GUEST_TEXT = `Gracias por completar su reserva.

Su código de reserva temporal es VKUFZE.

Esta reserva para Hotel Termas de Puyehue
Hotel                Hotel Termas de Puyehue
Pasajeros            4 adultos + 1 infante
TOTAL                US$ 2.625,00
----------------------------
Información de contacto

Contacto      MARIA PRUEBA SANTOS
Email         cliente@example.com
Teléfono      +54 9 000 0000000
País          Argentina
----------------------------

Condiciones Generales
Luego de generar la reserva, es responsabilidad exclusiva del huésped...`;

const info = (rawText, extra = {}) => ({ subject: SUBJECT, from: FROM, rawText, ...extra });

// Test 1: copia agencia (texto plano con columnas)
console.log('Test 1: copia agencia → se notifica con Pasajero y Agente');
const a = parsePuyehuePortalEmail(info(AGENCY_TEXT));
assert.strictEqual(a.kind, 'agency');
assert.strictEqual(a.code, 'VKUFZE');
assert.strictEqual(a.passenger, 'MARIA PRUEBA SANTOS');
assert.strictEqual(a.agent, 'GERMAN PEREZ');
assert.strictEqual(a.agency, 'Canopy Promociones');
assert.strictEqual(isPuyehueGuestCopy(a), false);
console.log('   ✅ OK\n');

// Test 2: copia huésped
console.log('Test 2: copia huésped → NO va a WhatsApp');
const g = parsePuyehuePortalEmail(info(GUEST_TEXT));
assert.strictEqual(g.kind, 'guest');
assert.strictEqual(g.code, 'VKUFZE');
assert.strictEqual(g.agent, '');
assert.strictEqual(isPuyehueGuestCopy(g), true);
console.log('   ✅ OK\n');

// Test 3: versiones HTML colapsadas en una sola línea (fallback extractTextFromHTML)
console.log('Test 3: HTML colapsado en una línea');
const collapse = t => t.replace(/\s+/g, ' ');
const a3 = parsePuyehuePortalEmail(info('', { }), { html: `<p>${collapse(AGENCY_TEXT)}</p>` });
assert.strictEqual(a3.kind, 'agency');
assert.strictEqual(a3.passenger, 'MARIA PRUEBA SANTOS');
assert.strictEqual(a3.agent, 'GERMAN PEREZ');
assert.strictEqual(a3.agency, 'Canopy Promociones');
const g3 = parsePuyehuePortalEmail(info(''), { html: `<p>${collapse(GUEST_TEXT)}</p>` });
assert.strictEqual(isPuyehueGuestCopy(g3), true);
console.log('   ✅ OK\n');

// Test 4: formato "Etiqueta\nValor" (tablas HTML convertidas por mailparser)
console.log('Test 4: etiqueta y valor en líneas separadas');
const stacked = AGENCY_TEXT.replace(/^(Pasajero|Agente|Agencia)\s+/gm, '$1\n');
const a4 = parsePuyehuePortalEmail(info(stacked));
assert.strictEqual(a4.kind, 'agency');
assert.strictEqual(a4.passenger, 'MARIA PRUEBA SANTOS');
assert.strictEqual(a4.agent, 'GERMAN PEREZ');
console.log('   ✅ OK\n');

// Test 5: nunca suprimir la de agencia aunque diga "temporal"
console.log('Test 5: si trae Agente nunca se omite');
const a5 = parsePuyehuePortalEmail(info(AGENCY_TEXT.replace('reserva es', 'reserva temporal es')));
assert.strictEqual(a5.kind, 'agency');
assert.strictEqual(isPuyehueGuestCopy(a5), false);
console.log('   ✅ OK\n');

// Test 6: "Reserva Web" no se omite (puede no tener copia de agencia)
console.log('Test 6: Reserva Web no se omite');
const w = parsePuyehuePortalEmail(info(GUEST_TEXT, { subject: 'Confirmación de Reserva Web Hotel Puyehue ABC123' }));
assert.strictEqual(w.kind, 'guest');
assert.strictEqual(w.isWeb, true);
assert.strictEqual(isPuyehueGuestCopy(w), false);
console.log('   ✅ OK\n');

// Test 7: otros hoteles / respuestas no se tocan
console.log('Test 7: mails que no son del portal → null');
assert.strictEqual(parsePuyehuePortalEmail({ subject: 'RE: ANULAR RESERVA Hotel Huilo-Huilo 598854662', from: 'reservas@huilohuilo.com', rawText: 'Anulada' }), null);
console.log('   ✅ OK\n');

console.log('✅ Todos los tests del portal Puyehue pasaron');
