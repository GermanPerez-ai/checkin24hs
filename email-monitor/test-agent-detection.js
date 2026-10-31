#!/usr/bin/env node
/**
 * Tests de detección de agentes
 * Verifica que la función detectAgent() identifique correctamente
 * a los agentes de Checkin24hs en los correos
 */

// Cargar las funciones del monitor (necesitamos simular el require)
require('dotenv').config();

// Configuración de agentes para tests
const testAgents = [
    { name: 'Mariano', aliases: ['mariano'] },
    { name: 'German', aliases: ['german', 'germán', 'german perez', 'germanperez'] },
    { name: 'Nazareno', aliases: ['nazareno', 'naza'] },
    { name: 'Axel', aliases: ['axel', 'axel bisio', 'axelbisio'] }
];

/**
 * Busca coincidencias de agentes en un texto dado
 */
function findAgentInText(text) {
    if (!text) return null;
    
    const textLower = text.toLowerCase();
    
    for (const agent of testAgents) {
        for (const alias of agent.aliases) {
            if (textLower.includes(alias)) {
                return agent.name;
            }
        }
    }
    
    return null;
}

/**
 * Detecta qué agente de Checkin24hs solicitó la reserva
 */
function detectAgent(rawText, parsed) {
    if (!rawText) return 'no identificado';
    
    const textLower = rawText.toLowerCase();
    
    // 1. PRIORIDAD: Buscar en el mensaje original citado / firma
    const quotedPatterns = [
        /(?:de|from):\s*([^\n]+)/gi,
        /(?:el|on)\s+[^\n]*?,\s*([^\n<]+?)(?:\s+escribió|wrote|schrieb)/gi,
        /^-{2,}\s*$/gm,
    ];
    
    for (const pattern of quotedPatterns) {
        const matches = textLower.matchAll(pattern);
        for (const match of matches) {
            const context = match[1] || textLower.slice(match.index, match.index + 200);
            const agent = findAgentInText(context);
            if (agent) return agent;
        }
    }
    
    // Buscar en firmas de email
    const emailMatches = textLower.match(/[\w.-]+@[\w.-]+\.\w+/g);
    if (emailMatches) {
        for (const email of emailMatches) {
            const agent = findAgentInText(email);
            if (agent) return agent;
        }
    }
    
    // 2. Buscar en saludos al inicio
    const firstLines = textLower.split('\n').slice(0, 5).join('\n');
    const greetingPatterns = [
        /(?:hola|estimado|estimada|querido|querida|buen\s+día|buenos\s+días)\s+([a-záéíóúñ]+)/gi,
        /([a-záéíóúñ]+)\s*,?\s*(?:como\s+estas|cómo\s+estás|buen\s+día)/gi
    ];
    
    for (const pattern of greetingPatterns) {
        const matches = firstLines.matchAll(pattern);
        for (const match of matches) {
            const name = match[1];
            const agent = findAgentInText(name);
            if (agent) return agent;
        }
    }
    
    // 3. Buscar en headers To/Cc
    const recipients = [];
    if (parsed.to && parsed.to.value) {
        recipients.push(...parsed.to.value.map(r => r.address || '').filter(Boolean));
    }
    if (parsed.cc && parsed.cc.value) {
        recipients.push(...parsed.cc.value.map(r => r.address || '').filter(Boolean));
    }
    
    for (const email of recipients) {
        const agent = findAgentInText(email.toLowerCase());
        if (agent) return agent;
    }
    
    return 'no identificado';
}

// ===== TESTS =====

console.log('🧪 Tests de detección de agentes\n');

const tests = [
    {
        name: 'Test 1: Saludo "Hola Mariano"',
        text: 'Hola Mariano, buen día!\n\nTe consulto sobre la reserva en Hotel Puyehue...',
        parsed: {},
        expected: 'Mariano'
    },
    {
        name: 'Test 2: Saludo "Hola German"',
        text: 'Hola German,\n\nNecesito modificar una reserva para el hotel...',
        parsed: {},
        expected: 'German'
    },
    {
        name: 'Test 3: Saludo "Hola Axel"',
        text: 'Hola Axel,\n\nTe escribo para consultar disponibilidad...',
        parsed: {},
        expected: 'Axel'
    },
    {
        name: 'Test 4: Saludo "Estimado Nazareno"',
        text: 'Estimado Nazareno,\n\nSolicito la cancelación de la reserva...',
        parsed: {},
        expected: 'Nazareno'
    },
    {
        name: 'Test 5: Alias "Naza"',
        text: 'Hola Naza, como estás?\n\nQuiero hacer una modificación...',
        parsed: {},
        expected: 'Nazareno'
    },
    {
        name: 'Test 6: En mensaje citado con "De:"',
        text: 'Confirmado.\n\nSaludos,\nHotel Puyehue\n\nDe: Mariano <mariano@checkin24hs.com>\nEnviado: lunes, 28 de octubre',
        parsed: {},
        expected: 'Mariano'
    },
    {
        name: 'Test 7: En firma con email axelbisio@hotmail.com',
        text: 'Confirmado.\n\n--\nHotel Manager\naxelbisio@hotmail.com',
        parsed: {},
        expected: 'Axel'
    },
    {
        name: 'Test 8: Nombre completo "German Perez"',
        text: 'Hola German Perez, buen día.\n\nConfirmamos su solicitud...',
        parsed: {},
        expected: 'German'
    },
    {
        name: 'Test 9: Alias "Germán" con acento',
        text: 'Hola Germán,\n\nLe confirmamos la modificación...',
        parsed: {},
        expected: 'German'
    },
    {
        name: 'Test 10: En header To',
        text: 'Confirmamos la modificación solicitada.',
        parsed: {
            to: {
                value: [
                    { address: 'mariano@checkin24hs.com' }
                ]
            }
        },
        expected: 'Mariano'
    },
    {
        name: 'Test 11: Sin coincidencia',
        text: 'Estimado cliente,\n\nConfirmamos su reserva...',
        parsed: {},
        expected: 'no identificado'
    },
    {
        name: 'Test 12: "German, como estas?"',
        text: 'German, como estas?\n\nNecesito ayuda con una reserva...',
        parsed: {},
        expected: 'German'
    },
    {
        name: 'Test 13: En mensaje citado con "El ... escribió:"',
        text: 'Confirmado.\n\nEl 28/10/2024, German Perez escribió:\n> Solicito modificación...',
        parsed: {},
        expected: 'German'
    }
];

let passed = 0;
let failed = 0;

tests.forEach(test => {
    const result = detectAgent(test.text, test.parsed);
    const success = result === test.expected;
    
    console.log(`${test.name}`);
    console.log(`   Resultado: ${result}`);
    console.log(`   Esperado: ${test.expected}`);
    console.log(`   ${success ? '✅ PASÓ' : '❌ FALLÓ'}\n`);
    
    if (success) {
        passed++;
    } else {
        failed++;
    }
});

console.log('='.repeat(60));
console.log(`Resultados: ${passed}/${tests.length} tests pasaron`);
console.log('='.repeat(60));

if (failed > 0) {
    console.log(`\n❌ ${failed} tests fallaron`);
    process.exit(1);
} else {
    console.log('\n✅ Todos los tests de detección de agentes pasaron!\n');
    process.exit(0);
}
