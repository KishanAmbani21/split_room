-- Restore RPCs, membership select fix, dashboard log limit

-- Users can always read their own group_members rows
DROP POLICY IF EXISTS group_members_select ON public.group_members;
CREATE POLICY group_members_select ON public.group_members FOR SELECT TO authenticated
  USING (
    (user_id = auth.uid() OR public.is_group_member(group_id))
    AND deleted_at IS NULL
  );

-- Restore a deleted expense from a group_logs row (bypasses created_by RLS on insert)
CREATE OR REPLACE FUNCTION public.restore_expense_from_log(p_log_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_log public.group_logs%ROWTYPE;
  v_snapshot JSONB;
  v_expense JSONB;
  v_expense_id UUID;
  v_group_id UUID;
  v_amount NUMERIC;
  v_split JSONB;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_log
  FROM public.group_logs
  WHERE id = p_log_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Activity not found';
  END IF;

  IF v_log.restored THEN
    RAISE EXCEPTION 'Already restored';
  END IF;

  IF v_log.action_type <> 'EXPENSE_DELETED' THEN
    RAISE EXCEPTION 'Not an expense deletion log';
  END IF;

  IF NOT public.is_group_member(v_log.group_id) THEN
    RAISE EXCEPTION 'Not a group member';
  END IF;

  v_snapshot := v_log.deleted_snapshot;
  IF v_snapshot IS NULL THEN
    RAISE EXCEPTION 'Deleted expense data missing';
  END IF;

  v_expense_id := COALESCE(
    (v_snapshot->>'id')::UUID,
    (v_snapshot->>'expenseId')::UUID
  );
  IF v_expense_id IS NULL THEN
    RAISE EXCEPTION 'Expense id missing';
  END IF;

  IF EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = v_expense_id AND e.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'Expense already exists';
  END IF;

  v_group_id := COALESCE(
    (v_snapshot->>'group_id')::UUID,
    (v_snapshot->>'groupId')::UUID,
    v_log.group_id
  );
  v_amount := COALESCE((v_snapshot->>'amount')::NUMERIC, 0);

  INSERT INTO public.expenses (
    id, group_id, group_name, title, amount, paid_by, paid_by_name,
    category, split_type, notes, receipt_image, created_by, member_ids,
    expense_date, created_at
  ) VALUES (
    v_expense_id,
    v_group_id,
    COALESCE(v_snapshot->>'group_name', v_snapshot->>'groupName', ''),
    COALESCE(v_snapshot->>'title', 'Expense'),
    v_amount,
    COALESCE((v_snapshot->>'paid_by')::UUID, (v_snapshot->>'paidBy')::UUID),
    COALESCE(v_snapshot->>'paid_by_name', v_snapshot->>'paidByName', 'Someone'),
    COALESCE(v_snapshot->>'category', 'Other'),
    COALESCE(v_snapshot->>'split_type', v_snapshot->>'splitType', 'equal'),
    COALESCE(v_snapshot->>'notes', ''),
    COALESCE(v_snapshot->>'receipt_image', v_snapshot->>'receiptImage', ''),
    auth.uid(),
    COALESCE(
      ARRAY(SELECT jsonb_array_elements_text(v_snapshot->'member_ids')),
      ARRAY(SELECT jsonb_array_elements_text(v_snapshot->'memberIds')),
      '{}'::TEXT[]
    )::UUID[],
    COALESCE(
      (v_snapshot->>'expense_date')::TIMESTAMPTZ,
      (v_snapshot->>'expenseDate')::TIMESTAMPTZ
    ),
    COALESCE(
      (v_snapshot->>'created_at')::TIMESTAMPTZ,
      (v_snapshot->>'createdAt')::TIMESTAMPTZ,
      NOW()
    )
  );

  FOR v_split IN SELECT * FROM jsonb_array_elements(COALESCE(v_snapshot->'splits', '[]'::jsonb))
  LOOP
    INSERT INTO public.expense_splits (expense_id, user_id, user_name, amount)
    VALUES (
      v_expense_id,
      COALESCE((v_split->>'user_id')::UUID, (v_split->>'userId')::UUID),
      COALESCE(v_split->>'user_name', v_split->>'userName', 'Member'),
      COALESCE((v_split->>'amount')::NUMERIC, 0)
    );
  END LOOP;

  UPDATE public.groups
  SET total_expense = total_expense + v_amount,
      updated_at = NOW()
  WHERE id = v_group_id AND deleted_at IS NULL;

  UPDATE public.group_logs SET restored = TRUE WHERE id = p_log_id;

  INSERT INTO public.group_logs (
    group_id, action_type, created_by, created_by_name, member_ids
  ) VALUES (
    v_group_id, 'ACTIVITY_RESTORED', auth.uid(),
    COALESCE((SELECT full_name FROM public.users WHERE id = auth.uid()), 'Member'),
    v_log.member_ids
  );
END;
$$;

-- Restore a soft-deleted group from a GROUP_DELETED log
CREATE OR REPLACE FUNCTION public.restore_group_from_log(p_log_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_log public.group_logs%ROWTYPE;
  v_snapshot JSONB;
  v_group_id UUID;
  v_member JSONB;
  v_expense JSONB;
  v_split JSONB;
  v_expense_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_log
  FROM public.group_logs
  WHERE id = p_log_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Activity not found';
  END IF;

  IF v_log.restored THEN
    RAISE EXCEPTION 'Already restored';
  END IF;

  IF v_log.action_type <> 'GROUP_DELETED' THEN
    RAISE EXCEPTION 'Not a group deletion log';
  END IF;

  v_snapshot := v_log.deleted_snapshot;
  IF v_snapshot IS NULL THEN
    RAISE EXCEPTION 'Deleted group data missing';
  END IF;

  v_group_id := COALESCE(
    (v_snapshot->'group'->>'id')::UUID,
    (v_snapshot->>'groupId')::UUID,
    v_log.group_id
  );

  IF EXISTS (SELECT 1 FROM public.groups g WHERE g.id = v_group_id AND g.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'Group already exists';
  END IF;

  -- Restore group row
  INSERT INTO public.groups (
    id, group_name, group_name_lower, group_image, description,
    created_by, creator_name, member_ids, member_details,
    total_expense, group_type, split_type, currency,
    last_expense_at, created_at, updated_at, deleted_at
  )
  SELECT
    v_group_id,
    COALESCE(g->>'group_name', g->>'groupName'),
    COALESCE(g->>'group_name_lower', g->>'groupNameLower', LOWER(COALESCE(g->>'group_name', g->>'groupName'))),
    COALESCE(g->>'group_image', g->>'groupImage', ''),
    COALESCE(g->>'description', ''),
    COALESCE((g->>'created_by')::UUID, (g->>'createdBy')::UUID),
    COALESCE(g->>'creator_name', g->>'creatorName', ''),
    COALESCE(
      ARRAY(SELECT jsonb_array_elements_text(g->'member_ids')),
      ARRAY(SELECT jsonb_array_elements_text(g->'memberIds')),
      '{}'::TEXT[]
    )::UUID[],
    COALESCE(g->'member_details', g->'memberDetails', '[]'::jsonb),
    COALESCE((g->>'total_expense')::NUMERIC, (g->>'totalExpense')::NUMERIC, 0),
    COALESCE(g->>'group_type', g->>'groupType', 'room'),
    COALESCE(g->>'split_type', g->>'splitType', 'equal'),
    COALESCE(g->>'currency', 'INR'),
    COALESCE((g->>'last_expense_at')::TIMESTAMPTZ, (g->>'lastExpenseAt')::TIMESTAMPTZ),
    COALESCE((g->>'created_at')::TIMESTAMPTZ, (g->>'createdAt')::TIMESTAMPTZ, NOW()),
    NOW(),
    NULL
  FROM (SELECT v_snapshot->'group' AS g) s
  ON CONFLICT (id) DO UPDATE SET
    deleted_at = NULL,
    updated_at = NOW();

  -- Restore group members
  FOR v_member IN SELECT * FROM jsonb_array_elements(COALESCE(v_snapshot->'group_members', '[]'::jsonb))
  LOOP
    INSERT INTO public.group_members (
      group_id, user_id, user_name, user_email, added_by, is_creator, deleted_at
    ) VALUES (
      v_group_id,
      COALESCE((v_member->>'user_id')::UUID, (v_member->>'userId')::UUID),
      COALESCE(v_member->>'user_name', v_member->>'userName', 'Member'),
      COALESCE(v_member->>'user_email', v_member->>'userEmail', ''),
      COALESCE((v_member->>'added_by')::UUID, (v_member->>'addedBy')::UUID),
      COALESCE((v_member->>'is_creator')::BOOLEAN, (v_member->>'isCreator')::BOOLEAN, FALSE),
      NULL
    )
    ON CONFLICT (group_id, user_id) DO UPDATE SET
      deleted_at = NULL,
      user_name = EXCLUDED.user_name,
      updated_at = NOW();
  END LOOP;

  -- Restore expenses and splits
  FOR v_expense IN SELECT * FROM jsonb_array_elements(COALESCE(v_snapshot->'expenses', '[]'::jsonb))
  LOOP
    v_expense_id := COALESCE(
      (v_expense->>'id')::UUID,
      (v_expense->>'expenseId')::UUID
    );
    IF v_expense_id IS NULL THEN
      CONTINUE;
    END IF;

    INSERT INTO public.expenses (
      id, group_id, group_name, title, amount, paid_by, paid_by_name,
      category, split_type, notes, receipt_image, created_by, member_ids,
      expense_date, created_at, deleted_at
    ) VALUES (
      v_expense_id,
      v_group_id,
      COALESCE(v_expense->>'group_name', v_expense->>'groupName', ''),
      COALESCE(v_expense->>'title', 'Expense'),
      COALESCE((v_expense->>'amount')::NUMERIC, 0),
      COALESCE((v_expense->>'paid_by')::UUID, (v_expense->>'paidBy')::UUID),
      COALESCE(v_expense->>'paid_by_name', v_expense->>'paidByName', 'Someone'),
      COALESCE(v_expense->>'category', 'Other'),
      COALESCE(v_expense->>'split_type', v_expense->>'splitType', 'equal'),
      COALESCE(v_expense->>'notes', ''),
      COALESCE(v_expense->>'receipt_image', v_expense->>'receiptImage', ''),
      auth.uid(),
      COALESCE(
        ARRAY(SELECT jsonb_array_elements_text(v_expense->'member_ids')),
        ARRAY(SELECT jsonb_array_elements_text(v_expense->'memberIds')),
        '{}'::TEXT[]
      )::UUID[],
      COALESCE(
        (v_expense->>'expense_date')::TIMESTAMPTZ,
        (v_expense->>'expenseDate')::TIMESTAMPTZ
      ),
      COALESCE(
        (v_expense->>'created_at')::TIMESTAMPTZ,
        (v_expense->>'createdAt')::TIMESTAMPTZ,
        NOW()
      ),
      NULL
    )
    ON CONFLICT (id) DO UPDATE SET deleted_at = NULL, updated_at = NOW();

    DELETE FROM public.expense_splits WHERE expense_id = v_expense_id;

    FOR v_split IN SELECT * FROM jsonb_array_elements(COALESCE(v_expense->'splits', '[]'::jsonb))
    LOOP
      INSERT INTO public.expense_splits (expense_id, user_id, user_name, amount)
      VALUES (
        v_expense_id,
        COALESCE((v_split->>'user_id')::UUID, (v_split->>'userId')::UUID),
        COALESCE(v_split->>'user_name', v_split->>'userName', 'Member'),
        COALESCE((v_split->>'amount')::NUMERIC, 0)
      );
    END LOOP;
  END LOOP;

  UPDATE public.group_logs SET restored = TRUE WHERE id = p_log_id;

  INSERT INTO public.group_logs (
    group_id, action_type, created_by, created_by_name, member_ids
  ) VALUES (
    v_group_id, 'ACTIVITY_RESTORED', auth.uid(),
    COALESCE((SELECT full_name FROM public.users WHERE id = auth.uid()), 'Member'),
    v_log.member_ids
  );
END;
$$;

-- Dashboard: only member groups, more activity logs
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
      SELECT jsonb_agg(to_jsonb(g.*) ORDER BY COALESCE(g.last_expense_at, g.updated_at) DESC NULLS LAST)
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
        WHERE gl.deleted_at IS NULL
          AND (
            gl.group_id = ANY(v_group_ids)
            OR (
              gl.action_type = 'GROUP_DELETED'
              AND p_user_id = ANY(gl.member_ids)
            )
          )
        ORDER BY gl.timestamp DESC
        LIMIT 50
      ) gl
    ), '[]'::jsonb)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.restore_expense_from_log(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_group_from_log(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
