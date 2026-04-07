-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION: Update vehicle_type column constraints for new categories
-- 
-- Run this SQL in Supabase SQL Editor to update the vehicles table.
-- ═══════════════════════════════════════════════════════════════════════════

-- The vehicle_type column already exists as TEXT, so we just need to:
-- 1. Update the CHECK constraint to allow the new category values
-- 2. (Optional) Update existing vehicles if needed

-- Drop old constraint if exists and add new one
ALTER TABLE vehicles DROP CONSTRAINT IF EXISTS vehicles_vehicle_type_check;

ALTER TABLE vehicles ADD CONSTRAINT vehicles_vehicle_type_check 
CHECK (vehicle_type IS NULL OR vehicle_type IN (
  'half_truck',
  'jumbo_truck', 
  'double_cabin',
  'bus',
  'microbus',
  'forklift'
));

-- Update any existing vehicles with old type values to the new values
UPDATE vehicles SET vehicle_type = 'jumbo_truck' WHERE vehicle_type = 'jumbo';
UPDATE vehicles SET vehicle_type = 'forklift' WHERE vehicle_type = 'truck';
