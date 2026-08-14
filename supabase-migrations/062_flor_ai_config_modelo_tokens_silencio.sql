-- Flor IA: alinear flor_ai_config con servidor WhatsApp + silencio 45 min en prompt
-- Modelo: gemini-3.1-flash-lite-preview | maxTokens: 2048
-- Alternativa: node scripts/update-flor-ai-config-supabase.js
--             node scripts/update-flor-prompt-supabase.js

-- 1) flor_ai_config: modelo + tokens
DO $$
DECLARE
  v_existing jsonb;
  v_new jsonb;
BEGIN
  SELECT COALESCE(value::jsonb, '{}'::jsonb)
  INTO v_existing
  FROM system_config
  WHERE key = 'flor_ai_config';

  IF NOT FOUND THEN
    v_existing := jsonb_build_object(
      'enabled', true,
      'provider', 'gemini',
      'temperature', 0.3
    );
  END IF;

  v_new := v_existing
    || jsonb_build_object(
      'enabled', COALESCE((v_existing->>'enabled')::boolean, true),
      'provider', 'gemini',
      'model', 'gemini-3.1-flash-lite-preview',
      'maxTokens', 2048
    );

  INSERT INTO system_config (key, value, updated_at)
  VALUES ('flor_ai_config', v_new::text, NOW())
  ON CONFLICT (key) DO UPDATE
  SET value = EXCLUDED.value,
      updated_at = NOW();
END $$;

-- 2) Prompt: si aún dice "30 minutos" de silencio, pasar a 45 (V.4.1 docs ya usa 45)
UPDATE system_config
SET
  value = replace(value, 'tras 30 minutos de inactividad humana', 'tras 45 minutos de inactividad humana'),
  updated_at = NOW()
WHERE key = 'flor_general_config'
  AND value LIKE '%tras 30 minutos de inactividad humana%';

-- Verificar:
-- SELECT key, value::json->>'model' AS model, value::json->>'maxTokens' AS max_tokens
-- FROM system_config WHERE key = 'flor_ai_config';
-- SELECT (value::json->>'promptGeneral') ILIKE '%45 minutos%' AS silencio_45
-- FROM system_config WHERE key = 'flor_general_config';
