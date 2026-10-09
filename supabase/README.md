# Supabase Authentication & Database Setup Guide for CASEYA

This directory contains the production schema, Row Level Security (RLS) policies, and administrative Edge Functions for the **CASEYA Dairy Plant ERP** authentication system.

---

## 1. Apply Database Migrations

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard) and select your project.
2. Navigate to **SQL Editor** in the left sidebar.
3. Open `supabase/migrations/20261009_auth_and_employee_profiles.sql`.
4. Copy and paste the entire script into the SQL editor and click **Run**.

This script will create:
- `public.employee_profiles` table linked to `auth.users(id)`
- Anti-recursion security helper functions (`is_admin()`, `get_current_user_role()`, `is_account_active()`)
- Explicit Row Level Security (RLS) policies for `SELECT`, `INSERT`, `UPDATE`, `DELETE`
- Security triggers preventing regular employees from elevating their own role
- Auto-provisioning trigger when users are created or invited
- RPC function `provision_employee()` for administrative operations

---

## 2. Configure Supabase Auth Settings

In your Supabase Dashboard:

1. **Authentication > Providers > Email**:
   - **Enable Email Provider**: `ON`
   - **Confirm Email**: `ON` (recommended) or `OFF` for instant login
   - **Secure Password Rules**: Minimum 8 characters
   - **Allow new users to sign up**: `OFF`  
     *(CRITICAL: Disabling public signups ensures Caseya remains strictly invitation-only for plant employees)*

2. **Authentication > URL Configuration**:
   - **Site URL**: `https://your-caseya-domain.vercel.app` (or `http://localhost:8080` for local testing)
   - **Redirect URLs** (add both):
     - `https://your-caseya-domain.vercel.app/reset-password`
     - `https://your-caseya-domain.vercel.app/callback`
     - `http://localhost:8080/reset-password`
     - `http://localhost:8080/callback`

---

## 3. Creating Your First Plant Administrator

To bootstrap your initial admin account:

1. In Supabase Dashboard, go to **Authentication > Users**.
2. Click **Add user** > **Create user**.
3. Enter your administrative email and password (e.g. `biraj.goswami@caseya-plant.com`).
4. In the **SQL Editor**, run the following query to grant the Admin role:

```sql
UPDATE public.employee_profiles
SET 
    role = 'Admin',
    account_status = 'active',
    full_name = 'Biraj Goswami',
    employee_code = 'ADMIN-01',
    department = 'Processing & Operations'
WHERE email = 'biraj.goswami@caseya-plant.com';
```

Now you can sign in at `/login` with full administrator privileges!

---

## 4. (Optional) Deploying the `invite-employee` Edge Function

If using the Supabase CLI:

```bash
supabase functions deploy invite-employee --no-verify-jwt
```

The function uses the Supabase service-role key on the server to dispatch official invitation emails with custom user metadata.
