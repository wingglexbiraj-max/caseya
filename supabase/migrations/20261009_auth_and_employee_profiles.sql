-- =============================================================================
-- CASEYA DAIRY PLANT ERP — PRODUCTION AUTHENTICATION & EMPLOYEE PROFILES SCHEMA
-- Migration: 20261009_auth_and_employee_profiles.sql
-- =============================================================================

-- 1. Create employee_profiles table linked to auth.users
CREATE TABLE IF NOT EXISTS public.employee_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Employee' CHECK (role IN ('Admin', 'Plant Manager', 'Employee')),
    employee_code TEXT NOT NULL DEFAULT 'EMP-01',
    department TEXT NOT NULL DEFAULT 'Processing & Operations',
    account_status TEXT NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'disabled', 'invited')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for performance & security queries
CREATE INDEX IF NOT EXISTS idx_employee_profiles_email ON public.employee_profiles(email);
CREATE INDEX IF NOT EXISTS idx_employee_profiles_role ON public.employee_profiles(role);
CREATE INDEX IF NOT EXISTS idx_employee_profiles_status ON public.employee_profiles(account_status);

-- 2. Anti-recursion Security Definer helper functions
-- Marked SECURITY DEFINER with explicit search_path = public to avoid RLS recursion loops

CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role 
    FROM public.employee_profiles 
    WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.employee_profiles 
        WHERE id = auth.uid() 
          AND role = 'Admin' 
          AND account_status = 'active'
    );
$$;

CREATE OR REPLACE FUNCTION public.is_account_active()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.employee_profiles 
        WHERE id = auth.uid() 
          AND account_status = 'active'
    );
$$;

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.employee_profiles ENABLE ROW LEVEL SECURITY;

-- Deny all by default is inherent in Supabase Postgres once RLS is enabled.
-- Explicit policies:

-- A. SELECT Policy:
-- - Users can read their own profile
-- - Admins can read all profiles
-- - Plant Managers can view all employee profiles
DROP POLICY IF EXISTS "employee_profiles_select_policy" ON public.employee_profiles;
CREATE POLICY "employee_profiles_select_policy" ON public.employee_profiles
    FOR SELECT
    TO authenticated
    USING (
        id = auth.uid() 
        OR public.is_admin() 
        OR public.get_current_user_role() = 'Plant Manager'
    );

-- B. INSERT Policy:
-- - Only Admins or system trigger can insert new profiles
DROP POLICY IF EXISTS "employee_profiles_insert_policy" ON public.employee_profiles;
CREATE POLICY "employee_profiles_insert_policy" ON public.employee_profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.is_admin()
    );

-- C. UPDATE Policy:
-- - Users can update their own row OR Admins can update any row
DROP POLICY IF EXISTS "employee_profiles_update_policy" ON public.employee_profiles;
CREATE POLICY "employee_profiles_update_policy" ON public.employee_profiles
    FOR UPDATE
    TO authenticated
    USING (
        id = auth.uid() OR public.is_admin()
    )
    WITH CHECK (
        id = auth.uid() OR public.is_admin()
    );

-- D. DELETE Policy:
-- - Only Admins can delete employee profiles
DROP POLICY IF EXISTS "employee_profiles_delete_policy" ON public.employee_profiles;
CREATE POLICY "employee_profiles_delete_policy" ON public.employee_profiles
    FOR DELETE
    TO authenticated
    USING (
        public.is_admin()
    );

-- 4. Trigger to prevent non-admins from escalating their own role or status
CREATE OR REPLACE FUNCTION public.enforce_profile_update_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- If user is NOT an active admin, block modification of role or account_status
    IF NOT public.is_admin() THEN
        IF NEW.role IS DISTINCT FROM OLD.role THEN
            RAISE EXCEPTION 'Access Denied: Only plant administrators can modify employee roles.';
        END IF;
        IF NEW.account_status IS DISTINCT FROM OLD.account_status THEN
            RAISE EXCEPTION 'Access Denied: Only plant administrators can modify account statuses.';
        END IF;
        IF NEW.employee_code IS DISTINCT FROM OLD.employee_code THEN
            RAISE EXCEPTION 'Access Denied: Employee codes are immutable.';
        END IF;
    END IF;

    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_enforce_profile_rules ON public.employee_profiles;
CREATE TRIGGER trigger_enforce_profile_rules
    BEFORE UPDATE ON public.employee_profiles
    FOR EACH ROW EXECUTE FUNCTION public.enforce_profile_update_rules();

-- 5. Trigger on auth.users to auto-create employee_profile upon signup or invitation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.employee_profiles (
        id,
        email,
        full_name,
        role,
        employee_code,
        department,
        account_status
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'Employee'),
        COALESCE(NEW.raw_user_meta_data->>'employee_code', 'EMP-' || upper(substr(md5(NEW.id::text), 1, 4))),
        COALESCE(NEW.raw_user_meta_data->>'department', 'Processing & Operations'),
        'active'
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = timezone('utc'::text, now());

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. RPC Administrative Employee Provisioning Function
CREATE OR REPLACE FUNCTION public.provision_employee(
    p_email TEXT,
    p_full_name TEXT,
    p_role TEXT,
    p_employee_code TEXT,
    p_department TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_new_id UUID;
BEGIN
    -- Verify calling user is an Admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Only administrators can provision employee records.';
    END IF;

    -- Validate role
    IF p_role NOT IN ('Admin', 'Plant Manager', 'Employee') THEN
        RAISE EXCEPTION 'Invalid role: must be Admin, Plant Manager, or Employee.';
    END IF;

    -- Upsert invitation record
    INSERT INTO public.employee_profiles (
        id,
        email,
        full_name,
        role,
        employee_code,
        department,
        account_status
    )
    VALUES (
        gen_random_uuid(),
        p_email,
        p_full_name,
        p_role,
        p_employee_code,
        p_department,
        'invited'
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        employee_code = EXCLUDED.employee_code,
        department = EXCLUDED.department,
        updated_at = timezone('utc'::text, now());

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Employee provisioned successfully with role ' || p_role
    );
END;
$$;

-- 7. First Administrator Bootstrap Instructions
-- Run this query after creating your first user via Supabase Dashboard -> Authentication:
-- 
-- UPDATE public.employee_profiles 
-- SET role = 'Admin', account_status = 'active', full_name = 'Plant Head'
-- WHERE email = 'your-admin-email@caseya-plant.com';
