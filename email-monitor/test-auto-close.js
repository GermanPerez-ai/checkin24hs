#!/usr/bin/env node
/**
 * Tests para el auto-cierre de reservas
 * Valida la extracción de códigos y la detección de confirmaciones
 */

const assert = require('assert');
const { extractReservationCodes, detectConfirmation } = require('./monitor');

console.log('🧪 Ejecutando tests del auto-cierre de reservas...\n');

// ===== TESTS =====

// Test 1: Extraer código alfanumérico de Puyehue
console.log('Test 1: Extraer código alfanumérico (Puyehue VH6QHS)');
const subject1 = 'RE: ANULAR RESERVA Hotel Puyehue VH6QHS';
const body1 = 'Reservas canceladas según lo solicitado.';
const codes1 = extractReservationCodes(subject1, body1);
assert.ok(codes1.includes('VH6QHS'), `Debería extraer VH6QHS, obtuvo: ${codes1.join(', ')}`);
console.log('   ✅ Código VH6QHS extraído correctamente\n');

// Test 2: Extraer código numérico de Huilo Huilo
console.log('Test 2: Extraer código numérico (Huilo Huilo 598854662)');
const subject2 = 'RE: ANULAR RESERVA Hotel Huilo-Huilo 598854662';
const body2 = 'Procedemos a anular según lo solicitado. N° de cancelación: 600986202';
const codes2 = extractReservationCodes(subject2, body2);
assert.ok(codes2.includes('598854662'), `Debería extraer 598854662, obtuvo: ${codes2.join(', ')}`);
assert.ok(codes2.includes('600986202'), `Debería extraer 600986202, obtuvo: ${codes2.join(', ')}`);
console.log('   ✅ Códigos numéricos extraídos correctamente\n');

// Test 3: Extraer múltiples códigos de Tanica
console.log('Test 3: Extraer múltiples códigos (Tanica VG52SH, VX6KZM)');
const subject3 = 'RE: ANULAR RESERVA Tanica VG52SH';
const body3 = 'Dejaremos anulada la reserva. Reserva original VG52SH Reserva con descuento VX6KZM';
const codes3 = extractReservationCodes(subject3, body3);
assert.ok(codes3.includes('VG52SH'), `Debería extraer VG52SH, obtuvo: ${codes3.join(', ')}`);
assert.ok(codes3.includes('VX6KZM'), `Debería extraer VX6KZM, obtuvo: ${codes3.join(', ')}`);
console.log('   ✅ Múltiples códigos extraídos correctamente\n');

// Test 4: Detectar confirmación de Huilo Huilo
console.log('Test 4: Detectar confirmación de cancelación (Huilo Huilo)');
const text4 = 'Procedemos a anular según lo solicitado. N° de cancelación: 600986202';
const detection4 = detectConfirmation(text4, text4, subject2);
assert.ok(detection4, 'Debería detectar confirmación');
assert.strictEqual(detection4.action, 'cancelacion', 'Debería ser una cancelación');
assert.strictEqual(detection4.confidence, 'high', 'Debería tener alta confianza');
console.log('   ✅ Confirmación de cancelación detectada\n');

// Test 5: Detectar confirmación de Puyehue
console.log('Test 5: Detectar confirmación de cancelación (Puyehue)');
const text5 = 'Reservas canceladas';
const detection5 = detectConfirmation(text5, text5, subject1);
assert.ok(detection5, 'Debería detectar confirmación');
assert.strictEqual(detection5.action, 'cancelacion', 'Debería ser una cancelación');
console.log('   ✅ Confirmación simple detectada\n');

// Test 6: Detectar confirmación de Tanica
console.log('Test 6: Detectar confirmación de cancelación (Tanica)');
const text6 = 'Dejaremos anulada la reserva según solicitado.';
const detection6 = detectConfirmation(text6, text6, subject3);
assert.ok(detection6, 'Debería detectar confirmación');
assert.strictEqual(detection6.action, 'cancelacion', 'Debería ser una cancelación');
console.log('   ✅ Confirmación "dejaremos anulada" detectada\n');

// Test 7: NO detectar cuando hotel rechaza
console.log('Test 7: NO detectar cuando hotel no puede cancelar');
const subject7 = 'RE: ANULAR RESERVA Hotel Test';
const text7 = 'Lamentablemente el hotel no confirmó la cancelación, tiene cargo por cancelación.';
const detection7 = detectConfirmation(text7, text7, subject7);
assert.strictEqual(detection7, null, 'NO debería detectar confirmación cuando hay rechazo');
console.log('   ✅ Rechazo detectado correctamente (no se auto-cierra)\n');

// Test 8: Detectar modificación confirmada
console.log('Test 8: Detectar confirmación de modificación');
const subject8 = 'RE: MODIFICAR RESERVA Hotel Test V2K67A';
const text8 = 'Hemos modificado la reserva según las nuevas fechas solicitadas.';
const rawText8 = `Hola Mariano,

${text8}

Saludos,
Hotel

> El 01/11/2026, Mariano escribió:
> MODIFICAR RESERVA Hotel Test V2K67A`;
const detection8 = detectConfirmation(text8, rawText8, subject8);
assert.ok(detection8, 'Debería detectar confirmación de modificación');
assert.strictEqual(detection8.action, 'modificacion', 'Debería ser una modificación');
console.log('   ✅ Confirmación de modificación detectada\n');

// Test 9: NO detectar modificación sin contexto
console.log('Test 9: NO detectar modificación sin contexto de subject');
const subject9 = 'RE: Consulta Hotel Test';
const text9 = 'Hemos modificado los datos solicitados.';
const detection9 = detectConfirmation(text9, text9, subject9);
assert.strictEqual(detection9, null, 'NO debería detectar modificación sin "MODIFICAR RESERVA" en el thread');
console.log('   ✅ Falso positivo de modificación evitado\n');

// Test 10: Extraer código del thread citado
console.log('Test 10: Extraer código del thread citado');
const subject10 = 'RE: Consulta';
const body10 = `Reservas canceladas.

> El 01/11/2026 escribió:
> ANULAR RESERVA Hotel Corralco V3X98B`;
const codes10 = extractReservationCodes(subject10, body10);
assert.ok(codes10.includes('V3X98B'), `Debería extraer V3X98B del thread, obtuvo: ${codes10.join(', ')}`);
console.log('   ✅ Código extraído del thread citado\n');

// Test 11: NO detectar cuando hay penalidad
console.log('Test 11: NO detectar cuando menciona penalidad');
const subject11 = 'RE: ANULAR RESERVA Hotel Test';
const text11 = 'La reserva quedará anulada pero debe abonar una penalidad del 50%.';
const detection11 = detectConfirmation(text11, text11, subject11);
assert.strictEqual(detection11, null, 'NO debería detectar confirmación cuando hay penalidad');
console.log('   ✅ Penalidad detectada, no se auto-cierra\n');

// Test 12: Código con 2 letras iniciales
console.log('Test 12: Extraer código con 2 letras iniciales (VH6QHS)');
const subject12 = 'RE: Reserva VH6QHS';
const codes12 = extractReservationCodes(subject12, '');
assert.ok(codes12.includes('VH6QHS'), `Debería extraer VH6QHS, obtuvo: ${codes12.join(', ')}`);
console.log('   ✅ Código con 2 letras extraído\n');

// Test 13: Código con 1 letra inicial
console.log('Test 13: Extraer código con 1 letra inicial (V2K67A)');
const subject13 = 'RE: Reserva V2K67A';
const codes13 = extractReservationCodes(subject13, '');
assert.ok(codes13.includes('V2K67A'), `Debería extraer V2K67A, obtuvo: ${codes13.join(', ')}`);
console.log('   ✅ Código con 1 letra extraído\n');

console.log('✅ Todos los tests pasaron correctamente!\n');

console.log('📋 RESUMEN DE CASOS PROBADOS:');
console.log('   ✅ Extracción de códigos alfanuméricos (V2K67A, VH6QHS, VG52SH, VX6KZM)');
console.log('   ✅ Extracción de códigos numéricos (598854662, 600986202)');
console.log('   ✅ Extracción desde subject y body');
console.log('   ✅ Extracción desde threads citados');
console.log('   ✅ Detección de confirmación clara ("procedemos a anular", "canceladas", "anulada")');
console.log('   ✅ Detección de modificación con contexto');
console.log('   ✅ Rechazo cuando hotel no confirma');
console.log('   ✅ Rechazo cuando hay penalidad/cargo');
console.log('   ✅ Prevención de falsos positivos\n');
