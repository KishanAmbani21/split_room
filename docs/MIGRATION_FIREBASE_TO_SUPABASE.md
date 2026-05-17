# Firebase → Supabase Migration Guide

This app now uses:

| Concern | Technology |
|---------|------------|
| Auth | Supabase Auth (email/password) |
| Database | Supabase PostgreSQL |
| Realtime | Supabase Realtime |
| Push notifications | Firebase Cloud Messaging (FCM) only |

Firebase **Firestore** and **Realtime Database** are no longer used.

---

## 1. Supabase project setup

1. Create a project at [supabase.com](https://supabase.com).
2. Run the SQL in `supabase/migrations/001_initial_schema.sql` in **SQL Editor**.
3. Enable **Realtime** for: `groups`, `group_members`, `expenses`, `expense_splits`, `group_logs`, `notifications` (included in migration).
4. Under **Authentication → Providers**, enable **Email**.

---

## 2. Flutter environment (secure keys)

Copy `env.example.json` → `env.json` (gitignored) and fill:

```json
{
  "SUPABASE_URL": "https://YOUR_REF.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

Run:

```bash
flutter run --dart-define-from-file=env.json
```

Never commit `env.json` or service role keys to the client app.

---

## 3. FCM edge function

Deploy `supabase/functions/send-fcm` and set secrets:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY` (Firebase service account JSON, private key with `\n`)

```bash
supabase functions deploy send-fcm
supabase secrets set FIREBASE_PROJECT_ID=...
```

The Flutter app stores `fcm_token` on `users` at login and invokes `send-fcm` when creating in-app notifications.

---

## 4. Data migration from Firestore (existing users)

Firebase Auth UIDs are **strings**; Supabase uses **UUIDs**. Choose one:

### Option A — Fresh start (simplest)

1. Export Firestore data for reference.
2. Users re-register with Supabase Auth (same email).
3. Manually recreate groups or import via script with new UUIDs.

### Option B — Scripted migration

1. Export Firestore collections: `users`, `groups`, `group_members`, `expenses`, `group_logs`, `notifications`.
2. Create Supabase users via Admin API; map `old_firebase_uid → new_supabase_uuid`.
3. Transform documents to snake_case columns (see `001_initial_schema.sql`).
4. Split embedded `splits[]` into `expense_splits` rows.
5. Import with `COPY` or batch `insert` using service role (server-side only).

### Field mapping (Firestore → PostgreSQL)

| Firestore | PostgreSQL |
|-----------|------------|
| `users/{uid}` | `users.id` (UUID) |
| `groups/{id}` | `groups.id` |
| `memberIds` | `groups.member_ids` + `group_members` |
| `memberDetails` | `groups.member_details` (JSONB) |
| `expenses.splits[]` | `expense_splits` table |
| `fcmToken` | `users.fcm_token` |

---

## 5. Architecture (Flutter)

```
lib/
  core/
    config/env_config.dart
    supabase/supabase_bootstrap.dart
    services/
      supabase_auth_service.dart
      supabase_realtime_service.dart
      fcm_push_service.dart
  features/
    auth/data/auth_repository.dart
    groups/repositories/group_repository.dart
    groups/services/
    expenses/services/
    notifications/services/
    dashboard/services/
```

---

## 6. Realtime subscriptions

`SupabaseRealtimeService` listens to:

- `groups` + `group_members` → user group list
- `expenses` + `expense_splits` → group expenses
- `group_logs` → activity feed
- `notifications` → in-app notifications

---

## 7. Security (RLS)

Policies in `001_initial_schema.sql`:

- Authenticated users only
- Group data visible only to `group_members`
- Notifications readable only by `user_id`
- Expenses restricted to group members

---

## 8. Dashboard analytics

Call RPC `get_dashboard_analytics()` for a single round-trip:

- Total spent / monthly totals
- Pending balances
- Amount to receive
- Group-wise expense breakdown

---

## 9. Verification checklist

- [ ] SQL migration applied
- [ ] `env.json` configured
- [ ] Sign up / login works
- [ ] Create group → members see it in realtime
- [ ] Add expense → splits + logs + notifications
- [ ] FCM token saved on dashboard load
- [ ] Edge function sends push on new notification
- [ ] RLS blocks non-members from other groups
