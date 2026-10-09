-- ==============================================================================
-- CASEYA PRODUCT MASTER SCHEMA & SEED MIGRATION
-- Migration: 20261009_products_master.sql
-- Description: Creates products_master table with RLS and seeds all 29 plant products
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.products_master (
    product_id VARCHAR(100) PRIMARY KEY,
    product_name VARCHAR(250) NOT NULL,
    item_code VARCHAR(100) DEFAULT 'NA',
    short_code VARCHAR(100) DEFAULT '',
    category VARCHAR(100) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    pack_size NUMERIC(12, 3) NOT NULL,
    pack_size_display VARCHAR(100) NOT NULL,
    pieces_per_crate INTEGER NOT NULL DEFAULT 0,
    per_crate_qty NUMERIC(12, 3),
    per_crate_qty_grams NUMERIC(12, 3),
    per_crate_display VARCHAR(150),
    price_per_piece NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    price_custom_label VARCHAR(150),
    individual_sale_unit VARCHAR(50) NOT NULL DEFAULT 'packet',
    bulk_packing_unit VARCHAR(50),
    shelf_life VARCHAR(100) DEFAULT '12 Days',
    allowed_input_modes JSONB NOT NULL DEFAULT '["Packets"]'::jsonb,
    target_fat NUMERIC(6, 2),
    target_snf NUMERIC(6, 2),
    target_sugar NUMERIC(6, 2),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.products_master ENABLE ROW LEVEL SECURITY;

-- Policy: Allow read access to all authenticated users & plant operators
CREATE POLICY "Allow read access to products_master"
    ON public.products_master
    FOR SELECT
    TO authenticated, anon
    USING (active = true);

-- Policy: Allow full modifications to authenticated users
CREATE POLICY "Allow modification of products_master"
    ON public.products_master
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Index for speedy queries
CREATE INDEX IF NOT EXISTS idx_products_master_category ON public.products_master(category);
CREATE INDEX IF NOT EXISTS idx_products_master_short_code ON public.products_master(short_code);

-- ==============================================================================
-- SEED 29 CANONICAL PRODUCTS
-- ==============================================================================

INSERT INTO public.products_master (
    product_id, product_name, item_code, short_code, category, unit, pack_size, pack_size_display,
    pieces_per_crate, per_crate_qty, per_crate_qty_grams, per_crate_display,
    price_per_piece, price_custom_label, individual_sale_unit, bulk_packing_unit,
    shelf_life, allowed_input_modes, target_fat, target_snf, active
) VALUES
-- 1. STD 200ml — ₹15 per packet; 60 pieces per crate.
('9900028', 'STD 200ml', '9900028', 'STD 200', 'Milk', 'ml', 200, '200 ml', 60, 12.0, 12000.0, '12.0 L (12000.0 ml)', 15.00, NULL, 'packet', 'Crates', '2 Days', '["Packets", "Crates"]'::jsonb, 4.5, 8.5, true),

-- 2. STD 250ml — ₹18 per packet; 48 pieces per crate.
('9900095', 'STD 250ml', '9900095', 'STD 250', 'Milk', 'ml', 250, '250 ml', 48, 12.0, 12000.0, '12.0 L (12000.0 ml)', 18.00, NULL, 'packet', 'Crates', '2 Days', '["Packets", "Crates"]'::jsonb, 4.5, 8.5, true),

-- 3. STD 500ml — ₹35 per packet; 24 pieces per crate.
('9900027', 'STD 500ml', '9900027', 'STD 500', 'Milk', 'ml', 500, '500 ml', 24, 12.0, 12000.0, '12.0 L (12000.0 ml)', 35.00, NULL, 'packet', 'Crates', '2 Days', '["Packets", "Crates"]'::jsonb, 4.5, 8.5, true),

-- 4. SM+ 500ml — Defence supply; price not specified; 24 pieces per crate.
('SMART500', 'SM+ 500ml', 'NA', 'SM+', 'Milk', 'ml', 500, '500 ml', 24, 12.0, 12000.0, '12.0 L (12000.0 ml)', 0.00, 'Defence Supply', 'packet', 'Crates', '2 Days', '["Packets", "Crates"]'::jsonb, 3.0, 8.5, true),

-- 5. Lassi — ₹20 per cup; 30 pieces per crate.
('9900007', 'Lassi', '9900007', 'Lassi', 'Fermented', 'ml', 200, '200 ml', 30, 6.0, 6000.0, '6.0 L (6000.0 ml)', 20.00, NULL, 'cup', 'Crates', '7 Days', '["Cups", "Crates"]'::jsonb, 2.5, 9.0, true),

-- 6. S80 — ₹15 per cup; 60 pieces per crate.
('9900025', 'S80', '9900025', 'S80', 'Curd', 'g', 80, '80 g', 60, 4.8, 4800.0, '4.8 kg (4800.0 g)', 15.00, NULL, 'cup', 'Crates', '12 Days', '["Cups", "Crates"]'::jsonb, 3.5, 10.0, true),

-- 7. S200 — ₹30 per cup; 30 pieces per crate.
('9900011', 'S200', '9900011', 'S200', 'Curd', 'g', 200, '200 g', 30, 6.0, 6000.0, '6.0 kg (6000.0 g)', 30.00, NULL, 'cup', 'Crates', '12 Days', '["Cups", "Crates"]'::jsonb, 3.5, 10.0, true),

-- 8. S400 — ₹55 per cup; 15 pieces per crate.
('9900010', 'S400', '9900010', 'S400', 'Curd', 'g', 400, '400 g', 15, 6.0, 6000.0, '6.0 kg (6000.0 g)', 55.00, NULL, 'cup', 'Crates', '12 Days', '["Cups", "Crates"]'::jsonb, 3.5, 10.0, true),

-- 9. Sweet Curd Pouch 400gm — ₹40 per packet; 30 pieces per crate.
('SCP400', 'Sweet Curd Pouch 400gm', 'SCP400', 'SCP 400', 'Curd', 'g', 400, '400 g', 30, 12.0, 12000.0, '12.0 kg (12000.0 g)', 40.00, NULL, 'packet', 'Crates', '12 Days', '["Packets", "Crates"]'::jsonb, 3.5, 10.0, true),

-- 10. P80 — ₹15 per cup; 60 pieces per crate.
('9900026', 'P80', '9900026', 'P80', 'Curd', 'g', 80, '80 g', 60, 4.8, 4800.0, '4.8 kg (4800.0 g)', 15.00, NULL, 'cup', 'Crates', '12 Days', '["Cups", "Crates"]'::jsonb, 3.2, 9.0, true),

-- 11. P200 — ₹30 per cup; 30 pieces per crate.
('P200', 'P200', 'P200', 'P200', 'Curd', 'g', 200, '200 g', 30, 6.0, 6000.0, '6.0 kg (6000.0 g)', 30.00, NULL, 'cup', 'Crates', '12 Days', '["Cups", "Crates"]'::jsonb, 3.2, 9.0, true),

-- 12. P400 — ₹55 per cup; 15 pieces per crate.
('9900013', 'P400', '9900013', 'P400', 'Curd', 'g', 400, '400 g', 15, 6.0, 6000.0, '6.0 kg (6000.0 g)', 55.00, NULL, 'cup', 'Crates', '12 Days', '["Cups", "Crates"]'::jsonb, 3.2, 9.0, true),

-- 13. Plain Curd Pouch 400gm — ₹35 per packet; 30 pieces per crate.
('PCP400', 'Plain Curd Pouch 400gm', 'PCP400', 'PCP 400', 'Curd', 'g', 400, '400 g', 30, 12.0, 12000.0, '12.0 kg (12000.0 g)', 35.00, NULL, 'packet', 'Crates', '12 Days', '["Packets", "Crates"]'::jsonb, 3.2, 9.5, true),

-- 14. Plain Curd Pouch 1kg — ₹75 per packet; crate size not specified.
('PCP1000', 'Plain Curd Pouch 1kg', 'PCP1000', 'PCP 1kg', 'Curd', 'g', 1000, '1 kg', 0, NULL, NULL, NULL, 75.00, NULL, 'packet', NULL, '12 Days', '["Packets"]'::jsonb, 3.2, 9.5, true),

-- 15. UHT 200ml — ₹17.50 per packet; crate size not specified.
('UHT200', 'UHT 200ml', 'UHT200', 'UHT 200', 'Milk', 'ml', 200, '200 ml', 0, NULL, NULL, NULL, 17.50, NULL, 'packet', NULL, '90 Days', '["Packets"]'::jsonb, 3.0, 8.5, true),

-- 16. UHT 1000ml — ₹74 per packet; crate size not specified.
('UHT1000', 'UHT 1000ml', 'UHT1000', 'UHT 1000', 'Milk', 'ml', 1000, '1000 ml', 0, NULL, NULL, NULL, 74.00, NULL, 'packet', NULL, '90 Days', '["Packets"]'::jsonb, 3.0, 8.5, true),

-- 17. Flavoured Milk (Kesar) — ₹25 per bottle; crate size not specified.
('FM_KESAR', 'Flavoured Milk (Kesar)', 'FM_KESAR', 'FM Kesar', 'Flavoured Milk', 'ml', 200, '200 ml', 0, NULL, NULL, NULL, 25.00, NULL, 'bottle', NULL, '30 Days', '["Bottles"]'::jsonb, 1.5, 8.5, true),

-- 18. Flavoured Milk (Mango) — ₹25 per bottle; crate size not specified.
('FM_MANGO', 'Flavoured Milk (Mango)', 'FM_MANGO', 'FM Mango', 'Flavoured Milk', 'ml', 200, '200 ml', 0, NULL, NULL, NULL, 25.00, NULL, 'bottle', NULL, '30 Days', '["Bottles"]'::jsonb, 1.5, 8.5, true),

-- 19. Flavoured Milk (Hazelnut) — ₹25 per bottle; crate size not specified.
('FM_HAZELNUT', 'Flavoured Milk (Hazelnut)', 'FM_HAZELNUT', 'FM Hazelnut', 'Flavoured Milk', 'ml', 200, '200 ml', 0, NULL, NULL, NULL, 25.00, NULL, 'bottle', NULL, '30 Days', '["Bottles"]'::jsonb, 1.5, 8.5, true),

-- 20. Flavoured Milk (Strawberry) — ₹25 per bottle; crate size not specified.
('FM_STRAWBERRY', 'Flavoured Milk (Strawberry)', 'FM_STRAWBERRY', 'FM Strawberry', 'Flavoured Milk', 'ml', 200, '200 ml', 0, NULL, NULL, NULL, 25.00, NULL, 'bottle', NULL, '30 Days', '["Bottles"]'::jsonb, 1.5, 8.5, true),

-- 21. Paneer — ₹92 per packet; 20 packets per box.
('PANEER200', 'Paneer', 'PANEER200', 'Paneer', 'Paneer', 'g', 200, '200 g', 20, 4.0, 4000.0, '4.0 kg (20 packets/box)', 92.00, NULL, 'packet', 'Boxes', '15 Days', '["Packets", "Boxes"]'::jsonb, NULL, NULL, true),

-- 22. Kalakaand — ₹140 per packet; packaging size not specified.
('SWEET_KALAKAAND', 'Kalakaand', 'KALAKAAND', 'Kalakaand', 'Sweet', 'g', 250, '250 g', 0, NULL, NULL, NULL, 140.00, NULL, 'packet', NULL, '7 Days', '["Packets"]'::jsonb, NULL, NULL, true),

-- 23. Milk Cake — ₹150 per packet; packaging size not specified.
('SWEET_MILKCAKE', 'Milk Cake', 'MILKCAKE', 'Milk Cake', 'Sweet', 'g', 250, '250 g', 0, NULL, NULL, NULL, 150.00, NULL, 'packet', NULL, '7 Days', '["Packets"]'::jsonb, NULL, NULL, true),

-- 24. Peda — sold by packet; price not specified.
('SWEET_PEDA', 'Peda', 'PEDA', 'Peda', 'Sweet', 'g', 250, '250 g', 0, NULL, NULL, NULL, 0.00, 'Price Pending', 'packet', NULL, '7 Days', '["Packets"]'::jsonb, NULL, NULL, true),

-- 25. Ghee 200gm — ₹20 per bottle; packaging size not specified.
('GHEE200', 'Ghee 200gm', 'GHEE200', 'Ghee 200g', 'Ghee', 'g', 200, '200 g', 0, NULL, NULL, NULL, 20.00, NULL, 'bottle', NULL, '180 Days', '["Bottles"]'::jsonb, NULL, NULL, true),

-- 26. Ghee 500gm — ₹420 per bottle; packaging size not specified.
('GHEE500', 'Ghee 500gm', 'GHEE500', 'Ghee 500g', 'Ghee', 'g', 500, '500 g', 0, NULL, NULL, NULL, 420.00, NULL, 'bottle', NULL, '180 Days', '["Bottles"]'::jsonb, NULL, NULL, true),

-- 27. Honey 125gm — ₹100 per bottle; packaging size not specified.
('HONEY125', 'Honey 125gm', 'HONEY125', 'Honey 125g', 'Honey', 'g', 125, '125 g', 0, NULL, NULL, NULL, 100.00, NULL, 'bottle', NULL, '365 Days', '["Bottles"]'::jsonb, NULL, NULL, true),

-- 28. Honey 250gm — ₹180 per bottle; packaging size not specified.
('HONEY250', 'Honey 250gm', 'HONEY250', 'Honey 250g', 'Honey', 'g', 250, '250 g', 0, NULL, NULL, NULL, 180.00, NULL, 'bottle', NULL, '365 Days', '["Bottles"]'::jsonb, NULL, NULL, true),

-- 29. Honey 500gm — ₹330 per bottle; packaging size not specified.
('HONEY500', 'Honey 500gm', 'HONEY500', 'Honey 500g', 'Honey', 'g', 500, '500 g', 0, NULL, NULL, NULL, 330.00, NULL, 'bottle', NULL, '365 Days', '["Bottles"]'::jsonb, NULL, NULL, true)

ON CONFLICT (product_id) DO UPDATE SET
    product_name = EXCLUDED.product_name,
    item_code = EXCLUDED.item_code,
    short_code = EXCLUDED.short_code,
    category = EXCLUDED.category,
    unit = EXCLUDED.unit,
    pack_size = EXCLUDED.pack_size,
    pack_size_display = EXCLUDED.pack_size_display,
    pieces_per_crate = EXCLUDED.pieces_per_crate,
    per_crate_qty = EXCLUDED.per_crate_qty,
    per_crate_qty_grams = EXCLUDED.per_crate_qty_grams,
    per_crate_display = EXCLUDED.per_crate_display,
    price_per_piece = EXCLUDED.price_per_piece,
    price_custom_label = EXCLUDED.price_custom_label,
    individual_sale_unit = EXCLUDED.individual_sale_unit,
    bulk_packing_unit = EXCLUDED.bulk_packing_unit,
    shelf_life = EXCLUDED.shelf_life,
    allowed_input_modes = EXCLUDED.allowed_input_modes,
    target_fat = EXCLUDED.target_fat,
    target_snf = EXCLUDED.target_snf,
    active = EXCLUDED.active,
    updated_at = NOW();
