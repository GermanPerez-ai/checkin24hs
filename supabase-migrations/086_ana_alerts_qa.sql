-- ANA: historial de alertas y auditoría de calidad de Flor IA
-- Ejecutar en SQL Editor de Supabase.

CREATE TABLE IF NOT EXISTS public.ana_alerts_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind TEXT NOT NULL,
  fingerprint TEXT NOT NULL,
  channel TEXT NOT NULL DEFAULT 'whatsapp',
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  sent_ok BOOLEAN NOT NULL DEFAULT false,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ana_alerts_log_kind_fp_idx
  ON public.ana_alerts_log (kind, fingerprint);

DO $$
BEGIN
  ALTER TABLE public.ana_alerts_log
    ADD CONSTRAINT ana_alerts_log_kind_fp_key UNIQUE (kind, fingerprint);
EXCEPTION
  WHEN duplicate_table OR duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS ana_alerts_log_created_idx
  ON public.ana_alerts_log (created_at DESC);

CREATE TABLE IF NOT EXISTS public.ana_qa_flor_ia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period_from DATE NOT NULL,
  period_to DATE NOT NULL,
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  gaps JSONB NOT NULL DEFAULT '[]'::jsonb,
  prompt_suggestions TEXT NOT NULL DEFAULT '',
  raw JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ana_qa_flor_ia_created_idx
  ON public.ana_qa_flor_ia (created_at DESC);

ALTER TABLE public.ana_alerts_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ana_qa_flor_ia ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ana_alerts_anon_all ON public.ana_alerts_log;
CREATE POLICY ana_alerts_anon_all ON public.ana_alerts_log
  FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS ana_qa_anon_all ON public.ana_qa_flor_ia;
CREATE POLICY ana_qa_anon_all ON public.ana_qa_flor_ia
  FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

GRANT ALL ON public.ana_alerts_log TO anon, authenticated;
GRANT ALL ON public.ana_qa_flor_ia TO anon, authenticated;

COMMENT ON TABLE public.ana_alerts_log IS 'ANA: alertas proactivas (flash, Flor, jobs).';
COMMENT ON TABLE public.ana_qa_flor_ia IS 'ANA: auditoría semanal de calidad de Flor IA.';
