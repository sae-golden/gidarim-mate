-- ============================================
-- 앱 피드백 테이블 마이그레이션
-- 1-3점 평가 시 사용자 피드백 수집용
-- ============================================

-- 피드백 테이블 생성
CREATE TABLE IF NOT EXISTS feedbacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- 사용자 탈퇴해도 피드백은 유지

  -- 평가 정보
  stars INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
  category TEXT NOT NULL CHECK (category IN ('bug', 'ui', 'feature', 'notification', 'other')),
  content TEXT NOT NULL,

  -- 앱 환경 정보 (디버깅용)
  app_version TEXT,
  os_type TEXT, -- 'ios', 'android', 'web'
  os_version TEXT,
  device_model TEXT,

  -- 처리 상태
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'wontfix')),
  admin_notes TEXT, -- 관리자 메모

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 활성화
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;

-- 정책: 인증된 사용자는 피드백 작성 가능 (INSERT)
CREATE POLICY "feedbacks_insert" ON feedbacks
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- 정책: 본인 피드백만 조회 가능 (SELECT)
CREATE POLICY "feedbacks_select_own" ON feedbacks
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- 인덱스 (관리자 조회 최적화)
CREATE INDEX IF NOT EXISTS idx_feedbacks_status ON feedbacks(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedbacks_category ON feedbacks(category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedbacks_user ON feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_stars ON feedbacks(stars);

-- updated_at 자동 갱신 트리거
CREATE TRIGGER tr_feedbacks_updated_at
  BEFORE UPDATE ON feedbacks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 관리자용 뷰 (선택 사항)
-- ============================================

-- 피드백 요약 뷰
CREATE OR REPLACE VIEW feedbacks_summary AS
SELECT
  category,
  stars,
  COUNT(*) as count,
  DATE_TRUNC('day', created_at) as date
FROM feedbacks
GROUP BY category, stars, DATE_TRUNC('day', created_at)
ORDER BY date DESC;

-- 최근 피드백 뷰 (관리자용 - 서비스 역할로만 접근)
CREATE OR REPLACE VIEW feedbacks_recent AS
SELECT
  f.id,
  f.stars,
  f.category,
  f.content,
  f.app_version,
  f.os_type,
  f.status,
  f.created_at,
  u.email as user_email
FROM feedbacks f
LEFT JOIN auth.users u ON f.user_id = u.id
ORDER BY f.created_at DESC
LIMIT 100;
