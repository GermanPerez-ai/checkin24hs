-- Campos Corralco / FlexiPass para vouchers y programas (import Excel, resumen por cliente).
-- Ejecutar en Supabase → SQL Editor después de 042 y 043.

ALTER TABLE public.flexi_vouchers
  ADD COLUMN IF NOT EXISTS pack_flexi INTEGER,
  ADD COLUMN IF NOT EXISTS monto_senia_ars NUMERIC(12, 0),
  ADD COLUMN IF NOT EXISTS source TEXT,
  ADD COLUMN IF NOT EXISTS cliente_documento TEXT,
  ADD COLUMN IF NOT EXISTS codigo_tbk TEXT,
  ADD COLUMN IF NOT EXISTS numero_boleta TEXT,
  ADD COLUMN IF NOT EXISTS tipo_ticket TEXT,
  ADD COLUMN IF NOT EXISTS tipo_pago TEXT,
  ADD COLUMN IF NOT EXISTS pago_usd_1_estado TEXT,
  ADD COLUMN IF NOT EXISTS pago_usd_2_estado TEXT,
  ADD COLUMN IF NOT EXISTS orden_numero TEXT,
  ADD COLUMN IF NOT EXISTS cliente_ciudad TEXT;

ALTER TABLE public.flexi_programs
  ADD COLUMN IF NOT EXISTS source TEXT;

CREATE INDEX IF NOT EXISTS idx_flexi_vouchers_source ON public.flexi_vouchers(source);
CREATE INDEX IF NOT EXISTS idx_flexi_vouchers_cliente_email ON public.flexi_vouchers(cliente_email);
CREATE INDEX IF NOT EXISTS idx_flexi_vouchers_codigo_tbk ON public.flexi_vouchers(codigo_tbk);

COMMENT ON COLUMN public.flexi_vouchers.pack_flexi IS 'Cantidad de PACKs Flexi vendidos en esta transacción (ej. 1 PACK = 10 cupos)';
COMMENT ON COLUMN public.flexi_vouchers.monto_senia_ars IS 'Seña abonada en pesos argentinos (ej. 92000 ARS por PACK)';
COMMENT ON COLUMN public.flexi_vouchers.source IS 'Origen del registro: manual, corralco-import-file, gsheet-corralco, etc.';
COMMENT ON COLUMN public.flexi_vouchers.codigo_tbk IS 'Código TBK del reporte Corralco / FlexiPass';
COMMENT ON COLUMN public.flexi_programs.source IS 'Origen del programa: manual, FILE-CORRALCO, GSHEET-CORRALCO, etc.';
