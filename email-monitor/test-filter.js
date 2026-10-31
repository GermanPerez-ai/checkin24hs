#!/usr/bin/env node
/**
 * Tests de ejemplo con correos reales simulados
 */

const assert = require('assert');

console.log('🧪 Tests con ejemplos de correos simulados\n');

// Simulación de correos
const ejemplos = [
    {
        nombre: 'Confirmación de reserva',
        subject: 'Re: Reserva Hotel Puyehue #VK5LDY',
        from: 'reservas@puyehue.cl',
        text: 'Estimados, confirmamos la reserva a nombre de Juan Pérez.\nCheck-in: 15/03/2024\nCheck-out: 17/03/2024',
        deberiaDetectar: true
    },
    {
        nombre: 'Modificación de fechas',
        subject: 'Re: MODIFICAR RESERVA Huilo Huilo 600363973',
        from: 'ventas@huilohuilo.com',
        text: 'Confirmamos la modificación de fechas.\nNuevas fechas: 20-22 marzo',
        deberiaDetectar: true
    },
    {
        nombre: 'Anulación',
        subject: 'Re: ANULAR RESERVA Corralco #2602640',
        from: 'reservas@corralco.com',
        text: 'Confirmamos la anulación de la reserva.\nNo se aplicarán cargos.',
        deberiaDetectar: true
    },
    {
        nombre: 'Voucher',
        subject: 'Re: Envío de voucher',
        from: 'admin@aguascalientes.cl',
        text: 'Adjunto el voucher solicitado',
        deberiaDetectar: true
    },
    {
        nombre: 'Consulta de cupo',
        subject: 'Re: Consulta disponibilidad',
        from: 'reservas@hotel.com',
        text: 'Tenemos cupo disponible para las fechas consultadas',
        deberiaDetectar: true
    },
    {
        nombre: 'Newsletter (no relacionado)',
        subject: 'Ofertas de verano',
        from: 'marketing@hotel.com',
        text: 'Aprovecha nuestras ofertas especiales',
        deberiaDetectar: false
    },
    {
        nombre: 'Spam (no relacionado)',
        subject: 'Gana un premio',
        from: 'spam@ejemplo.com',
        text: 'Has ganado un premio increíble',
        deberiaDetectar: false
    }
];

// Función simplificada de detección (copiada del monitor.js)
function detectarReserva(email) {
    const keywords = [
        'reserva', 'modificación', 'modificacion', 'anulación', 'anulacion',
        'cancelación', 'cancelacion', 'voucher', 'cupo', 'confirmación', 'confirmacion'
    ];
    
    const combined = `${email.subject} ${email.text}`.toLowerCase();
    return keywords.some(k => combined.includes(k));
}

// Ejecutar tests
let pasaron = 0;
let fallaron = 0;

ejemplos.forEach((ejemplo, i) => {
    const resultado = detectarReserva(ejemplo);
    const esperado = ejemplo.deberiaDetectar;
    
    console.log(`Test ${i + 1}: ${ejemplo.nombre}`);
    console.log(`   Asunto: ${ejemplo.subject}`);
    console.log(`   De: ${ejemplo.from}`);
    console.log(`   Resultado: ${resultado ? '✅ Detectado' : '🔍 Filtrado'}`);
    console.log(`   Esperado: ${esperado ? '✅ Detectar' : '🔍 Filtrar'}`);
    
    if (resultado === esperado) {
        console.log(`   ✅ PASÓ\n`);
        pasaron++;
    } else {
        console.log(`   ❌ FALLÓ\n`);
        fallaron++;
    }
});

console.log('='.repeat(60));
console.log(`Resultados: ${pasaron}/${ejemplos.length} tests pasaron`);
console.log('='.repeat(60) + '\n');

if (fallaron > 0) {
    process.exit(1);
}

console.log('✅ Todos los tests de filtrado pasaron!\n');
