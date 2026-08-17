#!/usr/bin/env node
const assert = require('assert');
const { parseHuiloConfirmation, parseHuiloDate } = require('./parse-huilo');

assert.strictEqual(parseHuiloDate('04-noviembre-2026'), '2026-11-04');
assert.strictEqual(parseHuiloDate('06-11-26'), '2026-11-06');
assert.strictEqual(parseHuiloDate('09-11-26'), '2026-11-09');
assert.strictEqual(parseHuiloDate('03-feb-27'), '2027-02-03');
assert.strictEqual(parseHuiloDate('16-07', '2026-05-22'), '2026-07-16');

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

const htmlTable = `
<html><body><table>
<tr><td>Nombre</td><td>Adriana Carpineti</td></tr>
<tr><td>Número de confirmación</td><td>597003333</td></tr>
<tr><td>Pasajeros</td><td>1 adulto</td></tr>
<tr><td>Fechas</td><td>In: 03-diciembre-2026 Out: 06-diciembre-2026</td></tr>
<tr><td>Tarifa final a pagar</td><td>USD 900</td></tr>
</table></body></html>
`;
const p3 = parseHuiloConfirmation({
  from: 'paz.galvez@huilohuilo.com',
  subject: 'Confirmación Adriana Carpineti',
  text: 'Ver HTML',
  html: htmlTable,
});
assert.ok(p3, 'tabla HTML debe parsear');
assert.strictEqual(p3.reservation_code, '597003333');
assert.strictEqual(p3.client_name, 'Adriana Carpineti');
assert.strictEqual(p3.check_in, '2026-12-03');
assert.strictEqual(p3.check_out, '2026-12-06');

const htmlStacked = `
<table>
<tr><td>Nombre</td></tr><tr><td>agencia Caupolican</td></tr>
<tr><td>Número de confirmación</td></tr><tr><td>597002222</td></tr>
<tr><td>In</td></tr><tr><td>21-10-26</td></tr>
<tr><td>Out</td></tr><tr><td>24-10-26</td></tr>
<tr><td>Tarifa final a pagar</td></tr><tr><td>USD 1500</td></tr>
</table>
`;
const p4 = parseHuiloConfirmation({
  from: 'paz.galvez@huilohuilo.com',
  subject: 'Confirmación agencia Caupolican',
  html: htmlStacked,
});
assert.ok(p4, 'filas apiladas deben parsear');
assert.strictEqual(p4.reservation_code, '597002222');
assert.strictEqual(p4.client_name, 'agencia Caupolican');
assert.strictEqual(p4.check_in, '2026-10-21');
assert.strictEqual(p4.check_out, '2026-10-24');

console.log('OK parse-huilo tests');
