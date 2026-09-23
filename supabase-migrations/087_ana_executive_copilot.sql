-- ANA Copiloto Ejecutivo: agenda, tareas e ideas
-- Ejecutar en SQL Editor de Supabase.

DO $$ BEGIN
  CREATE TYPE task_priority AS ENUM ('P1', 'P2', 'P3');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE task_category AS ENUM ('b2b_hoteles', 'sistemas_code', 'marketing_ads', 'gestion_personal', 'operaciones');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.executive_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category task_category DEFAULT 'operaciones',
  priority task_priority DEFAULT 'P2',
  status task_status DEFAULT 'pending',
  is_meeting BOOLEAN DEFAULT FALSE,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  due_date DATE,
  source VARCHAR(50) DEFAULT 'whatsapp',
  source_ref VARCHAR(255),
  google_calendar_event_id VARCHAR(255),
  google_task_id VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.executive_ideas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_prompt TEXT NOT NULL,
  structured_plan JSONB,
  category task_category DEFAULT 'operaciones',
  status VARCHAR(50) DEFAULT 'captured',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_executive_tasks_status_priority
  ON public.executive_tasks (status, priority);

CREATE INDEX IF NOT EXISTS idx_executive_tasks_due_date
  ON public.executive_tasks (due_date);

CREATE INDEX IF NOT EXISTS idx_executive_tasks_start
  ON public.executive_tasks (start_time);

CREATE UNIQUE INDEX IF NOT EXISTS idx_executive_tasks_open_source_ref
  ON public.executive_tasks (source, source_ref)
  WHERE source_ref IS NOT NULL AND status IN ('pending', 'in_progress');

CREATE INDEX IF NOT EXISTS idx_executive_ideas_status
  ON public.executive_ideas (status, created_at DESC);

ALTER TABLE public.executive_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.executive_ideas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS executive_tasks_anon_all ON public.executive_tasks;
CREATE POLICY executive_tasks_anon_all ON public.executive_tasks
  FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS executive_ideas_anon_all ON public.executive_ideas;
CREATE POLICY executive_ideas_anon_all ON public.executive_ideas
  FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);

GRANT ALL ON public.executive_tasks TO anon, authenticated;
GRANT ALL ON public.executive_ideas TO anon, authenticated;

COMMENT ON TABLE public.executive_tasks IS 'ANA Copiloto: tareas y reuniones del ejecutivo.';
COMMENT ON TABLE public.executive_ideas IS 'ANA Copiloto: banco de ideas (braindump).';
COMMENT ON COLUMN public.executive_tasks.source_ref IS 'Clave de deduplicación (auto_system: cancel:CODE, health:L1, etc.).';
