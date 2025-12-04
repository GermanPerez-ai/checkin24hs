-- ============================================
-- RENOMBRAR SOLO LAS TABLAS QUE EXISTAN
-- ============================================
-- Este script renombra solo las tablas que realmente existen
-- Ejecuta primero "verificar-y-renombrar-inteligente.sql" para ver el estado

-- Si hoteles existe, renombrar a hotels
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'hoteles') THEN
        ALTER TABLE hoteles RENAME TO hotels;
        RAISE NOTICE '✓ hoteles → hotels';
    END IF;
END $$;

-- Si reservas existe, renombrar a reservations
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reservas') THEN
        ALTER TABLE reservas RENAME TO reservations;
        RAISE NOTICE '✓ reservas → reservations';
    END IF;
END $$;

-- Si cotizaciones existe, renombrar a quotes
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'cotizaciones') THEN
        ALTER TABLE cotizaciones RENAME TO quotes;
        RAISE NOTICE '✓ cotizaciones → quotes';
    END IF;
END $$;

-- Si gastos existe, renombrar a expenses
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'gastos') THEN
        ALTER TABLE gastos RENAME TO expenses;
        RAISE NOTICE '✓ gastos → expenses';
    END IF;
END $$;

-- Si usuarios del sistema existe, renombrar a system_users
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'usuarios del sistema') THEN
        EXECUTE 'ALTER TABLE "usuarios del sistema" RENAME TO system_users';
        RAISE NOTICE '✓ usuarios del sistema → system_users';
    END IF;
END $$;

-- Si administradores del panel de control existe, renombrar a dashboard_admins
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'administradores del panel de control') THEN
        EXECUTE 'ALTER TABLE "administradores del panel de control" RENAME TO dashboard_admins';
        RAISE NOTICE '✓ administradores del panel de control → dashboard_admins';
    END IF;
END $$;

-- Mensaje final
DO $$ 
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Renombrado completado. Revisa los mensajes arriba.';
    RAISE NOTICE 'Las tablas que no existían fueron ignoradas.';
    RAISE NOTICE '========================================';
END $$;

-- ============================================
-- Después de ejecutar, verifica con:
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
-- ORDER BY table_name;
-- ============================================

