-- =====================================================
-- IVF 약물 알림 앱 - Supabase 스키마
-- =====================================================

-- 1. 사용자 프로필 (Supabase Auth와 연동)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nickname TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 치료 주기 (Cycle)
CREATE TABLE treatment_cycles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  cycle_number INTEGER NOT NULL DEFAULT 1,  -- 1차, 2차, 3차...
  start_date DATE,
  end_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 치료 단계 (Stage)
CREATE TABLE cycle_stages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cycle_id UUID REFERENCES treatment_cycles(id) ON DELETE CASCADE NOT NULL,
  stage_type TEXT NOT NULL CHECK (stage_type IN (
    'ovarian_stimulation',  -- 과배란
    'egg_retrieval',        -- 난자채취
    'fertilization',        -- 수정
    'embryo_transfer',      -- 배아이식
    'pregnancy_test',       -- 임신확인
    'follow_up'             -- 추후관리
  )),
  start_date DATE,
  end_date DATE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped')),
  -- 단계별 결과 데이터 (JSON으로 유연하게)
  result_data JSONB DEFAULT '{}',
  -- 예: 난자채취 {"retrieved_count": 10, "mature_count": 8}
  -- 예: 수정 {"fertilized_count": 6, "method": "ICSI"}
  -- 예: 이식 {"transferred_count": 2, "grade": "AA"}
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 약물 목록
CREATE TABLE medications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cycle_id UUID REFERENCES treatment_cycles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,                    -- 약물명 (예: 고날에프, 오비드렐)
  type TEXT NOT NULL CHECK (type IN ('injection', 'oral', 'patch', 'other')),
  dosage TEXT,                           -- 용량 (예: 300IU, 0.5mg)
  frequency TEXT,                        -- 빈도 (예: 1일 1회)
  scheduled_times TEXT[],                -- 예약 시간들 ['09:00', '21:00']
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  color TEXT,                            -- UI 표시 색상
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. 투약 기록 (복용/주사 완료 로그)
CREATE TABLE medication_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  medication_id UUID REFERENCES medications(id) ON DELETE CASCADE NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,     -- 예정 시간
  taken_at TIMESTAMPTZ,                  -- 실제 복용 시간
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'taken', 'skipped', 'missed')),
  injection_location INTEGER,            -- 주사 부위 (0-7, 좌측 0-3, 우측 4-7)
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 주사 부위 히스토리 (로테이션 추적)
CREATE TABLE injection_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  location INTEGER NOT NULL CHECK (location >= 0 AND location <= 7),
  injected_at TIMESTAMPTZ DEFAULT NOW(),
  medication_name TEXT
);

-- =====================================================
-- Row Level Security (RLS) 정책
-- =====================================================

-- RLS 활성화
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatment_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE injection_history ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 데이터만 접근 가능
CREATE POLICY "Users can view own profile" ON profiles
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can manage own cycles" ON treatment_cycles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own stages" ON cycle_stages
  FOR ALL USING (
    cycle_id IN (SELECT id FROM treatment_cycles WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can manage own medications" ON medications
  FOR ALL USING (
    cycle_id IN (SELECT id FROM treatment_cycles WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can manage own medication logs" ON medication_logs
  FOR ALL USING (
    medication_id IN (
      SELECT m.id FROM medications m
      JOIN treatment_cycles c ON m.cycle_id = c.id
      WHERE c.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage own injection history" ON injection_history
  FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- 자동 업데이트 트리거
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_treatment_cycles_updated_at
  BEFORE UPDATE ON treatment_cycles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_cycle_stages_updated_at
  BEFORE UPDATE ON cycle_stages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_medications_updated_at
  BEFORE UPDATE ON medications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- 새 사용자 가입 시 프로필 자동 생성
-- =====================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id)
  VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- 인덱스 (성능 최적화)
-- =====================================================

CREATE INDEX idx_treatment_cycles_user_id ON treatment_cycles(user_id);
CREATE INDEX idx_cycle_stages_cycle_id ON cycle_stages(cycle_id);
CREATE INDEX idx_medications_cycle_id ON medications(cycle_id);
CREATE INDEX idx_medication_logs_medication_id ON medication_logs(medication_id);
CREATE INDEX idx_medication_logs_scheduled_at ON medication_logs(scheduled_at);
CREATE INDEX idx_injection_history_user_id ON injection_history(user_id);
CREATE INDEX idx_injection_history_injected_at ON injection_history(injected_at);
