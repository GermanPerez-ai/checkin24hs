-- Programa Flexi: programas, vouchers emitidos y canjes (dashboard admin).
-- Ejecutar en Supabase → SQL Editor.

-- Programas por hotel
CREATE TABLE IF NOT EXISTS public.flexi_programs (
    id TEXT PRIMARY KEY,
    hotel_id UUID REFERENCES public.hotels(id) ON DELETE SET NULL,
    hotel_name TEXT NOT NULL,
    cupos_por_voucher INTEGER NOT NULL,
    precio_usd NUMERIC(12, 2) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    descripcion TEXT,
    estado TEXT NOT NULL DEFAULT 'Activo',
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flexi_programs_hotel_id ON public.flexi_programs(hotel_id);

-- Vouchers emitidos
CREATE TABLE IF NOT EXISTS public.flexi_vouchers (
    id TEXT PRIMARY KEY,
    programa_id TEXT REFERENCES public.flexi_programs(id) ON DELETE SET NULL,
    codigo TEXT NOT NULL UNIQUE,
    hotel_id UUID REFERENCES public.hotels(id) ON DELETE SET NULL,
    hotel_name TEXT,
    cliente_nombre TEXT,
    cliente_email TEXT,
    cliente_telefono TEXT,
    cupos_iniciales INTEGER NOT NULL DEFAULT 0,
    cupos_disponibles INTEGER NOT NULL DEFAULT 0,
    precio_usd NUMERIC(12, 2),
    fecha_venta DATE,
    fecha_inicio_uso DATE,
    fecha_fin_uso DATE,
    estado TEXT NOT NULL DEFAULT 'Activo',
    notas TEXT,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flexi_vouchers_programa ON public.flexi_vouchers(programa_id);
CREATE INDEX IF NOT EXISTS idx_flexi_vouchers_codigo ON public.flexi_vouchers(codigo);

-- Canjes de cupos
CREATE TABLE IF NOT EXISTS public.flexi_canjes (
    id TEXT PRIMARY KEY,
    voucher_id TEXT NOT NULL REFERENCES public.flexi_vouchers(id) ON DELETE CASCADE,
    voucher_codigo TEXT,
    cliente_nombre TEXT,
    hotel_name TEXT,
    check_in DATE,
    check_out DATE,
    personas INTEGER,
    cupos_usados INTEGER NOT NULL DEFAULT 0,
    notas TEXT,
    estado TEXT NOT NULL DEFAULT 'Confirmado',
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    motivo_anulacion TEXT,
    fecha_anulacion TIMESTAMPTZ,
    fecha_noshow TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flexi_canjes_voucher ON public.flexi_canjes(voucher_id);

ALTER TABLE public.flexi_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flexi_vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flexi_canjes ENABLE ROW LEVEL SECURITY;

-- Dashboard usa clave anon (mismo patrón que otras tablas internas del panel)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'flexi_programs_anon_all' AND tablename = 'flexi_programs') THEN
    CREATE POLICY flexi_programs_anon_all ON public.flexi_programs FOR ALL TO anon USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'flexi_vouchers_anon_all' AND tablename = 'flexi_vouchers') THEN
    CREATE POLICY flexi_vouchers_anon_all ON public.flexi_vouchers FOR ALL TO anon USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'flexi_canjes_anon_all' AND tablename = 'flexi_canjes') THEN
    CREATE POLICY flexi_canjes_anon_all ON public.flexi_canjes FOR ALL TO anon USING (true) WITH CHECK (true);
  END IF;
END $$;

COMMENT ON TABLE public.flexi_programs IS 'Programa Flexi por hotel (dashboard)';
COMMENT ON TABLE public.flexi_vouchers IS 'Vouchers Flexi emitidos';
COMMENT ON TABLE public.flexi_canjes IS 'Canjes de cupos Flexi';
