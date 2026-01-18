-- ============================================
-- 중복 약물 데이터 정리 마이그레이션
-- Supabase SQL Editor에서 실행하세요
-- ============================================

-- 1단계: medication_id 컬럼 추가 (이미 존재하면 무시)
ALTER TABLE user_medications
ADD COLUMN IF NOT EXISTS medication_id TEXT;

-- 2단계: 중복 데이터 확인 (실행 전 확인용 - 삭제 전 백업 권장)
-- 이 쿼리로 중복 데이터를 먼저 확인하세요
SELECT
  user_id,
  name,
  time,
  start_date,
  COUNT(*) as duplicate_count,
  array_agg(id) as ids
FROM user_medications
WHERE is_active = true
GROUP BY user_id, name, time, start_date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 3단계: 중복 제거 - 각 (user_id, name, time, start_date) 조합에서 가장 오래된 것만 유지
-- ⚠️ 주의: 이 쿼리는 데이터를 삭제합니다. 백업 후 실행하세요!
WITH duplicates AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, name, time, start_date
      ORDER BY created_at ASC
    ) as rn
  FROM user_medications
  WHERE is_active = true
)
DELETE FROM user_medications
WHERE id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

-- 4단계: 남은 레코드에 medication_id 설정 (없는 경우)
-- 로컬 ID가 없는 레코드에 Supabase ID를 medication_id로 복사
UPDATE user_medications
SET medication_id = id::TEXT
WHERE medication_id IS NULL;

-- 5단계: UNIQUE 제약조건 추가 (중복 방지)
-- 먼저 기존 제약조건이 있는지 확인하고 없으면 추가
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_medications_user_id_medication_id_key'
  ) THEN
    ALTER TABLE user_medications
    ADD CONSTRAINT user_medications_user_id_medication_id_key
    UNIQUE (user_id, medication_id);
  END IF;
END $$;

-- 6단계: 인덱스 추가 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_user_medications_medication_id
ON user_medications(user_id, medication_id);

-- 7단계: 정리 결과 확인
SELECT
  COUNT(*) as total_medications,
  COUNT(DISTINCT (user_id, name, time, start_date)) as unique_combinations
FROM user_medications
WHERE is_active = true;
