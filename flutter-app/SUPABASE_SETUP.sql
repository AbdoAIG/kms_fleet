-- ═══════════════════════════════════════════════════════════════════════════════
-- KMS Fleet — Supabase Database Setup
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- Run this SQL in your Supabase project's SQL Editor.
-- It creates ALL tables, indexes, triggers, and RLS policies.
--
-- Tables:
--   1. app_users          — User profiles with roles
--   2. vehicles           — Fleet vehicles with embedded driver fields
--   3. maintenance_records — Maintenance history
--   4. checklists          — Pre-trip / post-trip / weekly inspections
--   5. fuel_records        — Fuel fill-up logs
--   6. driver_violations   — Traffic violations
--   7. expenses            — Miscellaneous expenses
--   8. work_orders         — Maintenance/repair work orders
--   9. trip_trackings      — GPS trip tracking data
--   10. notifications      — System notifications
--   11. attachments        — File/photo attachments
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── 0. Enable UUID extension ─────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── 1. app_users ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.app_users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_user_id  UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT NOT NULL UNIQUE,
  display_name  TEXT NOT NULL DEFAULT '',
  role          TEXT NOT NULL DEFAULT 'driver' CHECK (role IN ('admin', 'supervisor', 'driver')),
  phone         TEXT DEFAULT '',
  is_active     BOOLEAN DEFAULT TRUE,
  assigned_vehicle_id INTEGER,
  last_login    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── 2. vehicles ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vehicles (
  id                    BIGSERIAL PRIMARY KEY,
  user_id               UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plate_number          TEXT NOT NULL,
  make                  TEXT NOT NULL DEFAULT '',
  model                 TEXT NOT NULL DEFAULT '',
  year                  INTEGER DEFAULT 2024,
  color                 TEXT DEFAULT '',
  fuel_type             TEXT DEFAULT 'petrol',
  current_odometer      INTEGER DEFAULT 0,
  status                TEXT DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'inactive')),
  notes                 TEXT,
  vehicle_type          TEXT,
  passenger_capacity    INTEGER,
  cargo_capacity_tons   DOUBLE PRECISION,
  purpose               TEXT,
  driver_name           TEXT,
  driver_phone          TEXT,
  driver_license_number TEXT,
  driver_license_expiry TIMESTAMPTZ,
  driver_status         TEXT CHECK (driver_status IN ('active', 'suspended')),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_vehicles_user_id ON public.vehicles(user_id);
CREATE INDEX idx_vehicles_plate ON public.vehicles(plate_number);
CREATE INDEX idx_vehicles_status ON public.vehicles(status);

-- ─── 3. maintenance_records ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.maintenance_records (
  id                   BIGSERIAL PRIMARY KEY,
  user_id              UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id           BIGINT REFERENCES public.vehicles(id) ON DELETE CASCADE,
  maintenance_date     TIMESTAMPTZ NOT NULL,
  description          TEXT NOT NULL DEFAULT '',
  type                 TEXT NOT NULL DEFAULT 'other',
  odometer_reading     INTEGER DEFAULT 0,
  cost                 DOUBLE PRECISION DEFAULT 0,
  labor_cost           DOUBLE PRECISION,
  service_provider     TEXT,
  invoice_number       TEXT,
  priority             TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status               TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
  parts_used           TEXT,
  next_maintenance_date TIMESTAMPTZ,
  next_maintenance_km  INTEGER,
  notes                TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_maintenance_user ON public.maintenance_records(user_id);
CREATE INDEX idx_maintenance_vehicle ON public.maintenance_records(vehicle_id);
CREATE INDEX idx_maintenance_status ON public.maintenance_records(status);
CREATE INDEX idx_maintenance_date ON public.maintenance_records(maintenance_date);

-- ─── 4. checklists ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.checklists (
  id              BIGSERIAL PRIMARY KEY,
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id      BIGINT REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type            TEXT NOT NULL DEFAULT 'pre_trip' CHECK (type IN ('pre_trip', 'post_trip', 'weekly')),
  inspection_date TIMESTAMPTZ NOT NULL,
  odometer_reading INTEGER DEFAULT 0,
  items           JSONB DEFAULT '[]'::jsonb,
  inspector_name  TEXT,
  signature_path  TEXT,
  notes           TEXT,
  status          TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed')),
  overall_score   DOUBLE PRECISION DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_checklists_user ON public.checklists(user_id);
CREATE INDEX idx_checklists_vehicle ON public.checklists(vehicle_id);
CREATE INDEX idx_checklists_type ON public.checklists(type);

-- ─── 5. fuel_records ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fuel_records (
  id               BIGSERIAL PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id       BIGINT REFERENCES public.vehicles(id) ON DELETE CASCADE,
  fill_date        TIMESTAMPTZ NOT NULL,
  odometer_reading INTEGER DEFAULT 0,
  liters           DOUBLE PRECISION NOT NULL DEFAULT 0,
  cost_per_liter   DOUBLE PRECISION NOT NULL DEFAULT 0,
  fuel_type        TEXT DEFAULT 'petrol',
  station_name     TEXT,
  station_location TEXT,
  full_tank        BOOLEAN DEFAULT TRUE,
  notes            TEXT,
  consumption_rate DOUBLE PRECISION,
  is_abnormal      BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_fuel_user ON public.fuel_records(user_id);
CREATE INDEX idx_fuel_vehicle ON public.fuel_records(vehicle_id);
CREATE INDEX idx_fuel_date ON public.fuel_records(fill_date);

-- ─── 6. driver_violations ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.driver_violations (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id  BIGINT REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL DEFAULT 'other',
  amount      DOUBLE PRECISION NOT NULL DEFAULT 0,
  date        TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  points      INTEGER DEFAULT 0,
  status      TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'disputed')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_violations_user ON public.driver_violations(user_id);
CREATE INDEX idx_violations_vehicle ON public.driver_violations(vehicle_id);

-- ─── 7. expenses ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.expenses (
  id               BIGSERIAL PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id       BIGINT REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type             TEXT NOT NULL DEFAULT 'miscellaneous' CHECK (type IN ('fuel', 'maintenance', 'toll', 'violation', 'insurance', 'miscellaneous')),
  amount           DOUBLE PRECISION NOT NULL DEFAULT 0,
  date             TIMESTAMPTZ NOT NULL,
  description      TEXT NOT NULL DEFAULT '',
  service_provider TEXT,
  invoice_number   TEXT,
  odometer_reading INTEGER,
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_expenses_user ON public.expenses(user_id);
CREATE INDEX idx_expenses_vehicle ON public.expenses(vehicle_id);
CREATE INDEX idx_expenses_type ON public.expenses(type);

-- ─── 8. work_orders ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.work_orders (
  id               BIGSERIAL PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id       BIGINT REFERENCES public.vehicles(id) ON DELETE CASCADE,
  type             TEXT NOT NULL DEFAULT 'maintenance' CHECK (type IN ('maintenance', 'repair', 'inspection')),
  status           TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed')),
  description      TEXT,
  technician_name  TEXT,
  technician_phone TEXT,
  estimated_cost   DOUBLE PRECISION,
  actual_cost      DOUBLE PRECISION,
  priority         TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  start_date       TIMESTAMPTZ,
  completed_date   TIMESTAMPTZ,
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_work_orders_user ON public.work_orders(user_id);
CREATE INDEX idx_work_orders_vehicle ON public.work_orders(vehicle_id);
CREATE INDEX idx_work_orders_status ON public.work_orders(status);

-- ─── 9. trip_trackings ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.trip_trackings (
  id               BIGSERIAL PRIMARY KEY,
  user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id       BIGINT REFERENCES public.vehicles(id) ON DELETE CASCADE,
  status           TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  start_lat        DOUBLE PRECISION,
  start_lng        DOUBLE PRECISION,
  end_lat          DOUBLE PRECISION,
  end_lng          DOUBLE PRECISION,
  start_address    TEXT,
  end_address      TEXT,
  distance_km      DOUBLE PRECISION DEFAULT 0,
  duration_minutes DOUBLE PRECISION DEFAULT 0,
  start_odometer   INTEGER,
  end_odometer     INTEGER,
  notes            TEXT,
  trip_points_json JSONB DEFAULT '[]'::jsonb,
  driver_name      TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_trips_user ON public.trip_trackings(user_id);
CREATE INDEX idx_trips_vehicle ON public.trip_trackings(vehicle_id);
CREATE INDEX idx_trips_status ON public.trip_trackings(status);

-- ─── 10. notifications ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL DEFAULT 'info' CHECK (type IN ('maintenance_due', 'license_expiry', 'violation', 'work_order', 'info', 'warning', 'success')),
  title       TEXT NOT NULL DEFAULT '',
  message     TEXT NOT NULL DEFAULT '',
  entity_type TEXT,
  entity_id   BIGINT,
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  read_at     TIMESTAMPTZ
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_read ON public.notifications(user_id, is_read);

-- ─── 11. attachments ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.attachments (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('vehicle', 'maintenance', 'checklist', 'fuel', 'violation', 'expense', 'work_order', 'trip')),
  entity_id   BIGINT NOT NULL,
  file_name   TEXT NOT NULL,
  file_type   TEXT NOT NULL,
  file_size   BIGINT DEFAULT 0,
  file_path   TEXT NOT NULL,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_attachments_entity ON public.attachments(entity_type, entity_id);
CREATE INDEX idx_attachments_user ON public.attachments(user_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTO-UPDATE updated_at TRIGGER
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to all tables that have updated_at
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT table_name FROM information_schema.tables
           WHERE table_schema = 'public'
           AND table_name IN (
             'vehicles', 'maintenance_records', 'checklists', 'fuel_records',
             'driver_violations', 'expenses', 'work_orders', 'trip_trackings',
             'app_users'
           )
  LOOP
    EXECUTE format(
      'CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();',
      t
    );
  END LOOP;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Enable RLS on all tables
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fuel_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_trackings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;

-- ─── Policies: authenticated users can manage their own data ──────────────────

-- app_users
CREATE POLICY "Users can view own profile" ON public.app_users
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = auth_user_id);

CREATE POLICY "Users can update own profile" ON public.app_users
  FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = auth_user_id);

CREATE POLICY "Admins can manage all users" ON public.app_users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.app_users au
      WHERE au.user_id = auth.uid() AND au.role = 'admin'
    )
  );

CREATE POLICY "Authenticated users can insert users" ON public.app_users
  FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() = auth_user_id);

-- vehicles
CREATE POLICY "Users can manage own vehicles" ON public.vehicles
  FOR ALL USING (auth.uid() = user_id);

-- maintenance_records
CREATE POLICY "Users can manage own maintenance" ON public.maintenance_records
  FOR ALL USING (auth.uid() = user_id);

-- checklists
CREATE POLICY "Users can manage own checklists" ON public.checklists
  FOR ALL USING (auth.uid() = user_id);

-- fuel_records
CREATE POLICY "Users can manage own fuel records" ON public.fuel_records
  FOR ALL USING (auth.uid() = user_id);

-- driver_violations
CREATE POLICY "Users can manage own violations" ON public.driver_violations
  FOR ALL USING (auth.uid() = user_id);

-- expenses
CREATE POLICY "Users can manage own expenses" ON public.expenses
  FOR ALL USING (auth.uid() = user_id);

-- work_orders
CREATE POLICY "Users can manage own work orders" ON public.work_orders
  FOR ALL USING (auth.uid() = user_id);

-- trip_trackings
CREATE POLICY "Users can manage own trips" ON public.trip_trackings
  FOR ALL USING (auth.uid() = user_id);

-- notifications
CREATE POLICY "Users can manage own notifications" ON public.notifications
  FOR ALL USING (auth.uid() = user_id);

-- attachments
CREATE POLICY "Users can manage own attachments" ON public.attachments
  FOR ALL USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTO-CREATE USER PROFILE ON SIGNUP
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.app_users (auth_user_id, user_id, email, display_name, role)
  VALUES (
    NEW.id,
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'driver')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ═══════════════════════════════════════════════════════════════════════════════
-- STORAGE BUCKET for attachments
-- ═══════════════════════════════════════════════════════════════════════════════
-- Run this in the Supabase Dashboard → Storage → create bucket "attachments"
-- Or use this SQL (requires the storage schema to be set up):
--
-- INSERT INTO storage.buckets (id, name, public) VALUES ('attachments', 'attachments', false);
--
-- Then add storage policies:
-- INSERT INTO storage.policies (bucket_id, name, definition)
-- VALUES ('attachments', 'Users can upload attachments',
--   '{"name": "Users can upload attachments", "definition": "CREATE POLICY \"Users can upload\" ON storage.objects FOR INSERT WITH CHECK (bucket_id = ''attachments'' AND auth.uid()::text = (storage.foldername(name))[1])"}');
--
-- ═══════════════════════════════════════════════════════════════════════════════
-- DONE! All tables are created with RLS enabled.
-- ═══════════════════════════════════════════════════════════════════════════════
