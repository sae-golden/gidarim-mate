-- ============================================
-- medication_logs 테이블 수정 마이그레이션
-- 로컬 약물 ID(TEXT)를 사용할 수 있도록 변경
-- Supabase SQL Editor에서 실행하세요
-- ============================================

-- 1단계: 기존 foreign key 제약조건 제거
-- 이 제약조건이 로컬 ID 저장을 막고 있음
ALTER TABLE medication_logs
DROP CONSTRAINT IF EXISTS medication_logs_medication_id_fkey;

-- 2단계: medication_id 컬럼 타입을 TEXT로 변경
-- UUID -> TEXT 변경 (기존 데이터는 TEXT로 자동 변환됨)
ALTER TABLE medication_logs
ALTER COLUMN medication_id TYPE TEXT USING medication_id::TEXT;

-- 3단계: local_medication_id 컬럼 추가 (로컬 앱의 약물 ID 저장용)
-- 이미 있으면 무시
ALTER TABLE medication_logs
ADD COLUMN IF NOT EXISTS local_medication_id TEXT;

-- 4단계: 기존 데이터 마이그레이션 - medication_id 값을 local_medication_id로 복사
UPDATE medication_logs
SET local_medication_id = medication_id
WHERE local_medication_id IS NULL AND medication_id IS NOT NULL;

-- 5단계: UNIQUE 제약조건 재생성 (user_id, local_medication_id, date)
-- 먼저 기존 제약조건 삭제
ALTER TABLE medication_logs
DROP CONSTRAINT IF EXISTS medication_logs_user_id_medication_id_date_key;

-- 새로운 제약조건 추가
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'medication_logs_user_local_med_date_key'
  ) THEN
    ALTER TABLE medication_logs
    ADD CONSTRAINT medication_logs_user_local_med_date_key
    UNIQUE (user_id, local_medication_id, date);
  END IF;
END $$;

-- 6단계: 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_medication_logs_local_med_id
ON medication_logs(user_id, local_medication_id, date);

-- 7단계: injection_sites 테이블도 동일하게 수정
ALTER TABLE injection_sites
DROP CONSTRAINT IF EXISTS injection_sites_medication_id_fkey;

ALTER TABLE injection_sites
ALTER COLUMN medication_id TYPE TEXT USING medication_id::TEXT;

ALTER TABLE injection_sites
ADD COLUMN IF NOT EXISTS local_medication_id TEXT;

UPDATE injection_sites
SET local_medication_id = medication_id
WHERE local_medication_id IS NULL AND medication_id IS NOT NULL;

-- 완료 확인
SELECT 'Migration completed successfully!' as status;
