-- ============================================
-- SCRIPT FUNCIONAL: RENOMBRAR TABLAS A INGLÉS
-- ============================================
-- Este script renombra las tablas usando bloques DO para mayor control
-- Maneja correctamente las tablas con espacios en los nombres

-- Renombrar hoteles → hotels
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'hoteles') THEN
        ALTER TABLE hoteles RENAME TO hotels;
        RAISE NOTICE '✓ hoteles → hotels';
    ELSE
        RAISE NOTICE '✗ Tabla hoteles no encontrada';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error renombrando hoteles: %', SQLERRM;
END $$;

-- Renombrar reservas → reservations
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'reservas') THEN
        ALTER TABLE reservas RENAME TO reservations;
        RAISE NOTICE '✓ reservas → reservations';
    ELSE
        RAISE NOTICE '✗ Tabla reservas no encontrada';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error renombrando reservas: %', SQLERRM;
END $$;

-- Renombrar cotizaciones → quotes
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'cotizaciones') THEN
        ALTER TABLE cotizaciones RENAME TO quotes;
        RAISE NOTICE '✓ cotizaciones → quotes';
    ELSE
        RAISE NOTICE '✗ Tabla cotizaciones no encontrada';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error renombrando cotizaciones: %', SQLERRM;
END $$;

-- Renombrar gastos → expenses
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'gastos') THEN
        ALTER TABLE gastos RENAME TO expenses;
        RAISE NOTICE '✓ gastos → expenses';
    ELSE
        RAISE NOTICE '✗ Tabla gastos no encontrada';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error renombrando gastos: %', SQLERRM;
END $$;

-- Renombrar usuarios del sistema → system_users
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'usuarios del sistema') THEN
        EXECUTE 'ALTER TABLE "usuarios del sistema" RENAME TO system_users';
        RAISE NOTICE '✓ usuarios del sistema → system_users';
    ELSE
        RAISE NOTICE '✗ Tabla usuarios del sistema no encontrada';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error renombrando usuarios del sistema: %', SQLERRM;
END $$;

-- Renombrar administradores del panel de control → dashboard_admins
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = 'administradores del panel de control') THEN
        EXECUTE 'ALTER TABLE "administradores del panel de control" RENAME TO dashboard_admins';
        RAISE NOTICE '✓ administradores del panel de control → dashboard_admins';
    ELSE
        RAISE NOTICE '✗ Tabla administradores del panel de control no encontrada';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error renombrando administradores: %', SQLERRM;
END $$;

-- ============================================
-- Mensaje final
-- ============================================
DO $$ 
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Renombrado completado. Verifica los resultados arriba.';
    RAISE NOTICE 'Ejecuta el script de verificación para confirmar.';
    RAISE NOTICE '========================================';
END $$;

-- ============================================
-- Después de ejecutar, verifica con:
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
-- ORDER BY table_name;
-- ============================================

