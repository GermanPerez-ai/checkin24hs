const puppeteer = require('puppeteer');

async function getRealPuyehueQuote(quoteData) {
    console.log('🚀 Iniciando automatización de Puyehue...');
    console.log('📋 Datos de cotización:', quoteData);
    
    const browser = await puppeteer.launch({
        headless: false, // Para debugging, cambiar a true en producción
        defaultViewport: null,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    try {
        const page = await browser.newPage();
        
        // Navegar al portal
        console.log('🌐 Navegando al portal de Puyehue...');
        await page.goto('https://reservas.puyehue.cl/cgi-bin/login_AG.cgi?RESORT=&option=logout', {
            waitUntil: 'networkidle2',
            timeout: 30000
        });
        console.log('✅ Portal cargado');

        // Login
        console.log('🔐 Buscando formulario de login...');
        await page.waitForSelector('input[name="username"], input[name="user"], input[type="text"]', { timeout: 10000 });
        console.log('🔐 Formulario de login encontrado');
        
        await page.type('input[name="username"], input[name="user"], input[type="text"]', 'canopypromo');
        await page.type('input[name="password"], input[type="password"]', 'canopypromo');
        await page.click('input[type="submit"], button[type="submit"], .login-button');
        console.log('✅ Login enviado');
        
        // Esperar un poco más y verificar si la página cambió
        console.log('⏳ Esperando respuesta del login...');
        await page.waitForTimeout(5000);
        
        // Debug: Mostrar la URL actual y el contenido de la página
        console.log('📍 URL actual:', await page.url());
        const pageTitle = await page.title();
        console.log('📄 Título de la página:', pageTitle);

        // Buscar formulario de cotización usando los selectores correctos del portal
        console.log('🔍 Buscando formulario de cotización...');
        
        // Usar los selectores específicos que encontramos en el portal
        const checkinField = await page.$('#FECHA_CHECKIN');
        if (!checkinField) {
            console.log('❌ No se encontró el campo FECHA_CHECKIN');
            throw new Error('No se pudo encontrar el campo de fecha de check-in');
        }
        
        console.log('✅ Campo de fecha encontrado');

        // Llenar formulario con los datos correctos
        console.log('📝 Llenando formulario de cotización...');
        
        // Función para seleccionar fecha en el calendario
        async function selectDateInCalendar(dateString) {
            console.log(`📅 Seleccionando fecha: ${dateString}`);
            
            // Parsear la fecha
            const date = new Date(dateString);
            const day = date.getDate();
            const month = date.getMonth(); // 0-11
            const year = date.getFullYear();
            
            // Intentar diferentes métodos para abrir el calendario
            console.log('🔍 Intentando abrir el calendario...');
            
            try {
                // Método 1: Hacer clic en el campo
                await page.click('#FECHA_CHECKIN');
                console.log('✅ Clic en campo de fecha realizado');
            } catch (e) {
                console.log('⚠️ Clic falló, intentando focus...');
                try {
                    // Método 2: Focus en el campo
                    await page.focus('#FECHA_CHECKIN');
                    console.log('✅ Focus en campo de fecha realizado');
                } catch (e2) {
                    console.log('⚠️ Focus falló, intentando escribir directamente...');
                    // Método 3: Escribir directamente
                    await page.evaluate(() => {
                        const field = document.querySelector('#FECHA_CHECKIN');
                        if (field) {
                            field.value = '2025-08-20';
                            field.dispatchEvent(new Event('change', { bubbles: true }));
                            field.dispatchEvent(new Event('blur', { bubbles: true }));
                        }
                    });
                    console.log('✅ Fecha escrita directamente');
                    return;
                }
            }
            
            await page.waitForTimeout(2000);
            
            // Esperar a que aparezca el calendario
            try {
                await page.waitForSelector('.ui-datepicker, .calendar, [class*="datepicker"], [class*="calendar"]', { timeout: 5000 });
                console.log('✅ Calendario abierto');
                
                // Intentar hacer clic en el día específico
                try {
                    const daySelector = `td[data-date="${day}"], td:contains("${day}"), .ui-datepicker-calendar td:contains("${day}")`;
                    await page.click(daySelector);
                    console.log(`✅ Día ${day} seleccionado`);
                } catch (e) {
                    console.log('⚠️ No se pudo hacer clic en el día, intentando escribir directamente...');
                    // Escribir la fecha directamente
                    await page.evaluate((dateStr) => {
                        const field = document.querySelector('#FECHA_CHECKIN');
                        if (field) {
                            field.value = dateStr;
                            field.dispatchEvent(new Event('change', { bubbles: true }));
                            field.dispatchEvent(new Event('blur', { bubbles: true }));
                        }
                    }, dateString);
                    console.log('✅ Fecha escrita directamente');
                }
            } catch (e) {
                console.log('⚠️ No se pudo abrir el calendario, escribiendo directamente...');
                await page.evaluate((dateStr) => {
                    const field = document.querySelector('#FECHA_CHECKIN');
                    if (field) {
                        field.value = dateStr;
                        field.dispatchEvent(new Event('change', { bubbles: true }));
                        field.dispatchEvent(new Event('blur', { bubbles: true }));
                    }
                }, dateString);
                console.log('✅ Fecha escrita directamente');
            }
        }

        // Llenar fecha de check-in
        await selectDateInCalendar(quoteData.checkIn);
        
        // Llenar número de noches
        const nightsField = await page.$('input[name="NOCHES"]');
        if (nightsField) {
            await page.focus('input[name="NOCHES"]');
            await page.keyboard.down('Control');
            await page.keyboard.press('A');
            await page.keyboard.up('Control');
            await page.keyboard.press('Backspace');
            await page.type('input[name="NOCHES"]', quoteData.nights.toString());
        }
        
        // Llenar número de adultos
        const adultsField = await page.$('input[name="ADULTOS"]');
        if (adultsField) {
            await page.focus('input[name="ADULTOS"]');
            await page.keyboard.down('Control');
            await page.keyboard.press('A');
            await page.keyboard.up('Control');
            await page.keyboard.press('Backspace');
            await page.type('input[name="ADULTOS"]', quoteData.adults.toString());
        }
        
        // Llenar número de niños
        const childrenField = await page.$('input[name="CHILD"]');
        if (childrenField) {
            await page.focus('input[name="CHILD"]');
            await page.keyboard.down('Control');
            await page.keyboard.press('A');
            await page.keyboard.up('Control');
            await page.keyboard.press('Backspace');
            await page.type('input[name="CHILD"]', quoteData.children.toString());
        }
        
        console.log('✅ Formulario llenado correctamente');

        // Enviar formulario
        console.log('📤 Enviando formulario...');
        await page.click('input[type="submit"], button[type="submit"]');
        
        // Esperar más tiempo para que cargue toda la página
        console.log('⏳ Esperando respuesta del formulario...');
        await page.waitForTimeout(15000);
        
        // Hacer scroll para cargar todo el contenido
        console.log('📜 Haciendo scroll para cargar todo el contenido...');
        await page.evaluate(() => {
            window.scrollTo(0, document.body.scrollHeight);
        });
        await page.waitForTimeout(3000);
        
        // NUEVO ENFOQUE: Buscar directamente el botón "CONTINUAR" o "COTIZAR" que aparece en la página
        console.log('🎯 Buscando botón para continuar...');
        
        // PRIMERO: Intentar seleccionar un programa específico
        console.log('🎯 Seleccionando programa EXPERIENCIA...');
        
        // Buscar elementos que contengan "EXPERIENCIA" o "SUEÑA"
        const programElements = await page.evaluate(() => {
            const elements = document.querySelectorAll('*');
            const programElements = [];
            
            for (const el of elements) {
                const text = el.textContent || el.value || '';
                if (text.toUpperCase().includes('EXPERIENCIA') || 
                    text.toUpperCase().includes('SUEÑA') ||
                    text.toUpperCase().includes('PROGRAMA')) {
                    programElements.push({
                        tagName: el.tagName,
                        className: el.className,
                        id: el.id,
                        text: text.trim(),
                        isClickable: el.tagName === 'BUTTON' || el.tagName === 'A' || el.tagName === 'INPUT' || el.onclick
                    });
                }
            }
            return programElements;
        });
        
        console.log('🔍 Elementos de programa encontrados:', programElements);
        
        // Intentar hacer clic en elementos de programa
        let programSelected = false;
        
        for (const elementInfo of programElements) {
            if (elementInfo.isClickable) {
                try {
                    // Intentar hacer clic usando diferentes selectores
                    const selectors = [
                        `${elementInfo.tagName.toLowerCase()}[class*="${elementInfo.className}"]`,
                        `${elementInfo.tagName.toLowerCase()}#${elementInfo.id}`,
                        `${elementInfo.tagName.toLowerCase()}:contains("${elementInfo.text}")`,
                        `${elementInfo.tagName.toLowerCase()}`
                    ];
                    
                    for (const selector of selectors) {
                        try {
                            const elements = await page.$$(selector);
                            for (const element of elements) {
                                const text = await page.evaluate(el => el.textContent || el.value || '', element);
                                if (text.toUpperCase().includes('EXPERIENCIA') || 
                                    text.toUpperCase().includes('SUEÑA')) {
                                    await element.click();
                                    console.log(`✅ Programa seleccionado: ${text}`);
                                    programSelected = true;
                                    break;
                                }
                            }
                            if (programSelected) break;
                        } catch (e) {
                            continue;
                        }
                    }
                    if (programSelected) break;
                } catch (e) {
                    continue;
                }
            }
        }
        
        if (!programSelected) {
            console.log('⚠️ No se pudo seleccionar programa específico, intentando con cualquier botón...');
        }
        
        // SEGUNDO: Seleccionar programa para mostrar precios
        console.log('🎯 Seleccionando programa para mostrar precios...');
        console.log('📋 Programa seleccionado por el usuario:', quoteData.selectedProgram);
        
        try {
            // Determinar qué programa buscar basado en la selección del usuario
            const targetProgram = quoteData.selectedProgram?.toLowerCase() || 'experiencia';
            console.log(`🎯 Buscando programa: ${targetProgram.toUpperCase()}`);
            
            // ESTRATEGIA 1: Buscar por texto específico
            console.log('🔍 Buscando programa EXPERIENCIA por texto en la página...');
            const pageText = await page.evaluate(() => document.body.innerText);
            if (pageText.toUpperCase().includes('PROGRAMA EXPERIENCIA')) {
                console.log('✅ Texto EXPERIENCIA encontrado en la página');
                
                // ESTRATEGIA 2: Intentar seleccionar via JavaScript
                console.log('🔧 Intentando seleccionar EXPERIENCIA via JavaScript...');
                const jsResult = await page.evaluate(() => {
                    // Buscar elementos que contengan "EXPERIENCIA"
                    const experienciaElements = Array.from(document.querySelectorAll('*')).filter(el => 
                        el.textContent && el.textContent.toUpperCase().includes('PROGRAMA EXPERIENCIA')
                    );
                    
                    if (experienciaElements.length > 0) {
                        // Intentar hacer clic en el primer elemento encontrado
                        try {
                            experienciaElements[0].click();
                            return true;
                        } catch (e) {
                            return false;
                        }
                    }
                    return false;
                });
                
                if (jsResult) {
                    console.log('✅ Programa EXPERIENCIA seleccionado via JavaScript');
                    
                    // ESPERAR a que se carguen los precios del programa correcto
                    console.log('⏳ Esperando a que se carguen los precios del programa EXPERIENCIA...');
                    await page.waitForTimeout(3000);
                    
                    // VERIFICAR que los precios sean del programa correcto
                    const priceCheck = await page.evaluate(() => {
                        const pageText = document.body.innerText;
                        const hasExperienciaPrices = pageText.includes('US$940') || pageText.includes('US$1.180') || 
                                                   pageText.includes('US$510') || pageText.includes('US$540') || 
                                                   pageText.includes('US$600') || pageText.includes('US$650');
                        const hasSuenaPrices = pageText.includes('US$290') || pageText.includes('US$315');
                        
                        return {
                            hasExperienciaPrices,
                            hasSuenaPrices,
                            pageText: pageText.substring(0, 1000)
                        };
                    });
                    
                    console.log('🔍 Verificación de precios:', priceCheck);
                    
                    if (priceCheck.hasExperienciaPrices && !priceCheck.hasSuenaPrices) {
                        console.log('✅ Precios del programa EXPERIENCIA confirmados');
                    } else {
                        console.log('⚠️ Los precios no corresponden al programa EXPERIENCIA, intentando nuevamente...');
                        // Intentar hacer clic nuevamente
                        await page.evaluate(() => {
                            const buttons = Array.from(document.querySelectorAll('button, a, input[type="submit"]'));
                            const experienciaButton = buttons.find(btn => 
                                btn.textContent && btn.textContent.toUpperCase().includes('EXPERIENCIA')
                            );
                            if (experienciaButton) {
                                experienciaButton.click();
                            }
                        });
                        await page.waitForTimeout(2000);
                    }
                }
                
                // ESTRATEGIA 3: Si no funcionó, intentar con selectores específicos
                if (!jsResult) {
                    console.log('🔧 Intentando con selectores específicos...');
                    
                    // Buscar botones que contengan "EXPERIENCIA" o "FULL BOARD"
                    const experienciaButtons = await page.$$('button, a, input[type="submit"]');
                    let clicked = false;
                    
                    for (const button of experienciaButtons) {
                        const buttonText = await page.evaluate(el => el.textContent || '', button);
                        if (buttonText.toUpperCase().includes('EXPERIENCIA') || 
                            buttonText.toUpperCase().includes('FULL BOARD')) {
                            try {
                                await button.click();
                                console.log('✅ Botón EXPERIENCIA clickeado:', buttonText);
                                clicked = true;
                                await page.waitForTimeout(3000);
                                break;
                            } catch (e) {
                                console.log('⚠️ Error al hacer clic en botón:', e.message);
                            }
                        }
                    }
                    
                    if (!clicked) {
                        console.log('⚠️ No se pudo seleccionar programa específico, intentando con cualquier botón...');
                    }
                }
            }
        } catch (error) {
            console.log('❌ Error al seleccionar programa:', error.message);
        }
        
        // TERCERO: Buscar botón para continuar
        console.log('🎯 Buscando botón para continuar...');
        
        try {
            // Buscar botones específicos
            const continueButtons = await page.$$('button, a, input[type="submit"]');
            let continueClicked = false;
            
            for (const button of continueButtons) {
                const buttonText = await page.evaluate(el => el.textContent || '', button);
                const upperText = buttonText.toUpperCase();
                
                if (upperText.includes('CONTINUAR') || upperText.includes('SIGUIENTE') || 
                    upperText.includes('AVANZAR') || upperText.includes('COTIZAR')) {
                    try {
                        await button.click();
                        console.log('✅ Botón de continuar clickeado:', buttonText);
                        continueClicked = true;
                        await page.waitForTimeout(2000);
                        break;
                    } catch (e) {
                        console.log('⚠️ Error al hacer clic en botón de continuar:', e.message);
                    }
                }
            }
            
            if (!continueClicked) {
                console.log('⚠️ No se encontró botón específico, intentando con cualquier botón de submit...');
                
                // Intentar con cualquier botón de submit
                const submitButtons = await page.$$('input[type="submit"], button[type="submit"]');
                for (const button of submitButtons) {
                    try {
                        await button.click();
                        console.log('✅ Botón submit genérico clickeado');
                        await page.waitForTimeout(2000);
                        break;
                    } catch (e) {
                        console.log('⚠️ Error al hacer clic en botón submit:', e.message);
                    }
                }
            }
        } catch (error) {
            console.log('❌ Error al buscar botón de continuar:', error.message);
        }
        
        // CUARTO: Intentar estrategia alternativa
        console.log('🎯 Intentando estrategia alternativa...');
        
        try {
            // Buscar botón RESERVAR específico para el programa seleccionado
            const targetProgram = quoteData.selectedProgram?.toLowerCase() || 'experiencia';
            console.log(`🎯 Buscando botón RESERVAR para programa: ${targetProgram.toUpperCase()}`);
            
            const reservarButtons = await page.$$('a.button, button, a');
            let reservarClicked = false;
            
            for (const button of reservarButtons) {
                const buttonText = await page.evaluate(el => el.textContent || '', button);
                const upperText = buttonText.toUpperCase();
                
                if (upperText.includes('RESERVAR')) {
                    // Verificar si este botón está asociado con el programa correcto
                    const buttonContext = await page.evaluate(el => {
                        const parent = el.parentElement;
                        const grandParent = parent ? parent.parentElement : null;
                        const context = (parent ? parent.textContent : '') + ' ' + (grandParent ? grandParent.textContent : '');
                        return context.toUpperCase();
                    }, button);
                    
                    if (buttonContext.includes(targetProgram.toUpperCase())) {
                        try {
                            await button.click();
                            console.log(`✅ Botón RESERVAR específico para ${targetProgram.toUpperCase()} clickeado`);
                            reservarClicked = true;
                            await page.waitForTimeout(3000);
                            break;
                        } catch (e) {
                            console.log('⚠️ Error al hacer clic en botón RESERVAR específico:', e.message);
                        }
                    }
                }
            }
            
            if (!reservarClicked) {
                console.log('⚠️ No se encontró botón RESERVAR específico, usando genérico');
                
                // Fallback: buscar cualquier botón RESERVAR
                for (const button of reservarButtons) {
                    const buttonText = await page.evaluate(el => el.textContent || '', button);
                    if (buttonText.toUpperCase().includes('RESERVAR')) {
                        try {
                            await button.click();
                            console.log('🔍 Botón RESERVAR genérico encontrado:', buttonText);
                            console.log('✅ Botón RESERVAR genérico clickeado exitosamente');
                            await page.waitForTimeout(3000);
                            break;
                        } catch (e) {
                            console.log('⚠️ Error al hacer clic en botón RESERVAR genérico:', e.message);
                        }
                    }
                }
            }
        } catch (error) {
            console.log('❌ Error al buscar botón RESERVAR:', error.message);
        }
        
        // Esperar a que se cargue la página de resultados
        console.log('📍 URL después del envío:', await page.url());
        await page.waitForTimeout(3000);
        
        // CUARTO: Extraer precios reales
        console.log('💰 Extrayendo precios reales...');
        
        try {
            const priceData = await page.evaluate(() => {
                const prices = [];
                const currencies = [];
                const priceDetails = [];
                const roomOptions = [];
                
                // Buscar precios en tablas
                const tables = document.querySelectorAll('table');
                tables.forEach((table, tableIndex) => {
                    const tableText = table.textContent;
                    
                    // Patrones de precios
                    const pricePatterns = [
                        /US\$([0-9,]+)/g,
                        /\$([0-9,]+)\s*USD/g,
                        /USD\s*([0-9,]+)/g,
                        /([0-9,]+)\s*USD/g
                    ];
                    
                    pricePatterns.forEach((pattern, patternIndex) => {
                        const matches = tableText.match(pattern);
                        if (matches) {
                            console.log(`✅ Tabla ${tableIndex} encontró ${matches.length} coincidencias con patrón ${patternIndex + 1}:`, matches);
                            matches.forEach(match => {
                                const priceMatch = match.match(/([0-9,]+)/);
                                if (priceMatch) {
                                    const price = parseInt(priceMatch[1].replace(/,/g, ''));
                                    if (price > 100 && price < 10000) { // Filtro para precios reales de hotel
                                        // Evitar duplicados
                                        if (!prices.includes(price)) {
                                            prices.push(price);
                                            currencies.push('USD');
                                            priceDetails.push({
                                                price: price,
                                                context: tableText.substring(0, 500),
                                                tableIndex: tableIndex
                                            });
                                        } else {
                                            console.log(`🔄 Precio duplicado ignorado: $${price} USD`);
                                        }
                                    }
                                }
                            });
                        }
                    });
                    
                    // Extraer opciones de habitación
                    const roomRows = table.querySelectorAll('tr, .room-option, .habitacion');
                    roomRows.forEach((row, rowIndex) => {
                        const rowText = row.textContent;
                        
                        // Buscar patrones de habitación más específicos
                        const roomPatterns = [
                            /Habitación\s+([^$]+?)\s+US\$([0-9,]+)/gi,
                            /Lodge\s+([^$]+?)\s+US\$([0-9,]+)/gi,
                            /([^$]+?)\s+US\$([0-9,]+)/gi,
                            /Habitación\s+standard\s+\(([^)]+)\)\s+US\$([0-9,]+)/gi,
                            /Habitación\s+superior\s+\(([^)]+)\)\s+US\$([0-9,]+)/gi
                        ];
                        
                        roomPatterns.forEach(pattern => {
                            const matches = rowText.match(pattern);
                            if (matches) {
                                const roomType = matches[1]?.trim() || `Opción ${rowIndex + 1}`;
                                const price = parseInt(matches[2]?.replace(/,/g, '') || '0');
                                
                                if (price > 100 && price < 10000) {
                                    // Evitar duplicados
                                    const existingRoom = roomOptions.find(room => 
                                        room.type === roomType && room.price === price
                                    );
                                    
                                    if (!existingRoom) {
                                        roomOptions.push({
                                            type: roomType,
                                            price: price,
                                            currency: 'USD',
                                            tableIndex: tableIndex,
                                            rowIndex: rowIndex
                                        });
                                    }
                                }
                            }
                        });
                    });
                });
                
                // Buscar en todo el texto de la página
                const pageText = document.body.innerText;
                const pagePricePatterns = [
                    /US\$([0-9,]+)/g,
                    /\$([0-9,]+)\s*USD/g,
                    /USD\s*([0-9,]+)/g,
                    /([0-9,]+)\s*USD/g
                ];
                pagePricePatterns.forEach((pattern, patternIndex) => {
                    const matches = pageText.match(pattern);
                    if (matches) {
                        console.log(`✅ Texto completo encontró ${matches.length} coincidencias con patrón ${patternIndex + 1}:`, matches);
                        matches.forEach(match => {
                            const priceMatch = match.match(/([0-9,]+)/);
                            if (priceMatch) {
                                const price = parseInt(priceMatch[1].replace(/,/g, ''));
                                if (price > 100 && price < 10000) {
                                    // Evitar duplicados
                                    if (!prices.includes(price)) {
                                        prices.push(price);
                                        currencies.push('USD');
                                        priceDetails.push({
                                            price: price,
                                            context: 'Texto completo de la página',
                                            tableIndex: -1
                                        });
                                    } else {
                                        console.log(`🔄 Precio duplicado ignorado: $${price} USD`);
                                    }
                                }
                            }
                        });
                    }
                });
                
                console.log('🏨 Opciones de habitación:', roomOptions);
                
                return {
                    prices: prices,
                    currency: currencies,
                    priceDetails: priceDetails,
                    roomOptions: roomOptions,
                    pageText: pageText.substring(0, 5000) // Primeros 5000 caracteres para debug
                };
            });
            
            console.log('💰 Precios reales encontrados:', priceData.prices);
            console.log('💱 Monedas encontradas:', priceData.currency);
            console.log('📋 Detalles de precios:', priceData.priceDetails);
            
            // Si no hay precios, buscar fechas alternativas
            if (priceData.prices.length === 0) {
                console.log('⚠️ No se encontraron precios, buscando fechas alternativas...');
                
                // Buscar fechas alternativas (próximos días)
                const originalDate = new Date(quoteData.checkIn);
                const alternativeDates = [];
                
                for (let i = 1; i <= 7; i++) {
                    const newDate = new Date(originalDate);
                    newDate.setDate(originalDate.getDate() + i);
                    alternativeDates.push(newDate.toISOString().split('T')[0]);
                }
                
                console.log('📅 Fechas alternativas a probar:', alternativeDates);
                
                // Intentar con la primera fecha alternativa
                const alternativeDate = alternativeDates[0];
                console.log(`🔄 Intentando con fecha alternativa: ${alternativeDate}`);
                
                // Actualizar la fecha en el formulario
                await page.evaluate((date) => {
                    const dateInputs = document.querySelectorAll('input[type="date"], input[name*="date"], input[name*="fecha"]');
                    dateInputs.forEach(input => {
                        if (input.name.toLowerCase().includes('checkin') || input.name.toLowerCase().includes('inicio')) {
                            input.value = date;
                            input.dispatchEvent(new Event('change', { bubbles: true }));
                        }
                    });
                }, alternativeDate);
                
                // Enviar formulario nuevamente
                const submitButton = await page.$('input[type="submit"], button[type="submit"]');
                if (submitButton) {
                    await submitButton.click();
                    await page.waitForTimeout(3000);
                    
                    // Extraer precios de la fecha alternativa
                    const alternativePriceData = await page.evaluate(() => {
                        const prices = [];
                        const pageText = document.body.innerText;
                        const pricePatterns = [/US\$([0-9,]+)/g, /\$([0-9,]+)\s*USD/g];
                        
                        pricePatterns.forEach(pattern => {
                            const matches = pageText.match(pattern);
                            if (matches) {
                                matches.forEach(match => {
                                    const priceMatch = match.match(/([0-9,]+)/);
                                    if (priceMatch) {
                                        const price = parseInt(priceMatch[1].replace(/,/g, ''));
                                        if (price > 100 && price < 10000 && !prices.includes(price)) {
                                            prices.push(price);
                                        }
                                    }
                                });
                            }
                        });
                        
                        return { prices, pageText: pageText.substring(0, 1000) };
                    });
                    
                    if (alternativePriceData.prices.length > 0) {
                        console.log('✅ Encontrados precios con fecha alternativa:', alternativePriceData.prices);
                        
                        // Actualizar datos de cotización con fecha alternativa
                        quoteData.checkIn = alternativeDate;
                        quoteData.checkOut = new Date(new Date(alternativeDate).getTime() + (quoteData.nights * 24 * 60 * 60 * 1000)).toISOString().split('T')[0];
                        
                        return {
                            success: true,
                            data: {
                                available: true,
                                basePrice: Math.min(...alternativePriceData.prices),
                                totalPrice: Math.min(...alternativePriceData.prices) * quoteData.nights,
                                currency: 'USD',
                                nights: quoteData.nights,
                                adults: quoteData.adults,
                                children: quoteData.children,
                                checkIn: quoteData.checkIn,
                                checkOut: quoteData.checkOut,
                                program: quoteData.selectedProgram,
                                source: 'real_portal_data_alternative_date',
                                allPrices: alternativePriceData.prices,
                                priceDetails: [],
                                roomOptions: [],
                                alternativeDateMessage: `No había disponibilidad para la fecha original. Se encontró disponibilidad para ${alternativeDate}.`
                            }
                        };
                    }
                }
                
                // Si no hay precios ni con fecha alternativa, retornar error
                return {
                    success: false,
                    error: 'No se encontraron precios reales en la respuesta del portal',
                    alternativeDateMessage: 'Se probó con fechas alternativas pero no se encontró disponibilidad.'
                };
            }
            
            // Si hay precios, retornar resultado normal
            const basePrice = Math.min(...priceData.prices);
            const totalPrice = basePrice * quoteData.nights;
            
            console.log('✅ Precios extraídos exitosamente');
            priceData.priceDetails.forEach((detail, index) => {
                console.log(`📊 Precio ${index + 1}: $${detail.price} USD`);
                console.log(`📋 Contexto: ${detail.context.substring(0, 100)}...`);
                console.log(`📍 Fuente: ${detail.tableIndex >= 0 ? `Tabla ${detail.tableIndex}` : 'Texto completo'}`);
                console.log('---');
            });
            
            return {
                success: true,
                data: {
                    available: true,
                    basePrice: basePrice,
                    totalPrice: totalPrice,
                    currency: 'USD',
                    nights: quoteData.nights,
                    adults: quoteData.adults,
                    children: quoteData.children,
                    checkIn: quoteData.checkIn,
                    checkOut: quoteData.checkOut,
                    program: quoteData.selectedProgram,
                    source: 'real_portal_data',
                    allPrices: priceData.prices,
                    priceDetails: priceData.priceDetails,
                    roomOptions: priceData.roomOptions
                }
            };
            
        } catch (error) {
            console.log('❌ Error al extraer precios:', error.message);
            return {
                success: false,
                error: 'Error al extraer precios del portal'
            };
        }
        
    } catch (error) {
        console.error('❌ Error en la automatización:', error);
        return {
            success: false,
            error: error.message
        };
    } finally {
        await browser.close();
    }
}

module.exports = { getRealPuyehueQuote };