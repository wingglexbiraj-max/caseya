-- =============================================================================
-- CASEYA DAIRY PLANT ERP — PRODUCTION DISPATCH MANAGEMENT SCHEMA
-- Migration: 20261009_dispatch_management.sql
-- =============================================================================

-- 1. Create dispatch_entries table (Parent record for vehicle dispatch)
CREATE TABLE IF NOT EXISTS public.dispatch_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispatch_date DATE NOT NULL DEFAULT CURRENT_DATE,
    dispatched_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    dispatch_time TEXT NOT NULL DEFAULT to_char(timezone('utc'::text, now()), 'HH12:MI AM'),
    vehicle_number TEXT NOT NULL,
    distributor_name TEXT NOT NULL,
    driver_name TEXT DEFAULT '',
    route TEXT DEFAULT '',
    remarks TEXT DEFAULT '',
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'cancelled', 'pending')),
    created_by TEXT NOT NULL DEFAULT 'Dispatch Officer',
    updated_by TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Create dispatch_entry_items table (Line items per product in vehicle)
CREATE TABLE IF NOT EXISTS public.dispatch_entry_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispatch_entry_id UUID NOT NULL REFERENCES public.dispatch_entries(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    product_name TEXT NOT NULL,
    short_code TEXT NOT NULL DEFAULT '',
    item_code TEXT NOT NULL DEFAULT '',
    input_mode TEXT NOT NULL DEFAULT 'Pieces' CHECK (input_mode IN ('Pieces', 'Crates', 'Litres', 'Kg')),
    input_quantity NUMERIC(12, 3) NOT NULL CHECK (input_quantity > 0),
    crates NUMERIC(10, 2) NOT NULL DEFAULT 0,
    pieces INT NOT NULL DEFAULT 0,
    normalized_quantity NUMERIC(12, 3) NOT NULL DEFAULT 0,
    normalized_unit TEXT NOT NULL DEFAULT 'Litres' CHECK (normalized_unit IN ('Litres', 'Kg')),
    pack_size NUMERIC(10, 2) NOT NULL DEFAULT 0,
    pack_size_display TEXT DEFAULT '',
    pieces_per_crate INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for performance on reporting & filtering
CREATE INDEX IF NOT EXISTS idx_dispatch_entries_date ON public.dispatch_entries(dispatch_date);
CREATE INDEX IF NOT EXISTS idx_dispatch_entries_vehicle ON public.dispatch_entries(vehicle_number);
CREATE INDEX IF NOT EXISTS idx_dispatch_entries_distributor ON public.dispatch_entries(distributor_name);
CREATE INDEX IF NOT EXISTS idx_dispatch_entry_items_entry_id ON public.dispatch_entry_items(dispatch_entry_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_entry_items_product_id ON public.dispatch_entry_items(product_id);

-- 3. Row Level Security (RLS) Policies
ALTER TABLE public.dispatch_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispatch_entry_items ENABLE ROW LEVEL SECURITY;

-- Dispatch Entries Policies
DROP POLICY IF EXISTS "dispatch_entries_select_policy" ON public.dispatch_entries;
CREATE POLICY "dispatch_entries_select_policy" ON public.dispatch_entries
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "dispatch_entries_insert_policy" ON public.dispatch_entries;
CREATE POLICY "dispatch_entries_insert_policy" ON public.dispatch_entries
    FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "dispatch_entries_update_policy" ON public.dispatch_entries;
CREATE POLICY "dispatch_entries_update_policy" ON public.dispatch_entries
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "dispatch_entries_delete_policy" ON public.dispatch_entries;
CREATE POLICY "dispatch_entries_delete_policy" ON public.dispatch_entries
    FOR DELETE TO authenticated USING (
        public.is_admin() OR public.get_current_user_role() = 'Plant Manager'
    );

-- Dispatch Entry Items Policies
DROP POLICY IF EXISTS "dispatch_entry_items_select_policy" ON public.dispatch_entry_items;
CREATE POLICY "dispatch_entry_items_select_policy" ON public.dispatch_entry_items
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "dispatch_entry_items_insert_policy" ON public.dispatch_entry_items;
CREATE POLICY "dispatch_entry_items_insert_policy" ON public.dispatch_entry_items
    FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "dispatch_entry_items_update_policy" ON public.dispatch_entry_items;
CREATE POLICY "dispatch_entry_items_update_policy" ON public.dispatch_entry_items
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "dispatch_entry_items_delete_policy" ON public.dispatch_entry_items;
CREATE POLICY "dispatch_entry_items_delete_policy" ON public.dispatch_entry_items
    FOR DELETE TO authenticated USING (
        public.is_admin() OR public.get_current_user_role() = 'Plant Manager'
    );

-- 4. Atomic RPC function to create or update vehicle dispatch transactionally
CREATE OR REPLACE FUNCTION public.save_vehicle_dispatch(
    p_dispatch JSONB,
    p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_dispatch_id UUID;
    v_item JSONB;
BEGIN
    -- Validate required fields
    IF (p_dispatch->>'vehicle_number') IS NULL OR length(trim(p_dispatch->>'vehicle_number')) = 0 THEN
        RAISE EXCEPTION 'Vehicle number is required';
    END IF;
    IF (p_dispatch->>'distributor_name') IS NULL OR length(trim(p_dispatch->>'distributor_name')) = 0 THEN
        RAISE EXCEPTION 'Distributor name is required';
    END IF;
    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'At least one product line is required for vehicle dispatch';
    END IF;

    -- Update existing record or insert new record
    IF (p_dispatch->>'id') IS NOT NULL AND length(p_dispatch->>'id') >= 32 THEN
        BEGIN
            v_dispatch_id := (p_dispatch->>'id')::UUID;
        EXCEPTION WHEN OTHERS THEN
            v_dispatch_id := gen_random_uuid();
        END;

        UPDATE public.dispatch_entries
        SET
            dispatch_date = COALESCE((p_dispatch->>'dispatch_date')::DATE, CURRENT_DATE),
            vehicle_number = upper(trim(p_dispatch->>'vehicle_number')),
            distributor_name = trim(p_dispatch->>'distributor_name'),
            driver_name = COALESCE(trim(p_dispatch->>'driver_name'), ''),
            route = COALESCE(trim(p_dispatch->>'route'), ''),
            remarks = COALESCE(trim(p_dispatch->>'remarks'), ''),
            dispatch_time = COALESCE(p_dispatch->>'dispatch_time', dispatch_time),
            updated_by = COALESCE(p_dispatch->>'updated_by', 'Dispatch Officer'),
            updated_at = timezone('utc'::text, now())
        WHERE id = v_dispatch_id;

        -- If not found, insert fresh
        IF NOT FOUND THEN
            INSERT INTO public.dispatch_entries (
                id,
                dispatch_date,
                vehicle_number,
                distributor_name,
                driver_name,
                route,
                remarks,
                dispatch_time,
                created_by
            )
            VALUES (
                v_dispatch_id,
                COALESCE((p_dispatch->>'dispatch_date')::DATE, CURRENT_DATE),
                upper(trim(p_dispatch->>'vehicle_number')),
                trim(p_dispatch->>'distributor_name'),
                COALESCE(trim(p_dispatch->>'driver_name'), ''),
                COALESCE(trim(p_dispatch->>'route'), ''),
                COALESCE(trim(p_dispatch->>'remarks'), ''),
                COALESCE(p_dispatch->>'dispatch_time', to_char(timezone('utc'::text, now()), 'HH12:MI AM')),
                COALESCE(p_dispatch->>'created_by', 'Dispatch Officer')
            );
        END IF;

        -- Clear previous lines to prevent duplication on edit
        DELETE FROM public.dispatch_entry_items WHERE dispatch_entry_id = v_dispatch_id;
    ELSE
        INSERT INTO public.dispatch_entries (
            dispatch_date,
            vehicle_number,
            distributor_name,
            driver_name,
            route,
            remarks,
            dispatch_time,
            created_by
        )
        VALUES (
            COALESCE((p_dispatch->>'dispatch_date')::DATE, CURRENT_DATE),
            upper(trim(p_dispatch->>'vehicle_number')),
            trim(p_dispatch->>'distributor_name'),
            COALESCE(trim(p_dispatch->>'driver_name'), ''),
            COALESCE(trim(p_dispatch->>'route'), ''),
            COALESCE(trim(p_dispatch->>'remarks'), ''),
            COALESCE(p_dispatch->>'dispatch_time', to_char(timezone('utc'::text, now()), 'HH12:MI AM')),
            COALESCE(p_dispatch->>'created_by', 'Dispatch Officer')
        )
        RETURNING id INTO v_dispatch_id;
    END IF;

    -- Insert product line items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        IF (v_item->>'input_quantity')::NUMERIC <= 0 THEN
            RAISE EXCEPTION 'Invalid quantity: % for product %', v_item->>'input_quantity', v_item->>'product_name';
        END IF;

        INSERT INTO public.dispatch_entry_items (
            dispatch_entry_id,
            product_id,
            product_name,
            short_code,
            item_code,
            input_mode,
            input_quantity,
            crates,
            pieces,
            normalized_quantity,
            normalized_unit,
            pack_size,
            pack_size_display,
            pieces_per_crate
        )
        VALUES (
            v_dispatch_id,
            v_item->>'product_id',
            v_item->>'product_name',
            COALESCE(v_item->>'short_code', ''),
            COALESCE(v_item->>'item_code', ''),
            COALESCE(v_item->>'input_mode', 'Pieces'),
            (v_item->>'input_quantity')::NUMERIC,
            COALESCE((v_item->>'crates')::NUMERIC, 0),
            COALESCE((v_item->>'pieces')::INT, 0),
            COALESCE((v_item->>'normalized_quantity')::NUMERIC, 0),
            COALESCE(v_item->>'normalized_unit', 'Litres'),
            COALESCE((v_item->>'pack_size')::NUMERIC, 0),
            COALESCE(v_item->>'pack_size_display', ''),
            COALESCE((v_item->>'pieces_per_crate')::INT, 1)
        );
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'dispatch_id', v_dispatch_id,
        'item_count', jsonb_array_length(p_items)
    );
END;
$$;
