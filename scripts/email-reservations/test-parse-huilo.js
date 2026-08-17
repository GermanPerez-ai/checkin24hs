#!/usr/bin/env node
const assert = require('assert');
const { parseHuiloConfirmation, parseHuiloDate } = require('./parse-huilo');

assert.strictEqual(parseHuiloDate('04-noviembre-2026'), '2026-11-04');
assert.strictEqual(parseHuiloDate('06-11-26'), '2026-11-06');
assert.strictEqual(parseHuiloDate('09-11-26'), '2026-11-09');

const sample1 = `
Estimados, Envío confirmación de reserva según lo solicitado.
Confirmación de reserva
Nombre: Mariana Carla Peralta
Alojamiento: Nothofagus
Número de confirmación: 599088009
Pasajeros: 2 adultos + 01 niño
Categoría de habitación: Estándar Triple
Tipo de habitación: Cama mat + individual
Plan de alimentación: Pensión completa
Traslados: Si __ No_x_
Fechas: In: 04-noviembre-2026 Out: 07-noviembre-2026
Tarifa final a pagar: USD 1200
`;

const p1 = parseHuiloConfirmation({
  from: 'paz.galvez@huilohuilo.com',
  subject: 'Confirmación Mariana Carla Peralta',
  text: sample1,
});

assert.ok(p1, 'sample1 debe parsear');
assert.strictEqual(p1.reservation_code, '599088009');
assert.strictEqual(p1.client_name, 'Mariana Carla Peralta');
assert.strictEqual(p1.check_in, '2026-11-04');
assert.strictEqual(p1.check_out, '2026-11-07');
assert.strictEqual(p1.adults, 2);
assert.strictEqual(p1.children, 1);
assert.strictEqual(p1.total_amount, 1200);
assert.strictEqual(p1.currency, 'USD');

const sample2 = `
Confirmación de reserva
Nombre: Andrea Vejar
Alojamiento: Nothofagus
Número de confirmación: 598854662
Pasajeros: 1 adulto
Categoría de habitación: Estándar
Tipo de habitación: Matrimonial
Plan de alimentación: Pensión completa
Fechas: In: 06-11-26 Out: 09-11-26
Tarifa final a pagar: USD 600
`;

const p2 = parseHuiloConfirmation({
  from: 'paz.galvez@huilohuilo.com',
  subject: 'Confirmación Andrea Vejar',
  text: sample2,
});

assert.ok(p2);
assert.strictEqual(p2.reservation_code, '598854662');
assert.strictEqual(p2.client_name, 'Andrea Vejar');
assert.strictEqual(p2.check_in, '2026-11-06');
assert.strictEqual(p2.check_out, '2026-11-09');
assert.strictEqual(p2.adults, 1);
assert.strictEqual(p2.children, 0);
assert.strictEqual(p2.total_amount, 600);

console.log('OK parse-huilo tests');
