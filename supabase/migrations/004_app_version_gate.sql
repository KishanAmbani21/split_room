-- DB-managed app version gate.
-- Increase min_supported_build and set force_update = true to block older APKs.

CREATE TABLE IF NOT EXISTS public.app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform TEXT NOT NULL UNIQUE,
  min_supported_build INTEGER NOT NULL DEFAULT 1,
  latest_build INTEGER NOT NULL DEFAULT 1,
  latest_version TEXT NOT NULL DEFAULT '1.0.0',
  update_message TEXT NOT NULL DEFAULT 'A new update is available. Please install the latest build.',
  force_update BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS app_versions_updated_at ON public.app_versions;
CREATE TRIGGER app_versions_updated_at
  BEFORE UPDATE ON public.app_versions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

INSERT INTO public.app_versions (
  platform,
  min_supported_build,
  latest_build,
  latest_version,
  update_message,
  force_update,
  is_active
) VALUES (
  'android',
  1,
  2,
  '1.0.1',
  'New build is available. Please install latest version.',
  FALSE,
  TRUE
)
ON CONFLICT (platform) DO NOTHING;

ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS app_versions_select_anon ON public.app_versions;
CREATE POLICY app_versions_select_anon ON public.app_versions FOR SELECT TO anon
  USING (is_active = TRUE);

DROP POLICY IF EXISTS app_versions_select_auth ON public.app_versions;
CREATE POLICY app_versions_select_auth ON public.app_versions FOR SELECT TO authenticated
  USING (is_active = TRUE);

GRANT SELECT ON public.app_versions TO anon;
GRANT SELECT ON public.app_versions TO authenticated;

NOTIFY pgrst, 'reload schema';
