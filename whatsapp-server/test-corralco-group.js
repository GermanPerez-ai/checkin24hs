const assert = require('assert');
const { parseCorralcoConfirmation, extractCorralcoCodes } = require('./corralco-parse');
const { isCancelIntent, isModificationIntent } = require('./corralco-group-reservations');

const conf = `Confirmación de reserva Corralco
Nombre: Juan Pérez
Número de reserva: 88776655
Check-in: 15/07/2026
Check-out: 18/07/2026
Total: CLP 450000`;

const p = parseCorralcoConfirmation({ from: 'reservas@corralco.com', subject: 'Confirmación', text: conf });
assert.ok(p);
assert.strictEqual(p.reservation_code, '88776655');
assert.strictEqual(p.check_in, '2026-07-15');
assert.strictEqual(p.check_out, '2026-07-18');
assert.strictEqual(p.hotel_key, 'corralco');

const loc = `Hotel Corralco
Localizador: CRC-12045
Huésped: María Gómez
Ingreso: 20/08/2026
Salida: 23/08/2026
Tarifa: USD 890`;
const p2 = parseCorralcoConfirmation({ from: 'paz@checkin24hs.com', subject: 'Fwd: Reserva Corralco', text: loc });
assert.ok(p2, 'localizador should parse');
assert.ok(String(p2.reservation_code).includes('12045') || String(p2.reservation_code).includes('CRC'));
assert.strictEqual(p2.check_in, '2026-08-20');

assert.ok(isCancelIntent('anulada esta'));
assert.ok(isModificationIntent('modificamos fechas'));
assert.deepStrictEqual(extractCorralcoCodes('anulada reserva 88776655'), ['88776655']);
assert.ok(extractCorralcoCodes('Localizador: CRC-12045').some((c) => /12045|CRC/i.test(c)));

assert.strictEqual(
  parseCorralcoConfirmation({ from: 'paz.galvez@huilohuilo.com', subject: 'Confirmación Huilo', text: 'Huilo' }),
  null
);

console.log('OK corralco group tests');
