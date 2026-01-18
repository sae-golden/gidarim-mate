-- ============================================
-- IVF 약물 알림 앱 - Supabase 테이블 스키마
-- ============================================

-- 1. 공용 테이블: 병원 목록
CREATE TABLE IF NOT EXISTS hospitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  region TEXT, -- 지역 (서울, 경기 등)
  is_ivf_specialist BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 공용 테이블: 약물 마스터 DB
CREATE TABLE IF NOT EXISTS medications_db (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  generic_name TEXT, -- 성분명
  type TEXT NOT NULL CHECK (type IN ('injection', 'oral', 'suppository', 'patch')),
  category TEXT, -- 카테고리 (FSH, GnRH 등)
  aliases TEXT[], -- 별칭 (음성인식용)
  default_dosage TEXT,
  instructions TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 사용자 프로필 (개인)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  hospital_id UUID REFERENCES hospitals(id),
  notification_enabled BOOLEAN DEFAULT true,
  notification_before_minutes INTEGER DEFAULT 10,
  theme TEXT DEFAULT 'light',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 사용자 약물 (개인)
CREATE TABLE IF NOT EXISTS user_medications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medication_id TEXT, -- 로컬 앱의 약물 ID (중복 방지용)
  medication_db_id UUID REFERENCES medications_db(id), -- 마스터 DB 참조 (optional)
  name TEXT NOT NULL,
  dosage TEXT,
  type TEXT NOT NULL CHECK (type IN ('injection', 'oral', 'suppository', 'patch')),
  time TEXT NOT NULL, -- "HH:mm" 형식
  pattern TEXT DEFAULT '매일', -- 매일, 격일, 월수금 등
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_count INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 같은 사용자가 동일한 로컬 ID의 약물을 중복 저장하지 못하게 함
  UNIQUE(user_id, medication_id)
);

-- 5. 치료 사이클 (개인)
CREATE TABLE IF NOT EXISTS treatment_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_number INTEGER NOT NULL, -- 1차, 2차...
  start_date DATE NOT NULL,
  end_date DATE,
  current_stage TEXT, -- 과배란, 채취, 이식 등
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 복용 기록 (개인) - 일별 요약
CREATE TABLE IF NOT EXISTS medication_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES user_medications(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  scheduled_count INTEGER NOT NULL DEFAULT 1,
  completed_count INTEGER NOT NULL DEFAULT 0,
  completion_rate INTEGER GENERATED ALWAYS AS (
    CASE WHEN scheduled_count > 0
         THEN ROUND((completed_count::NUMERIC / scheduled_count) * 100)
         ELSE 0
    END
  ) STORED,
  first_completed_at TIME,
  last_completed_at TIME,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, medication_id, date)
);

-- 7. 주사 부위 기록 (로컬 + 클라우드 백업)
CREATE TABLE IF NOT EXISTS injection_sites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medication_id UUID REFERENCES user_medications(id) ON DELETE SET NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  site TEXT NOT NULL CHECK (site IN ('left', 'right')),
  location TEXT, -- 복부, 허벅지 등
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Row Level Security (RLS) 정책
-- ============================================

-- RLS 활성화
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatment_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE injection_sites ENABLE ROW LEVEL SECURITY;

-- 공용 테이블은 읽기 전용
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications_db ENABLE ROW LEVEL SECURITY;

-- 공용 테이블 정책: 모든 인증 사용자가 읽기 가능
CREATE POLICY "hospitals_read" ON hospitals FOR SELECT TO authenticated USING (true);
CREATE POLICY "medications_db_read" ON medications_db FOR SELECT TO authenticated USING (true);

-- 개인 테이블 정책: 본인 데이터만 CRUD 가능
CREATE POLICY "user_profiles_all" ON user_profiles FOR ALL TO authenticated
  USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "user_medications_all" ON user_medications FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "treatment_cycles_all" ON treatment_cycles FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "medication_logs_all" ON medication_logs FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "injection_sites_all" ON injection_sites FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 인덱스 (성능 최적화)
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_medications_user_id ON user_medications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_medications_active ON user_medications(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_medication_logs_user_date ON medication_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_medication_logs_medication ON medication_logs(medication_id, date);
CREATE INDEX IF NOT EXISTS idx_treatment_cycles_user ON treatment_cycles(user_id, status);
CREATE INDEX IF NOT EXISTS idx_injection_sites_user_date ON injection_sites(user_id, date DESC);

-- ============================================
-- 트리거: updated_at 자동 갱신
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_user_medications_updated_at
  BEFORE UPDATE ON user_medications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_treatment_cycles_updated_at
  BEFORE UPDATE ON treatment_cycles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_medication_logs_updated_at
  BEFORE UPDATE ON medication_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 초기 데이터: 주요 IVF 약물
-- ============================================

INSERT INTO medications_db (name, generic_name, type, category, aliases, default_dosage) VALUES
-- 주사제
('고날에프', 'Follitropin alfa', 'injection', 'FSH', ARRAY['고나엘에프', '고나도트로핀'], '75-150 IU'),
('퓨레곤', 'Follitropin beta', 'injection', 'FSH', ARRAY['퓨레곤펜'], '75-150 IU'),
('메노푸어', 'Menotropin', 'injection', 'FSH+LH', ARRAY['메노퓨어'], '75-150 IU'),
('오비드렐', 'Choriogonadotropin alfa', 'injection', 'hCG', ARRAY['오비트렐'], '250 mcg'),
('프레그닐', 'Chorionic gonadotropin', 'injection', 'hCG', ARRAY['프레그닐주'], '5000-10000 IU'),
('세트로타이드', 'Cetrorelix', 'injection', 'GnRH antagonist', ARRAY['세트로타이드주'], '0.25 mg'),
('오르가루트란', 'Ganirelix', 'injection', 'GnRH antagonist', ARRAY['오르가루트랜'], '0.25 mg'),
('데카펩틸', 'Triptorelin', 'injection', 'GnRH agonist', ARRAY['데카펩틸주'], '0.1 mg'),
('루프론', 'Leuprolide', 'injection', 'GnRH agonist', ARRAY['루프린'], '1 mg'),
('크녹산', 'Ganirelix', 'injection', 'GnRH antagonist', ARRAY['큰옥산', '큰 옥산', '크록산'], '0.25 mg'),

-- 경구약
('프로기노바', 'Estradiol valerate', 'oral', 'Estrogen', ARRAY['프로게노바', '푸르기노바'], '2 mg'),
('유트로게스탄', 'Progesterone', 'oral', 'Progesterone', ARRAY['유트로게스탄캡슐'], '100-200 mg'),
('듀파스톤', 'Dydrogesterone', 'oral', 'Progesterone', ARRAY['듀파스톤정'], '10 mg'),
('클로미펜', 'Clomiphene', 'oral', 'SERM', ARRAY['클로미드'], '50-100 mg'),
('페마라', 'Letrozole', 'oral', 'Aromatase inhibitor', ARRAY['레트로졸'], '2.5-5 mg'),
('아스피린', 'Aspirin', 'oral', 'Antiplatelet', ARRAY['아스피린프로텍트'], '100 mg'),
('프레드니솔론', 'Prednisolone', 'oral', 'Steroid', ARRAY['프레드니솔론정'], '5 mg'),

-- 질정
('루테늄', 'Progesterone', 'suppository', 'Progesterone', ARRAY['루테움', '루테이움'], '90 mg'),
('크리논', 'Progesterone', 'suppository', 'Progesterone', ARRAY['크리논젤'], '8%')

ON CONFLICT (name) DO NOTHING;
