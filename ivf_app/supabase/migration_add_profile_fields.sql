-- ============================================
-- 마이그레이션: user_profiles 테이블에 치료단계/병원정보 필드 추가
-- 실행일: 2024-12-30
-- ============================================

-- 1. 치료 단계 필드 추가
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS treatment_stage INTEGER DEFAULT NULL;
-- 0: notStarted, 1: ovulation, 2: waitingTransfer, 3: waitingResult

-- 2. 병원 정보 필드 추가 (JSON으로 저장 - 유연성)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS hospital_info JSONB DEFAULT NULL;
-- 구조: {
--   "name": "병원명",
--   "address": "주소",
--   "phone": "전화번호",
--   "sidoName": "시도명",
--   "sgguName": "시군구명",
--   "ykiho": "요양기관번호",
--   "doctorName": "담당의",
--   "memo": "메모"
-- }

-- 3. 인덱스 (필요시)
-- CREATE INDEX IF NOT EXISTS idx_user_profiles_treatment_stage ON user_profiles(treatment_stage);

-- 4. 기존 hospital_id 컬럼은 유지 (하위 호환성)
-- 새로운 hospital_info가 더 상세한 정보를 담음

COMMENT ON COLUMN user_profiles.treatment_stage IS '치료 단계 (0: 시작전, 1: 과배란, 2: 이식대기, 3: 판정대기)';
COMMENT ON COLUMN user_profiles.hospital_info IS '병원 정보 JSON (name, address, phone, doctorName, memo 등)';
