/**
 * Script para verificar el estado de los servidores WhatsApp
 * Uso: node verificar_servidores_whatsapp.js
 */

const servidores = [
    { nombre: 'API 1', url: 'https://api1.checkin24hs.com', instancia: 1 },
    { nombre: 'API 2', url: 'https://api2.checkin24hs.com', instancia: 2 },
    { nombre: 'API 3', url: 'https://api3.checkin24hs.com', instancia: 3 },
    { nombre: 'API 4', url: 'https://api4.checkin24hs.com', instancia: 4 }
];

const colores = {
    reset: '\x1b[0m',
    verde: '\x1b[32m',
    rojo: '\x1b[31m',
    amarillo: '\x1b[33m',
    azul: '\x1b[34m',
    cyan: '\x1b[36m'
};

async function verificarEndpoint(url, timeout = 10000) {
    const inicio = Date.now();
    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeout);
        
        const response = await fetch(url, {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        const tiempo = Date.now() - inicio;
        
        const contentType = response.headers.get('content-type') || '';
        const esJson = contentType.includes('application/json');
        
        let data = null;
        try {
            data = esJson ? await response.json() : await response.text();
        } catch (e) {
            data = `Error parseando: ${e.message}`;
        }
        
        return {
            ok: true,
            status: response.status,
            statusText: response.statusText,
            tiempo,
            contentType,
            data
        };
    } catch (error) {
        const tiempo = Date.now() - inicio;
        return {
            ok: false,
            error: error.message,
            tiempo
        };
    }
}

async function verificarServidor(servidor) {
    console.log(`\n${colores.cyan}═══════════════════════════════════════════${colores.reset}`);
    console.log(`${colores.azul}📱 Verificando ${servidor.nombre}${colores.reset}`);
    console.log(`${colores.cyan}URL: ${servidor.url}${colores.reset}`);
    console.log(`${colores.cyan}═══════════════════════════════════════════${colores.reset}\n`);
    
    const resultados = {
        servidor: servidor.nombre,
        url: servidor.url,
        instancia: servidor.instancia,
        endpoints: {},
        errores: []
    };
    
    // Verificar endpoint raíz
    console.log(`  🔍 Verificando / ...`);
    const raiz = await verificarEndpoint(servidor.url + '/');
    resultados.endpoints.raiz = raiz;
    if (raiz.ok) {
        console.log(`     ${colores.verde}✅ Status: ${raiz.status}${colores.reset} (${raiz.tiempo}ms)`);
    } else {
        console.log(`     ${colores.rojo}❌ Error: ${raiz.error}${colores.reset}`);
        resultados.errores.push(`Error en /: ${raiz.error}`);
    }
    
    // Verificar /api/status
    console.log(`  🔍 Verificando /api/status ...`);
    const status = await verificarEndpoint(servidor.url + '/api/status');
    resultados.endpoints.status = status;
    if (status.ok) {
        console.log(`     ${colores.verde}✅ Status: ${status.status}${colores.reset} (${status.tiempo}ms)`);
        if (status.data && typeof status.data === 'object') {
            console.log(`     📊 Estado WhatsApp: ${status.data.status || 'N/A'}`);
            if (status.data.phone) console.log(`     📱 Teléfono: ${status.data.phone}`);
            if (status.data.name) console.log(`     👤 Nombre: ${status.data.name}`);
        }
    } else {
        console.log(`     ${colores.rojo}❌ Error: ${status.error}${colores.reset}`);
        resultados.errores.push(`Error en /api/status: ${status.error}`);
    }
    
    // Verificar /api/qr
    console.log(`  🔍 Verificando /api/qr ...`);
    const qr = await verificarEndpoint(servidor.url + '/api/qr');
    resultados.endpoints.qr = qr;
    if (qr.ok) {
        console.log(`     ${colores.verde}✅ Status: ${qr.status}${colores.reset} (${qr.tiempo}ms)`);
        if (qr.data && typeof qr.data === 'object') {
            console.log(`     📊 Estado: ${qr.data.status || 'N/A'}`);
            console.log(`     🔲 QR disponible: ${qr.data.qr ? 'Sí' : 'No'}`);
        }
    } else {
        console.log(`     ${colores.rojo}❌ Error: ${qr.error}${colores.reset}`);
        resultados.errores.push(`Error en /api/qr: ${qr.error}`);
    }
    
    // Verificar /api/health (opcional)
    console.log(`  🔍 Verificando /api/health ...`);
    const health = await verificarEndpoint(servidor.url + '/api/health');
    resultados.endpoints.health = health;
    if (health.ok) {
        console.log(`     ${colores.verde}✅ Status: ${health.status}${colores.reset} (${health.tiempo}ms)`);
    } else {
        console.log(`     ${colores.amarillo}⚠️  No disponible o error: ${health.error}${colores.reset}`);
    }
    
    // Resumen del servidor
    const endpointsExitosos = Object.values(resultados.endpoints).filter(e => e.ok).length;
    const totalEndpoints = Object.keys(resultados.endpoints).length;
    
    console.log(`\n  ${colores.cyan}📊 Resumen:${colores.reset}`);
    console.log(`     Endpoints exitosos: ${colores.verde}${endpointsExitosos}/${totalEndpoints}${colores.reset}`);
    
    if (resultados.errores.length > 0) {
        console.log(`     ${colores.rojo}❌ Errores encontrados: ${resultados.errores.length}${colores.reset}`);
    } else {
        console.log(`     ${colores.verde}✅ Sin errores${colores.reset}`);
    }
    
    return resultados;
}

async function verificarTodos() {
    console.log(`${colores.cyan}
╔══════════════════════════════════════════════════════════════╗
║   📱 VERIFICACIÓN DE SERVIDORES WHATSAPP - CHECKIN24HS      ║
╚══════════════════════════════════════════════════════════════╝
${colores.reset}`);
    
    const resultados = [];
    const tiempos = [];
    
    for (const servidor of servidores) {
        const inicio = Date.now();
        const resultado = await verificarServidor(servidor);
        const tiempoTotal = Date.now() - inicio;
        resultado.tiempoTotal = tiempoTotal;
        resultados.push(resultado);
        tiempos.push(tiempoTotal);
        
        // Pequeña pausa entre servidores
        await new Promise(resolve => setTimeout(resolve, 500));
    }
    
    // Resumen final
    console.log(`\n\n${colores.cyan}╔══════════════════════════════════════════════════════════════╗${colores.reset}`);
    console.log(`${colores.cyan}║                    📊 RESUMEN FINAL                           ║${colores.reset}`);
    console.log(`${colores.cyan}╚══════════════════════════════════════════════════════════════╝${colores.reset}\n`);
    
    resultados.forEach(resultado => {
        const estado = resultado.errores.length === 0 ? 
            `${colores.verde}✅ ONLINE${colores.reset}` : 
            `${colores.rojo}❌ ERRORES${colores.reset}`;
        
        console.log(`  ${resultado.servidor.padEnd(10)} | ${estado.padEnd(20)} | ${resultado.tiempoTotal}ms`);
    });
    
    const servidoresOnline = resultados.filter(r => r.errores.length === 0).length;
    const servidoresOffline = resultados.length - servidoresOnline;
    const tiempoPromedio = Math.round(tiempos.reduce((a, b) => a + b, 0) / tiempos.length);
    
    console.log(`\n  ${colores.cyan}Estadísticas:${colores.reset}`);
    console.log(`     Total servidores: ${resultados.length}`);
    console.log(`     ${colores.verde}Online: ${servidoresOnline}${colores.reset}`);
    console.log(`     ${colores.rojo}Con errores: ${servidoresOffline}${colores.reset}`);
    console.log(`     Tiempo promedio: ${tiempoPromedio}ms`);
    
    // Retornar código de salida apropiado
    if (servidoresOffline > 0) {
        process.exit(1);
    } else {
        process.exit(0);
    }
}

// Verificar si fetch está disponible (Node 18+)
if (typeof fetch === 'undefined') {
    console.error('❌ Este script requiere Node.js 18+ o instalar node-fetch');
    console.log('   Instala: npm install node-fetch');
    process.exit(1);
}

// Ejecutar verificación
verificarTodos().catch(error => {
    console.error(`${colores.rojo}❌ Error fatal:${colores.reset}`, error);
    process.exit(1);
});
