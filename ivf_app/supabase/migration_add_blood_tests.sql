-- ============================================
-- 피검사 기록 테이블 추가
-- ============================================

-- 피검사 기록 테이블
CREATE TABLE IF NOT EXISTS blood_tests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id TEXT NOT NULL, -- 로컬 사이클 ID
  date DATE NOT NULL,
  e2 DECIMAL,             -- 에스트라디올 (pg/mL)
  fsh DECIMAL,            -- 난포자극호르몬 (mIU/mL)
  lh DECIMAL,             -- 황체형성호르몬 (mIU/mL)
  p4 DECIMAL,             -- 프로게스테론 (ng/mL)
  hcg DECIMAL,            -- β-hCG (mIU/mL)
  amh DECIMAL,            -- 난소 예비력 (ng/mL)
  tsh DECIMAL,            -- 갑상선 (mIU/L)
  vit_d DECIMAL,          -- 비타민D (ng/mL)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 활성화
ALTER TABLE blood_tests ENABLE ROW LEVEL SECURITY;

-- RLS 정책
CREATE POLICY "blood_tests_all" ON blood_tests FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_blood_tests_user_id ON blood_tests(user_id);
CREATE INDEX IF NOT EXISTS idx_blood_tests_cycle_id ON blood_tests(user_id, cycle_id);
CREATE INDEX IF NOT EXISTS idx_blood_tests_date ON blood_tests(user_id, date DESC);

-- 트리거
CREATE TRIGGER tr_blood_tests_updated_at
  BEFORE UPDATE ON blood_tests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
