# IVF 약물 알림 앱 - 디자인 시스템

## 디자인 철학

**토스 스타일 + 파스텔톤 + 모던 느낌**

- **미니멀**: 불필요한 요소 제거, 핵심 정보만 표시
- **친근함**: 부드러운 색상과 둥근 모서리로 편안한 느낌
- **명확함**: 한눈에 이해할 수 있는 직관적 UI
- **따뜻함**: 난임 시술의 어려움을 이해하고 응원하는 감성

---

## 색상 팔레트

### Primary Colors (주색상)
- **Pastel Pink**: `#FFB3D9` - 주요 버튼, 강조 요소
- **Pastel Purple**: `#D8B3FF` - 보조 강조, 그라데이션

### Secondary Colors (보조색상)
- **Pastel Mint**: `#B3FFE5` - 완료 상태, 긍정적 피드백
- **Pastel Blue**: `#B3D9FF` - 정보 표시, 차분한 영역
- **Pastel Orange**: `#FFD9B3` - 알림, 주의 필요

### Neutral Colors (중립색상)
- **Background**: `#FAFAFA` - 앱 전체 배경
- **Card Background**: `#FFFFFF` - 카드, 모달 배경
- **Border**: `#E8E8E8` - 구분선, 테두리
- **Text Primary**: `#333333` - 주요 텍스트
- **Text Secondary**: `#999999` - 보조 텍스트
- **Text Disabled**: `#CCCCCC` - 비활성 텍스트

### Status Colors (상태색상)
- **Success**: `#B3FFE5` (Pastel Mint) - 완료, 성공
- **Warning**: `#FFD9B3` (Pastel Orange) - 주의, 알림
- **Error**: `#FFB3B3` (Pastel Red) - 오류, 미완료
- **Info**: `#B3D9FF` (Pastel Blue) - 정보

---

## 타이포그래피

### 폰트 패밀리
- **Primary**: Pretendard (한글/영문 모두 지원)
- **Fallback**: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto

### 폰트 크기
- **H1 (페이지 제목)**: 24px, Bold (700)
- **H2 (섹션 제목)**: 20px, Bold (700)
- **H3 (카드 제목)**: 18px, SemiBold (600)
- **Body Large**: 16px, Regular (400)
- **Body**: 14px, Regular (400)
- **Caption**: 12px, Regular (400)
- **Button**: 16px, SemiBold (600)

### 줄 간격
- **제목**: 1.3
- **본문**: 1.5
- **캡션**: 1.4

---

## 간격 시스템 (Spacing)

8px 기반 그리드 시스템 사용

- **XXS**: 4px
- **XS**: 8px
- **S**: 12px
- **M**: 16px
- **L**: 24px
- **XL**: 32px
- **XXL**: 48px

---

## 컴포넌트 스타일

### 버튼

**Primary Button (주요 버튼)**
- 배경: `#FFB3D9` → `#D8B3FF` (그라데이션)
- 텍스트: `#FFFFFF`
- 높이: 52px
- 모서리: 16px (둥근 모서리)
- 그림자: 0px 4px 12px rgba(255, 179, 217, 0.3)

**Secondary Button (보조 버튼)**
- 배경: `#FFFFFF`
- 텍스트: `#FFB3D9`
- 테두리: 2px solid `#FFB3D9`
- 높이: 52px
- 모서리: 16px

**Text Button (텍스트 버튼)**
- 배경: 투명
- 텍스트: `#FFB3D9`
- 높이: 40px

### 카드

- 배경: `#FFFFFF`
- 모서리: 20px (둥근 모서리)
- 그림자: 0px 2px 16px rgba(0, 0, 0, 0.06)
- 패딩: 20px
- 간격: 12px (카드 사이)

### 입력 필드

- 배경: `#FAFAFA`
- 테두리: 1px solid `#E8E8E8`
- 모서리: 12px
- 높이: 52px
- 패딩: 16px
- Focus 상태: 테두리 `#FFB3D9`

### 아이콘

- 크기: 24px (기본), 20px (작은 아이콘)
- 색상: `#999999` (기본), `#FFB3D9` (활성)
- 스타일: 둥근 선 (Rounded)

---

## 레이아웃

### 화면 구조
- **상단 여백**: 16px (안전 영역 고려)
- **좌우 여백**: 20px
- **하단 여백**: 16px + 네비게이션 바 높이

### 네비게이션 바
- 높이: 64px
- 배경: `#FFFFFF`
- 그림자: 0px -2px 8px rgba(0, 0, 0, 0.04)
- 아이콘 크기: 24px
- 활성 색상: `#FFB3D9`
- 비활성 색상: `#CCCCCC`

---

## 애니메이션

### 전환 효과
- **기본**: ease-out, 200ms
- **페이지 전환**: ease-in-out, 300ms
- **모달**: ease-out, 250ms

### 인터랙션
- **버튼 클릭**: scale(0.98), 100ms
- **카드 터치**: scale(0.99), 150ms
- **스와이프**: ease-out, 200ms

---

## 일러스트레이션 스타일

- **스타일**: 미니멀, 라인 아트
- **색상**: 파스텔톤 (팔레트 내에서 선택)
- **두께**: 2px (선 두께)
- **모서리**: 둥근 모서리
- **표현**: 친근하고 따뜻한 느낌

---

## 이모지 사용

토스 스타일에 맞춰 적절한 이모지 사용으로 친근함 표현

- 💉 주사
- 💊 약
- 📅 캘린더
- ✅ 완료
- 🔔 알림
- 📊 통계
- 🎉 축하
- 💪 응원

---

## 접근성

- **최소 터치 영역**: 44x44px
- **색상 대비**: WCAG AA 기준 (4.5:1 이상)
- **폰트 크기**: 최소 12px
- **포커스 표시**: 명확한 아웃라인

---

## 다크 모드 (선택 사항)

향후 추가 시 고려사항:
- 배경: `#1A1A1A`
- 카드: `#2A2A2A`
- 텍스트: `#FFFFFF`
- Primary 색상은 동일하게 유지
