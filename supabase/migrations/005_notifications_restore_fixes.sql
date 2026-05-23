-- Fix restore foundations and notification realtime reliability.

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN others THEN
      RAISE NOTICE 'Realtime add skipped for notifications: %', SQLERRM;
  END;
END $$;

-- Keep delete logs available by soft-deleting groups instead of hard-deleting
-- rows that are referenced by group_logs.
CREATE OR REPLACE FUNCTION public.soft_delete_group(
  p_group_id UUID,
  p_deleted_by_name TEXT DEFAULT 'Member'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group public.groups%ROWTYPE;
  v_members JSONB;
  v_expenses JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_group
  FROM public.groups
  WHERE id = p_group_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Group not found';
  END IF;

  IF v_group.created_by <> auth.uid() THEN
    RAISE EXCEPTION 'Only the group creator can delete this group';
  END IF;

  SELECT COALESCE(jsonb_agg(to_jsonb(gm.*)), '[]'::jsonb)
  INTO v_members
  FROM public.group_members gm
  WHERE gm.group_id = p_group_id;

  SELECT COALESCE(jsonb_agg(expense_row), '[]'::jsonb)
  INTO v_expenses
  FROM (
    SELECT to_jsonb(e.*) ||
      jsonb_build_object(
        'splits',
        COALESCE((
          SELECT jsonb_agg(to_jsonb(es.*))
          FROM public.expense_splits es
          WHERE es.expense_id = e.id
        ), '[]'::jsonb)
      ) AS expense_row
    FROM public.expenses e
    WHERE e.group_id = p_group_id
  ) s;

  INSERT INTO public.group_logs (
    group_id,
    action_type,
    created_by,
    created_by_name,
    member_ids,
    deleted_snapshot
  ) VALUES (
    p_group_id,
    'GROUP_DELETED',
    auth.uid(),
    COALESCE(NULLIF(TRIM(p_deleted_by_name), ''), 'Member'),
    v_group.member_ids,
    jsonb_build_object(
      'group', to_jsonb(v_group),
      'groupId', p_group_id,
      'group_members', v_members,
      'expenses', v_expenses
    )
  );

  UPDATE public.expense_splits es
  SET deleted_at = NOW()
  WHERE EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = es.expense_id AND e.group_id = p_group_id
  );

  UPDATE public.expenses
  SET deleted_at = NOW(), updated_at = NOW()
  WHERE group_id = p_group_id;

  UPDATE public.group_members
  SET deleted_at = NOW(), updated_at = NOW()
  WHERE group_id = p_group_id;

  UPDATE public.groups
  SET deleted_at = NOW(), updated_at = NOW()
  WHERE id = p_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.soft_delete_group(UUID, TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';
