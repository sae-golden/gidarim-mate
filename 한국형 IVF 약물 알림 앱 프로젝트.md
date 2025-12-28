# 한국형 IVF 약물 알림 앱 프로젝트

**토스 스타일 + 파스텔 퍼플 단일 컬러 디자인**

---

## 📋 프로젝트 개요

한국에는 IVF(시험관 시술) 전문 약물 알림 앱이 없습니다. 해외에는 Embie, Berry Fertility, Bonzun 등의 전문 앱이 있지만, 한국어를 지원하지 않고 한국 병원 프로토콜에 최적화되어 있지 않습니다.

이 프로젝트는 **한국 난임 환자들을 위한 전문 약물 알림 앱**을 개발하는 것을 목표로 합니다.

---

## 🎯 핵심 기능

### 1. 복잡한 스케줄 쉽게 등록
- **처방전 OCR**: 카메라로 처방전을 촬영하면 자동으로 약물 정보 인식
- **음성 입력**: "매일 아침 8시에 FSH 주사" 같은 자연어로 일정 등록
- **텍스트 입력**: 복붙도 가능한 간편한 텍스트 입력
- **캘린더 기반 기간 설정**: 시작일~종료일 선택으로 자동 계산

### 2. 주사 부위 체크 (해외 앱에 없는 기능!)
- 복부 9개 구역으로 나눠서 주사 맞은 위치 기록
- 자동 로테이션 추천: "내일은 오른쪽 위에 맞으세요"
- 주사 부위 히스토리 관리

### 3. 스마트 리마인더
- 정시 알림
- 미체크 시 재알림
- 방해금지 모드 무시 옵션

### 4. 남편과 공유 (향후 구현)
- 카카오톡 알림 연동
- 남편 앱 설치 불필요

---

## 🎨 디자인 시스템

### 색상 팔레트
- **메인 컬러**: 파스텔 퍼플 (#D8B3FF)
- **진한 퍼플**: #B88FE8 (버튼 hover, 강조)
- **연한 퍼플**: #F0E5FF (배경, 카드 강조)
- **중립 색상**: 흰색, 회색 계열

### 디자인 철학
- **토스 스타일**: 미니멀, 깔끔, 친근함
- **단일 컬러**: 파스텔 퍼플만 사용 (알록달록 X)
- **둥근 모서리**: 20px 반경의 부드러운 카드
- **그림자**: 은은한 그림자로 깊이감 표현

---

## 📱 주요 화면

### 1. 온보딩 - 약물 입력 방식 선택
- 처방전 사진 찍기 (가장 빠른 방법)
- 음성으로 말하기
- 텍스트로 입력
- 직접 하나씩 입력

### 2. 메인 대시보드
- 현재 단계 (채취 전, 채취, 이식 등)
- 오늘의 할 일 (주사, 약)
- 진행 상황 (완료율)
- 단계별 흐름

### 3. 주사 부위 입력
- 복부 그림에 터치로 위치 표시
- 어제 맞은 위치 / 내일 추천 위치 표시

### 4. 캘린더 & 통계
- 월간 캘린더 (완료/미완료 표시)
- 완료율, 연속 완료 일수
- 가장 많이 빠진 약

### 5. 치료 기록
- 채취 (개수, 날짜)
- 수정 (수정율)
- 배양 (3일차, 5일차)
- 이식 (날짜, 등급)
- 결과 (임신 판정)

---

## 🛠 기술 스택

### 프론트엔드
- **Flutter** (추천)
  - 크로스 플랫폼 (iOS + Android 동시 개발)
  - 빠른 개발 속도
  - 네이티브 수준의 성능
  - 토스 스타일 UI 구현 용이

### 백엔드 (향후 구현)
- **Firebase** or **Supabase**
  - 사용자 인증
  - 실시간 데이터베이스
  - 푸시 알림

### 주요 패키지
- `provider`: 상태 관리
- `sqflite`: 로컬 데이터베이스
- `flutter_local_notifications`: 알림
- `table_calendar`: 캘린더
- `shared_preferences`: 설정 저장

---

## 📊 MVP 개발 계획

### Phase 1: 기본 기능 (4-6주)
- ✅ 약물 일정 등록 (직접 입력)
- ✅ 오늘의 할 일 표시
- ✅ 알림 기능
- ✅ 주사 부위 기록
- ✅ 캘린더 뷰

### Phase 2: 고급 기능 (4-6주)
- 🔲 처방전 OCR
- 🔲 음성 입력
- 🔲 치료 기록 관리
- 🔲 통계 및 분석

### Phase 3: 공유 기능 (2-4주)
- 🔲 카카오톡 알림 연동
- 🔲 병원 협력 (QR 코드)

---

## 💰 수익 모델

### 1. Freemium 모델 (추천)
- **무료**: 기본 약물 알림, 주사 부위 기록
- **프리미엄 (월 5,900원)**:
  - 처방전 OCR 무제한
  - 음성 입력
  - 치료 기록 상세 분석
  - 남편과 공유 기능
  - 광고 제거

### 2. 병원 제휴
- 병원에서 환자에게 QR 코드 제공
- 병원은 환자 복약 순응도 데이터 확인 가능
- 병원당 월 구독료 또는 환자당 수수료

---

## 📂 프로젝트 구조

```
ivf_app_final/
├── README.md                    # 이 파일
├── docs/                        # 문서
│   ├── korean_ivf_app_plan.md   # 전체 기획서
│   ├── design_system.md         # 디자인 시스템
│   ├── wireframe_v2_improved.md # 와이어프레임
│   ├── competitor_analysis.md   # 경쟁사 분석
│   ├── tech_stack_comparison.md # 기술 스택 비교
│   ├── mvp_cost_estimate.md     # MVP 비용 산정
│   └── revenue_model.md         # 수익 모델
├── code/                        # 코드
│   ├── pubspec.yaml             # Flutter 패키지 설정
│   ├── app_colors.dart          # 색상 상수
│   ├── app_text_styles.dart     # 텍스트 스타일
│   ├── app_spacing.dart         # 간격 시스템
│   ├── app_button.dart          # 공통 버튼 위젯
│   ├── app_card.dart            # 공통 카드 위젯
│   ├── medication.dart          # 약물 모델
│   ├── treatment_stage.dart     # 치료 단계 모델
│   └── home_screen.dart         # 메인 화면
└── designs/                     # 디자인 이미지 (12개 화면)
```

---

## 🚀 시작하기

### 1. Flutter 설치
```bash
# Flutter SDK 다운로드
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz

# PATH 설정
export PATH="$PATH:$HOME/flutter/bin"

# Flutter 확인
flutter --version
```

### 2. 프로젝트 생성
```bash
flutter create --project-name ivf_medication_app --org com.ivfapp ivf_medication_app
cd ivf_medication_app
```

### 3. 패키지 설치
`pubspec.yaml` 파일을 `code/pubspec.yaml`로 교체한 후:
```bash
flutter pub get
```

### 4. 코드 복사
`code/` 디렉토리의 파일들을 Flutter 프로젝트의 `lib/` 디렉토리에 복사:
```bash
mkdir -p lib/constants lib/models lib/widgets lib/screens
cp code/app_*.dart lib/constants/
cp code/*_stage.dart code/medication.dart lib/models/
cp code/app_button.dart code/app_card.dart lib/widgets/
cp code/home_screen.dart lib/screens/
```

### 5. 실행
```bash
flutter run
```

---

## 📝 다음 단계

### 즉시 구현 가능
1. **약물 입력 화면** 구현
2. **캘린더 화면** 구현
3. **주사 부위 입력 화면** 구현
4. **로컬 데이터베이스** 연동 (sqflite)
5. **알림 기능** 구현 (flutter_local_notifications)

### 향후 구현
1. **처방전 OCR** (Google ML Kit)
2. **음성 입력** (speech_to_text)
3. **카카오톡 알림** (카카오 API)
4. **병원 협력** (QR 코드, 백엔드 필요)

---

## 📞 문의

프로젝트 관련 문의사항이 있으시면 언제든지 연락주세요!

---

**© 2025 IVF 약물 알림 앱 프로젝트**
