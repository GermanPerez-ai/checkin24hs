const assert = require('assert');
const { parseHuiloConfirmation } = require('./huilo-parse');
const { extractHuiloCodes, isCancelIntent } = require('./huilo-group-reservations');

const conf = `Confirmación de reserva
Nombre: Ivana Aubone
Alojamiento: Nothofagus
Número de confirmación: 598598227
Pasajeros: 2 adultos
Categoría de habitación: Estándar
Tipo de habitación: Cama matrimonial
Plan de alimentación: Pensión completa
Fechas: In: 08/08/2026 Out: 09/08/2026
Tarifa final a pagar: USD 340`;

const p = parseHuiloConfirmation({ from: 'whatsapp', subject: 'Confirmación', text: conf });
assert.ok(p);
assert.strictEqual(p.reservation_code, '598598227');
assert.strictEqual(p.check_in, '2026-08-08');
assert.strictEqual(p.check_out, '2026-08-09');

const mod = `Confirmación de reserva
Nombre: Pilar Martínez Cavallo
Alojamiento: Nawelpi Lodge
Número de confirmación: 595946981 y 595947028
Pasajeros: 4 adultos
Fechas: IN: 12/11/26 - OUT: 15/11/26
Tarifa final a pagar: USD 2.760`;
const p2 = parseHuiloConfirmation({ from: 'whatsapp', subject: 'Confirmación', text: mod });
assert.ok(p2, 'mod confirmation should parse');
assert.ok(String(p2.reservation_code).includes('595946981'));
assert.strictEqual(p2.check_in, '2026-11-12');
assert.strictEqual(p2.check_out, '2026-11-15');

const cancelText = 'holis oki, anulada';
const quoted = 'Número de confirmación: 598127293';
assert.ok(isCancelIntent(cancelText));
assert.deepStrictEqual(extractHuiloCodes(cancelText + '\n' + quoted), ['598127293']);
assert.deepStrictEqual(extractHuiloCodes('DNI 23999344 y reserva 598598227'), ['598598227']);

console.log('OK huilo group tests');
