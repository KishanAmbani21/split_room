-- Room Expense Manager — Supabase PostgreSQL schema
-- Run in Supabase Dashboard → SQL Editor (entire file, once)
--
-- Order: tables → triggers → functions (that reference tables) → RPCs → RLS

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- 1) Helper: updated_at (no table dependencies)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- 2) Tables (dependency order)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL UNIQUE,
  profile_image_url TEXT,
  fcm_token TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  login_type TEXT NOT NULL DEFAULT 'email',
  device_type TEXT NOT NULL DEFAULT 'android',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON public.users(fcm_token) WHERE fcm_token IS NOT NULL AND deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_name TEXT NOT NULL,
  group_name_lower TEXT NOT NULL,
  group_image TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  created_by UUID NOT NULL REFERENCES public.users(id),
  creator_name TEXT NOT NULL DEFAULT '',
  member_ids UUID[] NOT NULL DEFAULT '{}',
  member_details JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_expense NUMERIC(14, 2) NOT NULL DEFAULT 0,
  group_type TEXT NOT NULL DEFAULT 'room',
  split_type TEXT NOT NULL DEFAULT 'equal',
  currency TEXT NOT NULL DEFAULT 'INR',
  last_expense_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_groups_name_lower ON public.groups(group_name_lower) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_groups_created_by ON public.groups(created_by) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_groups_member_ids ON public.groups USING GIN (member_ids);

CREATE TABLE IF NOT EXISTS public.group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id),
  user_name TEXT NOT NULL DEFAULT '',
  user_email TEXT NOT NULL DEFAULT '',
  added_by UUID REFERENCES public.users(id),
  is_creator BOOLEAN NOT NULL DEFAULT FALSE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  group_name TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL,
  amount NUMERIC(14, 2) NOT NULL,
  paid_by UUID NOT NULL REFERENCES public.users(id),
  paid_by_name TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'Other',
  split_type TEXT NOT NULL DEFAULT 'equal',
  notes TEXT NOT NULL DEFAULT '',
  receipt_image TEXT NOT NULL DEFAULT '',
  expense_date TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES public.users(id),
  member_ids UUID[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_expenses_group ON public.expenses(group_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_expenses_paid_by ON public.expenses(paid_by) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON public.expenses(created_at DESC) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.expense_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id),
  user_name TEXT NOT NULL DEFAULT '',
  amount NUMERIC(14, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_expense_splits_expense ON public.expense_splits(expense_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_expense_splits_user ON public.expense_splits(user_id) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.group_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  action_message TEXT,
  created_by UUID REFERENCES public.users(id),
  created_by_name TEXT,
  member_ids UUID[] NOT NULL DEFAULT '{}',
  expense_data JSONB,
  member_data JSONB,
  group_data JSONB,
  full_data_snapshot JSONB,
  deleted_snapshot JSONB,
  restored BOOLEAN NOT NULL DEFAULT FALSE,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_group_logs_group_time ON public.group_logs(group_id, timestamp DESC) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  group_name TEXT NOT NULL DEFAULT '',
  group_image TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  created_by UUID REFERENCES public.users(id),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id) WHERE is_read = FALSE AND deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- 3) Table triggers
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS users_updated_at ON public.users;
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS groups_updated_at ON public.groups;
CREATE TRIGGER groups_updated_at
  BEFORE UPDATE ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS group_members_updated_at ON public.group_members;
CREATE TRIGGER group_members_updated_at
  BEFORE UPDATE ON public.group_members
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS expenses_updated_at ON public.expenses;
CREATE TRIGGER expenses_updated_at
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 4) Auth → public.users sync
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (
    NEW.id,
    LOWER(COALESCE(NEW.email, '')),
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill existing auth users into public.users
INSERT INTO public.users (id, email, full_name)
SELECT
  u.id,
  LOWER(COALESCE(u.email, '')),
  COALESCE(u.raw_user_meta_data->>'full_name', '')
FROM auth.users u
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 5) Functions that depend on tables (AFTER group_members exists)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_members gm
    WHERE gm.group_id = p_group_id
      AND gm.user_id = auth.uid()
      AND gm.deleted_at IS NULL
  );
$$;

-- ---------------------------------------------------------------------------
-- 6) Realtime publication (safe if already added)
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'groups', 'group_members', 'expenses', 'expense_splits', 'group_logs', 'notifications'
  ]
  LOOP
    BEGIN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        t
      );
    EXCEPTION
      WHEN duplicate_object THEN NULL;
      WHEN others THEN
        RAISE NOTICE 'Realtime add skipped for %: %', t, SQLERRM;
    END;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 7) RPCs
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_group_atomic(
  p_group_name TEXT,
  p_description TEXT,
  p_group_image TEXT,
  p_group_type TEXT,
  p_creator_name TEXT,
  p_currency TEXT,
  p_member_details JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group_id UUID;
  v_lower TEXT;
  v_member JSONB;
  v_uid UUID;
  v_member_ids UUID[] := ARRAY[]::UUID[];
  v_snapshot JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  v_lower := LOWER(TRIM(p_group_name));
  IF EXISTS (
    SELECT 1 FROM public.groups g
    WHERE g.deleted_at IS NULL AND g.group_name_lower = v_lower
  ) THEN
    RAISE EXCEPTION 'Group name already exists';
  END IF;

  v_group_id := gen_random_uuid();

  FOR v_member IN SELECT * FROM jsonb_array_elements(p_member_details)
  LOOP
    v_uid := (v_member->>'uid')::UUID;
    v_member_ids := array_append(v_member_ids, v_uid);
  END LOOP;

  INSERT INTO public.groups (
    id, group_name, group_name_lower, group_image, description,
    created_by, creator_name, member_ids, member_details,
    group_type, currency
  ) VALUES (
    v_group_id, TRIM(p_group_name), v_lower, COALESCE(p_group_image, ''),
    COALESCE(p_description, ''), auth.uid(), p_creator_name,
    v_member_ids, p_member_details, COALESCE(p_group_type, 'room'),
    COALESCE(p_currency, 'INR')
  );

  FOR v_member IN SELECT * FROM jsonb_array_elements(p_member_details)
  LOOP
    v_uid := (v_member->>'uid')::UUID;
    INSERT INTO public.group_members (
      group_id, user_id, user_name, user_email, added_by, is_creator
    ) VALUES (
      v_group_id, v_uid,
      COALESCE(v_member->>'name', 'Member'),
      COALESCE(v_member->>'email', ''),
      auth.uid(),
      COALESCE((v_member->>'isCreator')::BOOLEAN, FALSE)
    );
  END LOOP;

  v_snapshot := jsonb_build_object(
    'groupId', v_group_id,
    'groupName', TRIM(p_group_name),
    'memberIds', to_jsonb(v_member_ids)
  );

  INSERT INTO public.group_logs (
    group_id, action_type, action_message, created_by, created_by_name,
    member_ids, full_data_snapshot, group_data
  ) VALUES (
    v_group_id, 'GROUP_CREATED',
    p_creator_name || ' created ' || TRIM(p_group_name) || ' group',
    auth.uid(), p_creator_name, v_member_ids, v_snapshot, v_snapshot
  );

  RETURN v_group_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_expense_atomic(
  p_group_id UUID,
  p_group_name TEXT,
  p_title TEXT,
  p_amount NUMERIC,
  p_paid_by UUID,
  p_paid_by_name TEXT,
  p_category TEXT,
  p_split_type TEXT,
  p_notes TEXT,
  p_receipt_image TEXT,
  p_expense_date TIMESTAMPTZ,
  p_member_ids UUID[],
  p_splits JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_expense_id UUID;
  v_split JSONB;
BEGIN
  IF NOT public.is_group_member(p_group_id) THEN
    RAISE EXCEPTION 'Not a group member';
  END IF;

  v_expense_id := gen_random_uuid();

  INSERT INTO public.expenses (
    id, group_id, group_name, title, amount, paid_by, paid_by_name,
    category, split_type, notes, receipt_image, expense_date,
    created_by, member_ids
  ) VALUES (
    v_expense_id, p_group_id, p_group_name, TRIM(p_title), p_amount,
    p_paid_by, p_paid_by_name, COALESCE(p_category, 'Other'),
    COALESCE(p_split_type, 'equal'), COALESCE(p_notes, ''),
    COALESCE(p_receipt_image, ''), p_expense_date, auth.uid(), p_member_ids
  );

  FOR v_split IN SELECT * FROM jsonb_array_elements(p_splits)
  LOOP
    INSERT INTO public.expense_splits (expense_id, user_id, user_name, amount)
    VALUES (
      v_expense_id,
      (v_split->>'userId')::UUID,
      COALESCE(v_split->>'userName', 'Member'),
      (v_split->>'amount')::NUMERIC
    );
  END LOOP;

  UPDATE public.groups
  SET total_expense = total_expense + p_amount,
      last_expense_at = NOW(),
      updated_at = NOW()
  WHERE id = p_group_id AND deleted_at IS NULL;

  INSERT INTO public.group_logs (
    group_id, action_type, created_by, created_by_name, member_ids, expense_data
  ) VALUES (
    p_group_id, 'EXPENSE_ADDED', auth.uid(),
    (SELECT full_name FROM public.users WHERE id = auth.uid()),
    p_member_ids,
    jsonb_build_object(
      'expenseId', v_expense_id,
      'title', TRIM(p_title),
      'amount', p_amount,
      'paidBy', p_paid_by,
      'paidByName', p_paid_by_name
    )
  );

  RETURN v_expense_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_dashboard_analytics(p_user_id UUID DEFAULT auth.uid())
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_group_ids UUID[];
BEGIN
  IF p_user_id IS NULL OR p_user_id != auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT ARRAY_AGG(DISTINCT gm.group_id)
  INTO v_group_ids
  FROM public.group_members gm
  INNER JOIN public.groups g ON g.id = gm.group_id
  WHERE gm.user_id = p_user_id
    AND gm.deleted_at IS NULL
    AND g.deleted_at IS NULL;

  IF v_group_ids IS NULL THEN
    v_group_ids := ARRAY[]::UUID[];
  END IF;

  SELECT jsonb_build_object(
    'groups', COALESCE((
      SELECT jsonb_agg(to_jsonb(g.*))
      FROM public.groups g
      WHERE g.id = ANY(v_group_ids) AND g.deleted_at IS NULL
    ), '[]'::jsonb),
    'expenses', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', e.id,
          'group_id', e.group_id,
          'group_name', e.group_name,
          'title', e.title,
          'amount', e.amount,
          'paid_by', e.paid_by,
          'paid_by_name', e.paid_by_name,
          'category', e.category,
          'created_at', e.created_at,
          'splits', COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
              'userId', es.user_id,
              'userName', es.user_name,
              'amount', es.amount
            ))
            FROM public.expense_splits es
            WHERE es.expense_id = e.id AND es.deleted_at IS NULL
          ), '[]'::jsonb)
        )
      )
      FROM public.expenses e
      WHERE e.group_id = ANY(v_group_ids) AND e.deleted_at IS NULL
    ), '[]'::jsonb),
    'logs', COALESCE((
      SELECT jsonb_agg(to_jsonb(gl.*))
      FROM (
        SELECT * FROM public.group_logs gl
        WHERE gl.group_id = ANY(v_group_ids) AND gl.deleted_at IS NULL
        ORDER BY gl.timestamp DESC
        LIMIT 20
      ) gl
    ), '[]'::jsonb)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- ---------------------------------------------------------------------------
-- 8) Row Level Security
-- ---------------------------------------------------------------------------

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_select ON public.users;
CREATE POLICY users_select ON public.users FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

DROP POLICY IF EXISTS users_update_own ON public.users;
CREATE POLICY users_update_own ON public.users FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS users_insert_own ON public.users;
CREATE POLICY users_insert_own ON public.users FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS groups_select ON public.groups;
CREATE POLICY groups_select ON public.groups FOR SELECT TO authenticated
  USING (public.is_group_member(id) AND deleted_at IS NULL);

DROP POLICY IF EXISTS groups_insert ON public.groups;
CREATE POLICY groups_insert ON public.groups FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS groups_update ON public.groups;
CREATE POLICY groups_update ON public.groups FOR UPDATE TO authenticated
  USING (public.is_group_member(id) AND deleted_at IS NULL);

DROP POLICY IF EXISTS groups_delete ON public.groups;
CREATE POLICY groups_delete ON public.groups FOR DELETE TO authenticated
  USING (created_by = auth.uid());

DROP POLICY IF EXISTS group_members_select ON public.group_members;
CREATE POLICY group_members_select ON public.group_members FOR SELECT TO authenticated
  USING (public.is_group_member(group_id) AND deleted_at IS NULL);

DROP POLICY IF EXISTS group_members_insert ON public.group_members;
CREATE POLICY group_members_insert ON public.group_members FOR INSERT TO authenticated
  WITH CHECK (public.is_group_member(group_id) OR added_by = auth.uid());

DROP POLICY IF EXISTS group_members_update ON public.group_members;
CREATE POLICY group_members_update ON public.group_members FOR UPDATE TO authenticated
  USING (public.is_group_member(group_id));

DROP POLICY IF EXISTS expenses_select ON public.expenses;
CREATE POLICY expenses_select ON public.expenses FOR SELECT TO authenticated
  USING (public.is_group_member(group_id) AND deleted_at IS NULL);

DROP POLICY IF EXISTS expenses_insert ON public.expenses;
CREATE POLICY expenses_insert ON public.expenses FOR INSERT TO authenticated
  WITH CHECK (public.is_group_member(group_id) AND created_by = auth.uid());

DROP POLICY IF EXISTS expenses_update ON public.expenses;
CREATE POLICY expenses_update ON public.expenses FOR UPDATE TO authenticated
  USING (public.is_group_member(group_id) AND deleted_at IS NULL);

DROP POLICY IF EXISTS expenses_delete ON public.expenses;
CREATE POLICY expenses_delete ON public.expenses FOR DELETE TO authenticated
  USING (public.is_group_member(group_id));

DROP POLICY IF EXISTS expense_splits_select ON public.expense_splits;
CREATE POLICY expense_splits_select ON public.expense_splits FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.id = expense_id AND public.is_group_member(e.group_id)
    ) AND deleted_at IS NULL
  );

DROP POLICY IF EXISTS expense_splits_write ON public.expense_splits;
CREATE POLICY expense_splits_write ON public.expense_splits FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.id = expense_id AND public.is_group_member(e.group_id)
    )
  );

DROP POLICY IF EXISTS group_logs_select ON public.group_logs;
CREATE POLICY group_logs_select ON public.group_logs FOR SELECT TO authenticated
  USING (public.is_group_member(group_id) AND deleted_at IS NULL);

DROP POLICY IF EXISTS group_logs_insert ON public.group_logs;
CREATE POLICY group_logs_insert ON public.group_logs FOR INSERT TO authenticated
  WITH CHECK (public.is_group_member(group_id));

DROP POLICY IF EXISTS group_logs_update ON public.group_logs;
CREATE POLICY group_logs_update ON public.group_logs FOR UPDATE TO authenticated
  USING (public.is_group_member(group_id));

DROP POLICY IF EXISTS notifications_select ON public.notifications;
CREATE POLICY notifications_select ON public.notifications FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND deleted_at IS NULL);

DROP POLICY IF EXISTS notifications_insert ON public.notifications;
CREATE POLICY notifications_insert ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS notifications_update ON public.notifications;
CREATE POLICY notifications_update ON public.notifications FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

NOTIFY pgrst, 'reload schema';
