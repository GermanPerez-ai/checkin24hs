const puppeteer = require('puppeteer');

class CotizadorPuyehue {
    constructor() {
        this.maxRetries = 3;
        this.retryDelay = 2000; // 2 segundos
    }

    async cotizarConReintentos(datosUsuario) {
        let lastError = null;
        
        for (let intento = 1; intento <= this.maxRetries; intento++) {
            try {
                console.log(`🔄 Intento ${intento} de ${this.maxRetries}`);
                return await this.ejecutarCotizacion(datosUsuario);
            } catch (error) {
                lastError = error;
                console.log(`❌ Error en intento ${intento}:`, error.message);
                
                if (intento < this.maxRetries) {
                    console.log(`⏳ Esperando ${this.retryDelay}ms antes del siguiente intento...`);
                    await this.delay(this.retryDelay);
                }
            }
        }
        
        // Si todos los intentos fallaron
        throw new Error('El portal está en mantenimiento. Por favor, contactar a un agente.');
    }

    async ejecutarCotizacion(datosUsuario) {
        const browser = await puppeteer.launch({
            headless: true,
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });

        try {
            const page = await browser.newPage();
            
            // Configurar timeout
            page.setDefaultTimeout(30000);
            page.setDefaultNavigationTimeout(30000);

            console.log('🌐 Navegando al portal de Puyehue...');
            await page.goto('https://reservas.puyehue.cl/cgi-bin/login_AG.cgi?RESORT=TANICA&option=logout');

            // Login automático
            console.log('🔑 Realizando login...');
            await page.waitForSelector('#usuario', { timeout: 10000 });
            await page.type('#usuario', 'canopypromo');
            await page.type('#clave', 'canopypromo');
            await page.click('#login-button');

            // Esperar a que cargue la página principal
            await page.waitForSelector('#fecha-checkin', { timeout: 15000 });

            // Cargar fecha automáticamente
            console.log('📅 Cargando fecha de check-in...');
            await page.click('#fecha-checkin');
            await this.seleccionarFecha(page, datosUsuario.fecha_checkin);

            // Completar formulario
            console.log('📝 Completando formulario...');
            await page.type('#noches', datosUsuario.noches.toString());
            await page.type('#adultos', datosUsuario.adultos.toString());
            await page.type('#ninos-5-11', datosUsuario.ninos_5_11.toString());
            await page.type('#infantes-0-4', datosUsuario.infantes_0_4.toString());

            // Hacer clic en cotizar
            console.log('💰 Ejecutando cotización...');
            await page.click('#cotizar-button');

            // Esperar resultado
            await page.waitForSelector('.resultado-cotizacion', { timeout: 20000 });

            // Extraer resultado
            const resultado = await this.extraerResultado(page);
            
            console.log('✅ Cotización completada exitosamente');
            return resultado;

        } catch (error) {
            console.error('❌ Error durante la cotización:', error.message);
            throw error;
        } finally {
            await browser.close();
        }
    }

    async seleccionarFecha(page, fecha) {
        // Convertir fecha a formato del calendario
        const fechaObj = new Date(fecha);
        const dia = fechaObj.getDate();
        const mes = fechaObj.getMonth();
        const año = fechaObj.getFullYear();

        // Seleccionar fecha en el calendario
        await page.evaluate((dia, mes, año) => {
            // Lógica para seleccionar fecha en el calendario
            const fechaSelector = `[data-date="${año}-${String(mes + 1).padStart(2, '0')}-${String(dia).padStart(2, '0')}"]`;
            document.querySelector(fechaSelector).click();
        }, dia, mes, año);
    }

    async extraerResultado(page) {
        return await page.evaluate(() => {
            const precioElement = document.querySelector('.precio-total');
            const habitacionElement = document.querySelector('.tipo-habitacion');
            
            return {
                precio: precioElement ? precioElement.textContent : 'No disponible',
                habitacion: habitacionElement ? habitacionElement.textContent : 'No disponible',
                disponible: true
            };
        });
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// API Express para manejar las peticiones
const express = require('express');
const app = express();
const cotizador = new CotizadorPuyehue();

app.use(express.json());

app.post('/api/cotizar-puyehue', async (req, res) => {
    try {
        const datosUsuario = req.body;
        
        console.log('🏨 Iniciando cotización para:', datosUsuario);
        
        const resultado = await cotizador.cotizarConReintentos(datosUsuario);
        
        res.json({
            success: true,
            resultado: resultado,
            mensaje: 'Cotización completada exitosamente'
        });

    } catch (error) {
        console.error('❌ Error en API:', error.message);
        
        res.status(500).json({
            success: false,
            error: 'El portal está en mantenimiento. Por favor, contactar a un agente.',
            detalles: error.message
        });
    }
});

// Función para usar desde el frontend
async function cotizarPuyehueDesdeFrontend(datosUsuario) {
    try {
        const response = await fetch('/api/cotizar-puyehue', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(datosUsuario)
        });

        const resultado = await response.json();

        if (resultado.success) {
            return resultado.resultado;
        } else {
            throw new Error(resultado.error);
        }

    } catch (error) {
        console.error('❌ Error en cotización:', error.message);
        throw new Error('El portal está en mantenimiento. Por favor, contactar a un agente.');
    }
}

// Exportar para uso en el frontend
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { CotizadorPuyehue, cotizarPuyehueDesdeFrontend };
}

// Iniciar servidor si se ejecuta directamente
if (require.main === module) {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
        console.log(`🚀 Servidor de cotización iniciado en puerto ${PORT}`);
    });
} 