#!/usr/bin/env node
/**
 * Tests para verificación de señales fuertes de reserva
 * Cubre casos de emails sin headers de respuesta formal pero con contenido de movimiento de reserva
 */

const assert = require('assert');

console.log('🧪 Tests de señales de reserva (emails sin In-Reply-To/References)\n');

// Mock de parsed email y routing para tests
function createMockParsed(subject, text, hasReplyHeaders = false) {
    return {
        subject,
        text,
        inReplyTo: hasReplyHeaders ? '<some-message-id@example.com>' : null,
        references: hasReplyHeaders ? ['<some-message-id@example.com>'] : null
    };
}

function createMockInfo(text, from) {
    return {
        text,
        from,
        fromName: from.split('@')[0],
        subject: ''
    };
}

function createMockRouting(isInternal = false) {
    return {
        type: isInternal ? 'internal' : 'hotel'
    };
}

// Copiar funciones del monitor.js para testing aislado
function hasStrongReservationSignals(parsed, info, routing) {
    // SIEMPRE filtrar remitentes internos, sin importar las señales
    if (routing.type === 'internal') {
        return { 
            hasSignals: false, 
            reason: 'weak_signals',
            details: 'Remitente interno (siempre filtrado)'
        };
    }
    
    // Si es respuesta formal, aceptar sin más verificaciones
    const isReply = Boolean(parsed.inReplyTo || (parsed.references && parsed.references.length > 0));
    if (isReply) {
        return { hasSignals: true, reason: 'is_formal_reply' };
    }
    
    const subject = (parsed.subject || '').toLowerCase();
    const combined = `${subject} ${info.text}`.toLowerCase();
    
    // Señal 1: Asunto empieza con RE: o RV: (respuesta sin headers técnicos)
    const hasReplyPrefix = /^(re|rv|fwd|fw):/i.test(subject);
    if (hasReplyPrefix) {
        return { hasSignals: true, reason: 'subject_reply_prefix' };
    }
    
    // Señal 2: Palabras clave fuertes de acción sobre reserva existente
    const strongActionKeywords = [
        'confirmamos', 'confirmó', 'confirmo',
        'modificación', 'modificacion', 'modificamos', 'modificado',
        'anulación', 'anulacion', 'anulamos', 'anulado', 'anulada',
        'cancelación', 'cancelacion', 'cancelamos', 'cancelado', 'cancelada',
        'procedemos a', 'queda anulad', 'queda cancelad'
    ];
    const hasStrongAction = strongActionKeywords.some(kw => combined.includes(kw));
    
    // Señal 3: Código de reserva presente con CONTEXTO
    // Para evitar falsos positivos, el código debe estar cerca de palabras relacionadas con reservas
    const codeWithContextPattern = 
        // Códigos alfanuméricos cerca de palabras clave
        /(?:reserva|código|codigo|code|localizador|voucher|confirmación|modificación|anulación)\s*[:#]?\s*[A-Z]{1,2}[A-Z0-9]{4,6}\b/i.test(combined) ||
        // O en el asunto después de un espacio/guión (ej: "ANULAR RESERVA Hotel Huilo-Huilo 598854662")
        /(?:reserva|hotel|modificar|anular|cancelar)[\s\-]+[\w\s\-]+\d{8,9}\b/i.test(combined) ||
        // Códigos numéricos largos con contexto explícito
        /(?:reserva|código|codigo|n[°º]|#)\s*:?\s*#?\s*\d{8,9}\b/i.test(combined);
    
    const hasReservationCode = codeWithContextPattern;
    
    // Si tiene acción fuerte Y código con contexto, es señal fuerte
    // (2 señales sustanciales, no solo "es externo")
    if (hasStrongAction && hasReservationCode) {
        return { 
            hasSignals: true, 
            reason: 'strong_signals',
            details: 'Acción confirmada + código de reserva'
        };
    }
    
    return { 
        hasSignals: false, 
        reason: 'weak_signals',
        details: `Señales insuficientes: action=${hasStrongAction}, code=${hasReservationCode}`
    };
}

// Tests
const testCases = [
    {
        nombre: 'Mail nuevo de hotel CON modificación (sin In-Reply-To) → DEBE NOTIFICARSE',
        parsed: createMockParsed(
            'Nueva Reserva Termas de Huife - Checkin24hs',
            'Modificación fechas pax David Glass. In 26/11/2026 Out 28/11/2026 Suite Canelo',
            false // SIN headers de respuesta
        ),
        info: createMockInfo(
            'Modificación fechas pax David Glass. In 26/11/2026 Out 28/11/2026 Suite Canelo',
            'administracion@termashuife.cl'
        ),
        routing: createMockRouting(false),
        debeAceptar: true,
        razonEsperada: 'strong_signals'
    },
    {
        nombre: 'Mail de hotel CON confirmación y código (sin In-Reply-To) → DEBE NOTIFICARSE',
        parsed: createMockParsed(
            'Reserva Hotel Puyehue',
            'Confirmamos la reserva para el huésped Juan Pérez. Código: V2K67A',
            false
        ),
        info: createMockInfo(
            'Confirmamos la reserva para el huésped Juan Pérez. Código: V2K67A',
            'reservas@puyehue.cl'
        ),
        routing: createMockRouting(false),
        debeAceptar: true,
        razonEsperada: 'strong_signals'
    },
    {
        nombre: 'Mail con RE: en asunto (sin headers formales) → DEBE NOTIFICARSE',
        parsed: createMockParsed(
            'RE: Nueva Reserva Termas de Huife - Checkin24hs',
            'confirmamos la reserva para el huésped',
            false
        ),
        info: createMockInfo(
            'confirmamos la reserva para el huésped',
            'info@termashuife.cl'
        ),
        routing: createMockRouting(false),
        debeAceptar: true,
        razonEsperada: 'subject_reply_prefix'
    },
    {
        nombre: 'Respuesta formal con In-Reply-To → DEBE NOTIFICARSE',
        parsed: createMockParsed(
            'Re: Consulta reserva',
            'La reserva está confirmada',
            true // CON headers de respuesta
        ),
        info: createMockInfo(
            'La reserva está confirmada',
            'hotel@example.com'
        ),
        routing: createMockRouting(false),
        debeAceptar: true,
        razonEsperada: 'is_formal_reply'
    },
    {
        nombre: 'Newsletter SIN señales fuertes → DEBE FILTRARSE',
        parsed: createMockParsed(
            'Ofertas especiales de verano',
            'Aprovecha nuestras mejores tarifas para reservar tus vacaciones',
            false
        ),
        info: createMockInfo(
            'Aprovecha nuestras mejores tarifas para reservar tus vacaciones',
            'marketing@hotel.com'
        ),
        routing: createMockRouting(false),
        debeAceptar: false,
        razonEsperada: 'weak_signals'
    },
    {
        nombre: 'Email con palabra "reserva" pero sin acción fuerte → DEBE FILTRARSE',
        parsed: createMockParsed(
            'Información sobre reservas',
            'Para hacer una reserva, visite nuestro sitio web',
            false
        ),
        info: createMockInfo(
            'Para hacer una reserva, visite nuestro sitio web',
            'info@hotel.com'
        ),
        routing: createMockRouting(false),
        debeAceptar: false,
        razonEsperada: 'weak_signals'
    },
    {
        nombre: 'Email interno con modificación → DEBE FILTRARSE (interno)',
        parsed: createMockParsed(
            'Modificación interna',
            'Modificación de la reserva V2K67A confirmada',
            false
        ),
        info: createMockInfo(
            'Modificación de la reserva V2K67A confirmada',
            'german@checkin24hs.com'
        ),
        routing: createMockRouting(true), // Interno
        debeAceptar: false,
        razonEsperada: 'weak_signals' // No pasará por routing
    },
    {
        nombre: 'Anulación confirmada con código numérico largo → DEBE NOTIFICARSE',
        parsed: createMockParsed(
            'ANULAR RESERVA Hotel Huilo-Huilo 598854662',
            'Procedemos a anular la reserva según solicitado',
            false
        ),
        info: createMockInfo(
            'Procedemos a anular la reserva según solicitado',
            'ventas@huilohuilo.com'
        ),
        routing: createMockRouting(false),
        debeAceptar: true,
        razonEsperada: 'strong_signals'
    },
    {
        nombre: 'Cancelación sin código pero con acción fuerte → DEBE FILTRARSE (falta código)',
        parsed: createMockParsed(
            'Sobre tu reserva',
            'Lamentamos informar que cancelamos el servicio',
            false
        ),
        info: createMockInfo(
            'Lamentamos informar que cancelamos el servicio',
            'hotel@example.com'
        ),
        routing: createMockRouting(false),
        debeAceptar: false,
        razonEsperada: 'weak_signals'
    }
];

// Ejecutar tests
let pasaron = 0;
let fallaron = 0;

testCases.forEach((test, i) => {
    const resultado = hasStrongReservationSignals(test.parsed, test.info, test.routing);
    const aceptado = resultado.hasSignals;
    
    console.log(`Test ${i + 1}: ${test.nombre}`);
    console.log(`   Asunto: "${test.parsed.subject}"`);
    console.log(`   De: ${test.info.from}`);
    console.log(`   Tiene In-Reply-To: ${Boolean(test.parsed.inReplyTo)}`);
    console.log(`   Resultado: ${aceptado ? '✅ ACEPTADO' : '🔍 FILTRADO'}`);
    console.log(`   Razón: ${resultado.reason}${resultado.details ? ' (' + resultado.details + ')' : ''}`);
    console.log(`   Esperado: ${test.debeAceptar ? '✅ ACEPTAR' : '🔍 FILTRAR'} (razón: ${test.razonEsperada})`);
    
    const exito = (aceptado === test.debeAceptar) && 
                  (resultado.reason === test.razonEsperada || !test.debeAceptar);
    
    if (exito) {
        console.log(`   ✅ PASÓ\n`);
        pasaron++;
    } else {
        console.log(`   ❌ FALLÓ (esperaba ${test.razonEsperada}, obtuvo ${resultado.reason})\n`);
        fallaron++;
    }
});

console.log('='.repeat(70));
console.log(`Resultados: ${pasaron}/${testCases.length} tests pasaron`);
console.log('='.repeat(70) + '\n');

if (fallaron > 0) {
    process.exit(1);
}

console.log('✅ Todos los tests de señales de reserva pasaron!\n');
