-- ============================================
-- SCRIPT ROBUSTO: RENOMBRAR TABLAS (VERSIÓN MEJORADA)
-- ============================================
-- Este script renombra las tablas de forma más explícita
-- Maneja mejor las tablas con espacios en los nombres

-- 1. Renombrar hoteles → hotels
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'hoteles') THEN
        ALTER TABLE hoteles RENAME TO hotels;
        RAISE NOTICE 'Tabla hoteles renombrada a hotels';
    END IF;
END $$;

-- 2. Renombrar reservas → reservations
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reservas') THEN
        ALTER TABLE reservas RENAME TO reservations;
        RAISE NOTICE 'Tabla reservas renombrada a reservations';
    END IF;
END $$;

-- 3. Renombrar cotizaciones → quotes
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'cotizaciones') THEN
        ALTER TABLE cotizaciones RENAME TO quotes;
        RAISE NOTICE 'Tabla cotizaciones renombrada a quotes';
    END IF;
END $$;

-- 4. Renombrar gastos → expenses
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'gastos') THEN
        ALTER TABLE gastos RENAME TO expenses;
        RAISE NOTICE 'Tabla gastos renombrada a expenses';
    END IF;
END $$;

-- 5. Renombrar usuarios del sistema → system_users
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'usuarios del sistema') THEN
        EXECUTE 'ALTER TABLE "usuarios del sistema" RENAME TO system_users';
        RAISE NOTICE 'Tabla usuarios del sistema renombrada a system_users';
    END IF;
END $$;

-- 6. Renombrar administradores del panel de control → dashboard_admins
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'administradores del panel de control') THEN
        EXECUTE 'ALTER TABLE "administradores del panel de control" RENAME TO dashboard_admins';
        RAISE NOTICE 'Tabla administradores del panel de control renombrada a dashboard_admins';
    END IF;
END $$;

-- ============================================
-- ¡LISTO! Ahora verifica los nombres con el script de verificación
-- ============================================

