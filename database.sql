-- TIPALERT DATABASE (Fixed)

CREATE TABLE IF NOT EXISTS streamer_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  bio TEXT DEFAULT '',
  platform TEXT DEFAULT 'YouTube',
  welcome_msg TEXT DEFAULT 'ขอบคุณที่ support นะครับ! 🙏',
  min_donation INTEGER DEFAULT 20,
  alert_duration INTEGER DEFAULT 8,
  tts_enabled BOOLEAN DEFAULT TRUE,
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_methods (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES streamer_profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  label TEXT NOT NULL,
  icon TEXT DEFAULT '💳',
  account_number TEXT NOT NULL,
  account_name TEXT NOT NULL,
  bank_name TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS donations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  streamer_id UUID REFERENCES streamer_profiles(id) ON DELETE CASCADE,
  donor_name TEXT DEFAULT 'Anonymous',
  amount INTEGER NOT NULL,
  message TEXT DEFAULT '',
  payment_method TEXT,
  status TEXT DEFAULT 'confirmed',
  fired_at TIMESTAMPTZ DEFAULT NOW(),
  month_year TEXT
);

CREATE OR REPLACE FUNCTION fill_month_year()
RETURNS TRIGGER AS $$
BEGIN
  NEW.month_year := TO_CHAR(NEW.fired_at, 'YYYY-MM');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_month_year ON donations;
CREATE TRIGGER set_month_year
BEFORE INSERT ON donations
FOR EACH ROW EXECUTE FUNCTION fill_month_year();

ALTER TABLE streamer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read profiles" ON streamer_profiles;
DROP POLICY IF EXISTS "Own profile update" ON streamer_profiles;
DROP POLICY IF EXISTS "Own profile insert" ON streamer_profiles;
DROP POLICY IF EXISTS "Public read payments" ON payment_methods;
DROP POLICY IF EXISTS "Own payments manage" ON payment_methods;
DROP POLICY IF EXISTS "Own donations" ON donations;

CREATE POLICY "Public read profiles" ON streamer_profiles FOR SELECT USING (true);
CREATE POLICY "Own profile update" ON streamer_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Own profile insert" ON streamer_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Public read payments" ON payment_methods FOR SELECT USING (true);
CREATE POLICY "Own payments manage" ON payment_methods FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Own donations" ON donations FOR ALL USING (auth.uid() = streamer_id);

CREATE INDEX IF NOT EXISTS idx_donations_streamer ON donations(streamer_id);
CREATE INDEX IF NOT EXISTS idx_donations_month ON donations(streamer_id, month_year);
CREATE INDEX IF NOT EXISTS idx_payments_user ON payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON streamer_profiles(username);
