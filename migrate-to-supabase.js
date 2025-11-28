// ============================================
// SCRIPT DE MIGRACIÓN: localStorage → Supabase
// ============================================
// Este script migra todos los datos de localStorage a Supabase

async function migrateLocalStorageToSupabase() {
    console.log('🚀 Iniciando migración de datos de localStorage a Supabase...');
    
    if (!window.supabaseClient || !window.supabaseClient.isInitialized()) {
        console.error('❌ Error: Supabase no está inicializado. Configura las credenciales primero.');
        alert('⚠️ Error: Supabase no está configurado. Por favor, configura tus credenciales en supabase-config.js primero.');
        return;
    }

    let migratedCount = 0;
    let errorCount = 0;

    // ============================================
    // 1. MIGRAR HOTELES
    // ============================================
    try {
        const hotels = JSON.parse(localStorage.getItem('hotelsDB') || '[]');
        if (hotels.length > 0) {
            console.log(`📦 Migrando ${hotels.length} hoteles...`);
            
            for (const hotel of hotels) {
                try {
                    // Preparar datos para Supabase
                    const hotelData = {
                        name: hotel.name || '',
                        location: hotel.location || '',
                        description: hotel.description || '',
                        rating: hotel.rating || 0,
                        price: parseFloat(String(hotel.price || 0).replace(/[^0-9.-]/g, '')) || 0,
                        status: hotel.status || 'Activo',
                        amenities: Array.isArray(hotel.amenities) ? hotel.amenities : (hotel.amenities ? [hotel.amenities] : []),
                        images: Array.isArray(hotel.images) ? hotel.images : (hotel.images ? [hotel.images] : []),
                        coordinates: hotel.coordinates || null,
                        google_maps: hotel.googleMaps || hotel.google_maps || null
                    };

                    await window.supabaseClient.createHotel(hotelData);
                    migratedCount++;
                    console.log(`✅ Hotel migrado: ${hotel.name}`);
                } catch (error) {
                    errorCount++;
                    console.error(`❌ Error migrando hotel "${hotel.name}":`, error.message);
                }
            }
        } else {
            console.log('ℹ️ No hay hoteles para migrar');
        }
    } catch (error) {
        console.error('❌ Error en migración de hoteles:', error);
    }

    // ============================================
    // 2. MIGRAR RESERVAS
    // ============================================
    try {
        const reservations = JSON.parse(localStorage.getItem('reservationsDB') || '[]');
        if (reservations.length > 0) {
            console.log(`📦 Migrando ${reservations.length} reservas...`);
            
            for (const reservation of reservations) {
                try {
                    const reservationData = {
                        code: reservation.code || reservation.id || 'RES-' + Date.now(),
                        hotel_id: null, // Necesitarías mapear el ID del hotel
                        customer_name: reservation.customerName || reservation.customer_name || '',
                        customer_email: reservation.customerEmail || reservation.customer_email || '',
                        customer_phone: reservation.customerPhone || reservation.customer_phone || '',
                        check_in: reservation.checkIn || reservation.check_in || null,
                        check_out: reservation.checkOut || reservation.check_out || null,
                        adults: reservation.adults || 1,
                        children: reservation.children || 0,
                        total_amount: parseFloat(reservation.totalAmount || reservation.total_amount || 0),
                        status: reservation.status || 'Pendiente',
                        notes: reservation.notes || ''
                    };

                    await window.supabaseClient.createReservation(reservationData);
                    migratedCount++;
                    console.log(`✅ Reserva migrada: ${reservationData.code}`);
                } catch (error) {
                    errorCount++;
                    console.error(`❌ Error migrando reserva "${reservation.code}":`, error.message);
                }
            }
        } else {
            console.log('ℹ️ No hay reservas para migrar');
        }
    } catch (error) {
        console.error('❌ Error en migración de reservas:', error);
    }

    // ============================================
    // 3. MIGRAR COTIZACIONES
    // ============================================
    try {
        const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
        if (quotes.length > 0) {
            console.log(`📦 Migrando ${quotes.length} cotizaciones...`);
            
            for (const quote of quotes) {
                try {
                    const quoteData = {
                        customer_name: quote.customerName || quote.customer_name || '',
                        customer_email: quote.customerEmail || quote.customer_email || '',
                        customer_phone: quote.customerPhone || quote.customer_phone || '',
                        hotel_id: null,
                        check_in: quote.checkIn || quote.check_in || null,
                        check_out: quote.checkOut || quote.check_out || null,
                        adults: quote.adults || 1,
                        children: quote.children || 0,
                        total: parseFloat(quote.total || 0),
                        status: quote.status || 'Pendiente',
                        notes: quote.notes || ''
                    };

                    await window.supabaseClient.createQuote(quoteData);
                    migratedCount++;
                    console.log(`✅ Cotización migrada: ${quoteData.customer_name || quoteData.customer_email}`);
                } catch (error) {
                    errorCount++;
                    console.error(`❌ Error migrando cotización:`, error.message);
                }
            }
        } else {
            console.log('ℹ️ No hay cotizaciones para migrar');
        }
    } catch (error) {
        console.error('❌ Error en migración de cotizaciones:', error);
    }

    // ============================================
    // 4. MIGRAR GASTOS
    // ============================================
    try {
        const expenses = JSON.parse(localStorage.getItem('expensesDB') || '[]');
        if (expenses.length > 0) {
            console.log(`📦 Migrando ${expenses.length} gastos...`);
            
            for (const expense of expenses) {
                try {
                    const expenseData = {
                        date: expense.date || new Date().toISOString().split('T')[0],
                        type: expense.type || 'variable',
                        category: expense.category || '',
                        subcategory: expense.subcategory || '',
                        description: expense.description || '',
                        amount: parseFloat(expense.amount || 0),
                        exchange_rate: expense.exchangeRate || expense.exchange_rate || null,
                        usd_amount: expense.usd || expense.usd_amount || null
                    };

                    await window.supabaseClient.createExpense(expenseData);
                    migratedCount++;
                    console.log(`✅ Gasto migrado: ${expenseData.description || expenseData.category}`);
                } catch (error) {
                    errorCount++;
                    console.error(`❌ Error migrando gasto:`, error.message);
                }
            }
        } else {
            console.log('ℹ️ No hay gastos para migrar');
        }
    } catch (error) {
        console.error('❌ Error en migración de gastos:', error);
    }

    // ============================================
    // 5. MIGRAR USUARIOS
    // ============================================
    try {
        const users = JSON.parse(localStorage.getItem('checkin24hs_users') || '[]');
        if (users.length > 0) {
            console.log(`📦 Migrando ${users.length} usuarios...`);
            
            for (const user of users) {
                try {
                    const userData = {
                        name: user.name || '',
                        email: user.email || '',
                        phone: user.phone || '',
                        status: user.status || 'active',
                        tipo_cuenta: user.tipoCuenta || user.tipo_cuenta || '',
                        birth_day: user.birthDay || user.birth_day || null,
                        birth_month: user.birthMonth || user.birth_month || null
                    };

                    if (userData.email) {
                        await window.supabaseClient.createUser(userData);
                        migratedCount++;
                        console.log(`✅ Usuario migrado: ${userData.email}`);
                    }
                } catch (error) {
                    errorCount++;
                    console.error(`❌ Error migrando usuario "${user.email}":`, error.message);
                }
            }
        } else {
            console.log('ℹ️ No hay usuarios para migrar');
        }
    } catch (error) {
        console.error('❌ Error en migración de usuarios:', error);
    }

    // ============================================
    // RESUMEN FINAL
    // ============================================
    console.log('='.repeat(50));
    console.log('📊 RESUMEN DE MIGRACIÓN');
    console.log('='.repeat(50));
    console.log(`✅ Registros migrados exitosamente: ${migratedCount}`);
    console.log(`❌ Errores: ${errorCount}`);
    console.log('='.repeat(50));

    if (errorCount === 0) {
        alert(`✅ Migración completada exitosamente!\n\n${migratedCount} registros migrados a Supabase.`);
    } else {
        alert(`⚠️ Migración completada con algunos errores.\n\n✅ Exitosos: ${migratedCount}\n❌ Errores: ${errorCount}\n\nRevisa la consola para más detalles.`);
    }
}

// Función para ejecutar migración desde el dashboard
window.migrateToSupabase = migrateLocalStorageToSupabase;

// Auto-ejecutar si se desea (descomentar para activar)
// migrateLocalStorageToSupabase();

