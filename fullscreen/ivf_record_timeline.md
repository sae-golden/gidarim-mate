# 시험관메이트 - 기록 탭 개선 (타임라인 UI)

## 개요
기존 복잡한 기록/통계 탭을 삭제하고, 타임라인 형태의 히스토리 UI로 전면 개편.
시험관(IVF)과 인공수정(IUI) 모두 지원.

---

## 삭제 항목

| 삭제 | 이유 |
|------|------|
| ❌ 통계 탭 | 불필요 |
| ❌ 기록/통계 탭 전환 | 단일 화면으로 |
| ❌ 요약 카드 (채취/동결/이식 숫자) | 타임라인에서 바로 보임 |
| ❌ 현재 진행 상태 카드 | 타임라인으로 대체 |

---

## 시술 종류

### 새 사이클 시작 시 선택
```
┌─────────────────────────────────────────┐
│ 어떤 시술을 시작하시나요?               │
├─────────────────────────────────────────┤
│                                         │
│       < 시험관 >        인공수정        │
│         ━━━━━                           │
│                                         │
│ 몇 차 시도인가요?                       │
│ ┌─────────────────────────────────────┐ │
│ │ 1차                              ▼ │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ☐ 보관하던 배아를 이식해요              │
│                                         │
│      [취소]        [시작]              │
└─────────────────────────────────────────┘
```

### 인공수정 선택 시
```
┌─────────────────────────────────────────┐
│ 어떤 시술을 시작하시나요?               │
├─────────────────────────────────────────┤
│                                         │
│        시험관        < 인공수정 >       │
│                        ━━━━━━           │
│                                         │
│ 몇 차 시도인가요?                       │
│ ┌─────────────────────────────────────┐ │
│ │ 1차                              ▼ │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ☐ 자연주기로 진행해요                   │
│   (과배란 주사 없이)                    │
│                                         │
│      [취소]        [시작]              │
└─────────────────────────────────────────┘
```

---

## 시술별 단계

### 시험관 (IVF)
| 아이콘 | 단계 | 표현 |
|--------|------|------|
| 💉 | 과배란 | 과배란 중이에요 |
| 🥚 | 채취 | 채취했어요 |
| 🌱 | 이식 | 이식했어요 |
| ❄️ | 동결 | 동결했어요 |

### 인공수정 (IUI)
| 아이콘 | 단계 | 표현 | 비고 |
|--------|------|------|------|
| 💉 | 과배란 | 과배란 중이에요 | 자연주기면 생략 |
| 💫 | 인공수정 | 인공수정 했어요 | |

---

## 타임라인 UI

### 첫 화면 (시술 선택)

기록 탭 첫 진입 시 또는 진행 중인 사이클이 없을 때:

```
┌─────────────────────────────────────────┐
│ 기록                               🕐  │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│         어떤 시술을 시작하시나요?        │
│                                         │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ │             시험관                  │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ │            인공수정                 │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│            지난 기록 보기               │
└─────────────────────────────────────────┘
```

### 시험관 선택 시 → 바텀시트

```
┌─────────────────────────────────────────┐
│                   ──                    │
│                                         │
│ 시험관                                  │
│                                         │
│ 몇 차 시도인가요?                       │
│ ┌─────────────────────────────────────┐ │
│ │ 1차                              ▼ │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ☐ 보관하던 배아를 이식해요              │
│   (채취 단계 생략)                      │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │             시작하기                │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 인공수정 선택 시 → 바텀시트

```
┌─────────────────────────────────────────┐
│                   ──                    │
│                                         │
│ 인공수정                                │
│                                         │
│ 몇 차 시도인가요?                       │
│ ┌─────────────────────────────────────┐ │
│ │ 1차                              ▼ │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ☐ 자연주기로 진행해요                   │
│   (과배란 단계 생략)                    │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │             시작하기                │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 시작 후 빈 타임라인

```
┌─────────────────────────────────────────┐
│ 기록                               🕐  │
│ 1차 시험관                       [편집] │
│ 시작 2026.01.02                         │
├─────────────────────────────────────────┤
│                                         │
│         차근차근 함께 기록해요          │
│                                         │
│   ○ ── 첫 단계를 기록해주세요      [+]  │
│                                         │
├─────────────────────────────────────────┤
│   새로운 시도 시작하기               >  │
└─────────────────────────────────────────┘
```

### 삭제 항목

| 항목 | 이유 |
|------|------|
| "이번 사이클 결과 입력하기" | 시작 전에 불필요 |
| 빈 타임라인 노드들 | 혼란스러움 |
| 과도한 이모지 | 심플하게 |

---

### 시험관 기본 화면
```
┌─────────────────────────────────────────┐
│ 기록                                    │
│ 1차 채취                         [편집] │
├─────────────────────────────────────────┤
│                                         │
│ 시작 2025.12.01                         │
│                                         │
│   💉 ── 과배란 중이에요                 │
│   │    12.01                            │
│   │                                     │
│   │                                     │
│   🥚 ── 채취했어요                      │
│   │    12.18 · 6개                      │
│   │                                     │
│   │                                     │
│   🌱 ── 이식했어요                      │
│   │    12.26 · 5일 배아 · 2개           │
│   │                                     │
│   │                                     │
│   ○ ── 다음 단계를 기록해주세요    [+]  │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│ 🥚 새로운 채취 시작하기              >  │
├─────────────────────────────────────────┤
│           🕐 지난 기록 보기             │
└─────────────────────────────────────────┘
```

### 종료 시 (성공)
```
│   🌱 ── 이식했어요                      │
│   │    12.26 · 5일 배아 · 2개           │
│   │                                     │
│   │                                     │
│   🎉 ── 좋은 소식이 있어요!             │
│        01.05                            │
│                                         │
│ 종료 2025.01.05                         │
```

### 종료 시 (아쉬운 결과)
```
│   🌱 ── 이식했어요                      │
│   │    12.26 · 5일 배아 · 2개           │
│   │                                     │
│   │                                     │
│   💜 ── 아쉽지만 다음을 준비해요        │
│        01.05                            │
│                                         │
│ 종료 2025.01.05                         │
```

### 인공수정 타임라인 (과배란 주기)
```
┌─────────────────────────────────────────┐
│ 기록                                    │
│ 1차 인공수정                     [편집] │
├─────────────────────────────────────────┤
│                                         │
│ 시작 2025.12.01                         │
│                                         │
│   💉 ── 과배란 중이에요                 │
│   │    12.01                            │
│   │                                     │
│   │                                     │
│   💫 ── 인공수정 했어요                 │
│   │    12.14                            │
│   │                                     │
│   │                                     │
│   ○ ── 다음 단계를 기록해주세요    [+]  │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│ 💫 새로운 시도 시작하기              >  │
├─────────────────────────────────────────┤
│           🕐 지난 기록 보기             │
└─────────────────────────────────────────┘
```

### 인공수정 타임라인 (자연주기)
```
┌─────────────────────────────────────────┐
│ 기록                                    │
│ 2차 인공수정 · 자연주기          [편집] │
├─────────────────────────────────────────┤
│                                         │
│ 시작 2025.01.05                         │
│                                         │
│   💫 ── 인공수정 했어요                 │
│   │    01.15                            │
│   │                                     │
│   │                                     │
│   🎉 ── 좋은 소식이 있어요!             │
│        01.29                            │
│                                         │
│ 종료 2025.01.29                         │
│                                         │
└─────────────────────────────────────────┘
```

---

## 시술 내용 (4단계)

| 아이콘 | 단계 | 표현 | 추가 입력 |
|--------|------|------|-----------|
| 💉 | 과배란 | 과배란 중이에요 | 시작일 |
| 🥚 | 채취 | 채취했어요 | 날짜, 채취 개수(선택) |
| 🌱 | 이식 | 이식했어요 | 날짜, 배양일수, 이식 개수 |
| ❄️ | 동결 | 동결했어요 | 날짜, 배양일수, 동결 개수 |

---

## 종료 결과 (4가지)

| 아이콘 | 결과 | 표현 |
|--------|------|------|
| 🎉 | 성공 | 좋은 소식이 있어요! |
| ❄️ | 동결 후 대기 | 동결하고 기다리기로 했어요 |
| 💜 | 중단/쉬어가기 | 이번엔 쉬어가기로 했어요 |
| 💜 | 착상 실패 | 아쉽지만 다음을 준비해요 |

---

## [+] 단계 추가 플로우

### Step 1: 단계 선택 (시험관)
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 어떤 단계를 기록할까요?                 │
├─────────────────────────────────────────┤
│                                         │
│   💉  과배란 중이에요                   │
│                                         │
│   🥚  채취했어요                        │
│                                         │
│   🌱  이식했어요                        │
│                                         │
│   ❄️  동결했어요                        │
│                                         │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│                                         │
│   🏁  이번 시도 마무리하기              │
│                                         │
└─────────────────────────────────────────┘
```

### Step 1: 단계 선택 (인공수정 - 과배란 주기)
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 어떤 단계를 기록할까요?                 │
├─────────────────────────────────────────┤
│                                         │
│   💉  과배란 중이에요                   │
│                                         │
│   💫  인공수정 했어요                   │
│                                         │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│                                         │
│   🏁  이번 시도 마무리하기              │
│                                         │
└─────────────────────────────────────────┘
```

### Step 1: 단계 선택 (인공수정 - 자연주기)
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 어떤 단계를 기록할까요?                 │
├─────────────────────────────────────────┤
│                                         │
│   💫  인공수정 했어요                   │
│                                         │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│                                         │
│   🏁  이번 시도 마무리하기              │
│                                         │
└─────────────────────────────────────────┘
```

### Step 2-A: 과배란 선택 시
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 💉 과배란 중이에요                      │
├─────────────────────────────────────────┤
│                                         │
│ 📅 시작일                               │
│ ┌─────────────────────────────────────┐ │
│ │ 2025.12.01                       📅 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │              완료                   │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### Step 2-B: 채취 선택 시
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 🥚 채취했어요                           │
├─────────────────────────────────────────┤
│                                         │
│ 📅 날짜                                 │
│ ┌─────────────────────────────────────┐ │
│ │ 2025.12.18                       📅 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 🥚 채취             [-]   12개   [+]    │
│                                         │
│ 🧫 성숙 (M2)        [-]   10개   [+]    │
│                            (선택 입력)  │
│                                         │
│ 💉 수정             [-]    8개   [+]    │
│                            (선택 입력)  │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │              완료                   │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

**채취 과정 설명:**
```
난자 채취 (12개)
    ↓
성숙도 분류
- 성숙난자 (M2): 수정 가능
- 중간/미성숙: 추가 배양 필요
    ↓
수정 시도
    ↓
수정된 배아 (8개)
```

### Step 2-C: 이식 선택 시 (여러 배아 지원)
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 🌱 이식했어요                           │
├─────────────────────────────────────────┤
│                                         │
│ 📅 날짜                                 │
│ ┌─────────────────────────────────────┐ │
│ │ 2025.12.26                       📅 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 🌱 이식 배아                            │
│ ┌─────────────────────────────────────┐ │
│ │ 5일      ▼         1개      ▼    ✕ │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 3일      ▼         1개      ▼    ✕ │ │
│ └─────────────────────────────────────┘ │
│                                         │
│            [+ 배아 추가]                │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │              완료                   │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

**배양일수 옵션:** 2일, 3일, 4일, 5일, 6일

### Step 2-D: 동결 선택 시 (여러 배양일수 지원)
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ ❄️ 동결했어요                           │
├─────────────────────────────────────────┤
│                                         │
│ 📅 날짜                                 │
│ ┌─────────────────────────────────────┐ │
│ │ 2025.12.20                       📅 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ❄️ 동결 배아                            │
│ ┌─────────────────────────────────────┐ │
│ │ 5일      ▼         2개      ▼    ✕ │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 3일      ▼         1개      ▼    ✕ │ │
│ └─────────────────────────────────────┘ │
│                                         │
│            [+ 배아 추가]                │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │              완료                   │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### Step 2-E: 인공수정 선택 시
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 💫 인공수정 했어요                      │
├─────────────────────────────────────────┤
│                                         │
│ 📅 날짜                                 │
│ ┌─────────────────────────────────────┐ │
│ │ 2025.12.14                       📅 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │              완료                   │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### Step 2-E: 마무리 선택 시
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 이번 시도는 어떻게 마무리됐나요?        │
├─────────────────────────────────────────┤
│                                         │
│   🎉  좋은 소식이 있어요!               │
│                                         │
│   ❄️  동결하고 기다리기로 했어요        │
│                                         │
│   💜  이번엔 쉬어가기로 했어요          │
│                                         │
│   💜  아쉽지만 다음을 준비해요          │
│                                         │
└─────────────────────────────────────────┘
```

---

## 타임라인 편집

### 항목 탭 시 → 바텀시트로 편집
```
┌─────────────────────────────────────────┐
│                   ──                    │
│ 🥚 채취했어요                           │
├─────────────────────────────────────────┤
│                                         │
│ 📅 날짜                                 │
│ ┌─────────────────────────────────────┐ │
│ │ 2025.12.18                       📅 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 🥚 채취 개수                            │
│ ┌─────────────────────────────────────┐ │
│ │        [-]      6개      [+]        │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌───────────────┐ ┌───────────────────┐ │
│ │     삭제      │ │       완료        │ │
│ └───────────────┘ └───────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## 데이터 모델

```dart
class TreatmentCycle {
  String id;
  TreatmentType type;        // ivf, iui
  int cycleNumber;           // 1차, 2차...
  bool isNaturalCycle;       // 자연주기 여부 (인공수정만)
  bool isFrozenTransfer;     // 동결배아 이식 여부 (시험관만)
  DateTime startDate;        // 시작일
  DateTime? endDate;         // 종료일
  List<TreatmentEvent> events;  // 타임라인 이벤트들
  CycleResult? result;       // 종료 결과
}

enum TreatmentType {
  ivf,   // 시험관
  iui,   // 인공수정
}

class TreatmentEvent {
  String id;
  EventType type;            // stimulation, retrieval, transfer, freezing, insemination
  DateTime date;             // 날짜
  
  // 채취 관련 (retrieval)
  int? retrievedCount;       // 채취 개수
  int? matureCount;          // 성숙난자 (M2) 개수 (선택)
  int? fertilizedCount;      // 수정된 배아 개수 (선택)
  
  // 이식/동결 관련 (transfer, freezing)
  List<EmbryoInfo>? embryos; // 배아 정보 리스트 (여러 배양일수 지원)
  
  DateTime createdAt;
}

class EmbryoInfo {
  int days;                  // 배양일수 (2~6일)
  int count;                 // 개수
}

enum EventType {
  stimulation,   // 💉 과배란
  retrieval,     // 🥚 채취 (시험관)
  transfer,      // 🌱 이식 (시험관)
  freezing,      // ❄️ 동결 (시험관)
  insemination,  // 💫 인공수정 (인공수정)
}

enum CycleResult {
  success,       // 🎉 좋은 소식이 있어요!
  frozen,        // ❄️ 동결하고 기다리기로 했어요
  rest,          // 💜 이번엔 쉬어가기로 했어요
  nextTime,      // 💜 아쉽지만 다음을 준비해요
}
```

---

## 시술별 단계 필터링

```dart
List<EventType> getAvailableEvents(TreatmentCycle cycle) {
  if (cycle.type == TreatmentType.iui) {
    // 인공수정
    if (cycle.isNaturalCycle) {
      // 자연주기: 과배란 없음
      return [EventType.insemination];
    } else {
      // 과배란 주기
      return [EventType.stimulation, EventType.insemination];
    }
  } else {
    // 시험관
    if (cycle.isFrozenTransfer) {
      // 동결배아 이식: 채취 없음
      return [EventType.stimulation, EventType.transfer];
    } else {
      return [EventType.stimulation, EventType.retrieval, EventType.transfer, EventType.freezing];
    }
  }
}
```

---

## 타임라인 컴포넌트

### 타임라인 카드 표시 예시
```
│
💉 ── 과배란 중이에요
│    12.01
│
│
🥚 ── 채취했어요
│    12.18 · 12개 → 성숙 10개 → 수정 8개
│
│
❄️ ── 동결했어요
│    12.20 · 5일 2개, 3일 1개
│
│
🌱 ── 이식했어요
│    12.26 · 5일 1개, 3일 1개
│
│
○ ── 다음 단계를 기록해주세요 [+]
```

### 표시 규칙
- 채취: `12개` 또는 `12개 → 성숙 10개 → 수정 8개` (입력한 만큼)
- 이식/동결: 배양일수별로 나열 `5일 2개, 3일 1개`
- 날짜는 MM.DD 형식

```dart
Widget buildTimeline(TreatmentCycle cycle) {
  return Column(
    children: [
      // 시작
      TimelineStart(date: cycle.startDate),
      
      // 이벤트들
      ...cycle.events.map((event) => TimelineEvent(
        icon: event.type.icon,
        title: event.type.displayText,
        date: event.date,
        detail: event.detailText,
        onTap: () => showEditSheet(event),
      )),
      
      // 다음 단계 또는 종료
      if (cycle.result == null)
        TimelineAddButton(onTap: () => showAddSheet())
      else
        TimelineEnd(result: cycle.result, date: cycle.endDate),
    ],
  );
}
```

---

## 타임라인 스타일

```dart
// 라인 스타일
Container(
  width: 2,
  color: Color(0xFFE9D5FF),  // 연보라
)

// 아이콘 원
Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: Color(0xFFF3E8FF),  // 연보라 배경
    shape: BoxShape.circle,
    border: Border.all(color: Color(0xFF9B7ED9), width: 2),
  ),
  child: Center(child: Text(icon)),
)

// 마지막 추가 버튼 (빈 원)
Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(color: Color(0xFFD1D5DB), width: 2, style: BorderStyle.dashed),
  ),
)
```

---

## 피검사 기록

### 개요
타임라인에서 피검사 수치를 기록하고 추적할 수 있는 기능

### 진입점
기록 추가 시 피검사 기록 옵션 추가:

```
┌─────────────────────────────────────────┐
│ + 기록 추가                             │
├─────────────────────────────────────────┤
│   과배란 시작                           │
│   채취                                  │
│   이식                                  │
│   동결                                  │
│   ─────────────────────────────────     │
│   피검사 기록                           │
└─────────────────────────────────────────┘
```

### 피검사 기록 화면

```
┌─────────────────────────────────────────┐
│ ←        피검사 기록                    │
├─────────────────────────────────────────┤
│                                         │
│ 날짜                                    │
│ ┌─────────────────────────────────────┐ │
│ │ 2026.01.06                        ▼ │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 어떤 수치를 기록할까요?                 │
│ (해당하는 항목을 선택하세요)            │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  E2 (에스트라디올)                  │ │
│ │  난포 성장 확인                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  FSH                                │ │
│ │  난포자극호르몬                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  LH                                 │ │
│ │  배란 징후 확인                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  P4 (프로게스테론)                  │ │
│ │  황체 기능                          │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  β-hCG                              │ │
│ │  임신 확인 수치                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  AMH                                │ │
│ │  난소 예비력                        │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  TSH                                │ │
│ │  갑상선 기능                        │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  Vit D                              │ │
│ │  비타민D 수치                       │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 항목 선택 후 입력 필드 표시

```
┌─────────────────────────────────────────┐
│ ←        피검사 기록                    │
├─────────────────────────────────────────┤
│                                         │
│ 2026.01.06                          ▼  │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  ✓ E2 (에스트라디올)                │ │
│ │  ┌─────────────────────────────┐    │ │
│ │  │ 450                  pg/mL │    │ │
│ │  └─────────────────────────────┘    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  ✓ FSH                              │ │
│ │  ┌─────────────────────────────┐    │ │
│ │  │ 6.2                 mIU/mL │    │ │
│ │  └─────────────────────────────┘    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  ○ LH                               │ │
│ │    배란 징후 확인                   │ │
│ └─────────────────────────────────────┘ │
│                                         │
│       ... (나머지 항목들) ...           │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │             저장                    │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 타임라인에 표시

```
   ● ── 과배란 시작
   │    01.02
   │
   │    📋 피검사
   │    01.06
   │    E2: 450 · FSH: 6.2
   │
   ○ ── 다음 단계 기록하기
```

### 수치 정보

| 수치 | 표시명 | 설명 | 단위 |
|------|--------|------|------|
| E2 | E2 (에스트라디올) | 난포 성장 확인 | pg/mL |
| FSH | FSH | 난포자극호르몬 | mIU/mL |
| LH | LH | 배란 징후 확인 | mIU/mL |
| P4 | P4 (프로게스테론) | 황체 기능 | ng/mL |
| hCG | β-hCG | 임신 확인 수치 | mIU/mL |
| AMH | AMH | 난소 예비력 | ng/mL |
| TSH | TSH | 갑상선 기능 | mIU/L |
| VitD | Vit D | 비타민D 수치 | ng/mL |

### 데이터 모델

```dart
class BloodTest {
  final String id;
  final String cycleId;
  final DateTime date;
  final double? e2;       // 에스트라디올
  final double? fsh;      // 난포자극호르몬
  final double? lh;       // 황체형성호르몬
  final double? p4;       // 프로게스테론
  final double? hcg;      // β-hCG
  final double? amh;      // 난소 예비력
  final double? tsh;      // 갑상선
  final double? vitD;     // 비타민D
  final DateTime createdAt;
  
  BloodTest({
    required this.id,
    required this.cycleId,
    required this.date,
    this.e2,
    this.fsh,
    this.lh,
    this.p4,
    this.hcg,
    this.amh,
    this.tsh,
    this.vitD,
    required this.createdAt,
  });
}
```

### Supabase 테이블

```sql
CREATE TABLE blood_tests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  cycle_id UUID REFERENCES treatment_cycles(id) NOT NULL,
  date DATE NOT NULL,
  e2 DECIMAL,
  fsh DECIMAL,
  lh DECIMAL,
  p4 DECIMAL,
  hcg DECIMAL,
  amh DECIMAL,
  tsh DECIMAL,
  vit_d DECIMAL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 정책
ALTER TABLE blood_tests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own blood tests"
ON blood_tests FOR ALL
USING (auth.uid() = user_id);
```

### 코드 가이드

```dart
// 수치 항목 정의
enum BloodTestType {
  e2,
  fsh,
  lh,
  p4,
  hcg,
  amh,
  tsh,
  vitD,
}

extension BloodTestTypeExt on BloodTestType {
  String get displayName {
    switch (this) {
      case BloodTestType.e2: return 'E2 (에스트라디올)';
      case BloodTestType.fsh: return 'FSH';
      case BloodTestType.lh: return 'LH';
      case BloodTestType.p4: return 'P4 (프로게스테론)';
      case BloodTestType.hcg: return 'β-hCG';
      case BloodTestType.amh: return 'AMH';
      case BloodTestType.tsh: return 'TSH';
      case BloodTestType.vitD: return 'Vit D';
    }
  }
  
  String get description {
    switch (this) {
      case BloodTestType.e2: return '난포 성장 확인';
      case BloodTestType.fsh: return '난포자극호르몬';
      case BloodTestType.lh: return '배란 징후 확인';
      case BloodTestType.p4: return '황체 기능';
      case BloodTestType.hcg: return '임신 확인 수치';
      case BloodTestType.amh: return '난소 예비력';
      case BloodTestType.tsh: return '갑상선 기능';
      case BloodTestType.vitD: return '비타민D 수치';
    }
  }
  
  String get unit {
    switch (this) {
      case BloodTestType.e2: return 'pg/mL';
      case BloodTestType.fsh: return 'mIU/mL';
      case BloodTestType.lh: return 'mIU/mL';
      case BloodTestType.p4: return 'ng/mL';
      case BloodTestType.hcg: return 'mIU/mL';
      case BloodTestType.amh: return 'ng/mL';
      case BloodTestType.tsh: return 'mIU/L';
      case BloodTestType.vitD: return 'ng/mL';
    }
  }
}
```

```dart
// 피검사 기록 화면
class BloodTestRecordScreen extends StatefulWidget {
  final String cycleId;
  
  @override
  _BloodTestRecordScreenState createState() => _BloodTestRecordScreenState();
}

class _BloodTestRecordScreenState extends State<BloodTestRecordScreen> {
  DateTime _selectedDate = DateTime.now();
  Set<BloodTestType> _selectedTypes = {};
  Map<BloodTestType, TextEditingController> _controllers = {};
  
  @override
  void initState() {
    super.initState();
    for (var type in BloodTestType.values) {
      _controllers[type] = TextEditingController();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('피검사 기록')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // 날짜 선택
          _buildDatePicker(),
          SizedBox(height: 24),
          
          // 안내 문구
          Text(
            '어떤 수치를 기록할까요?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            '해당하는 항목을 선택하세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          
          // 수치 항목들
          ...BloodTestType.values.map((type) => _buildTestItem(type)),
          
          SizedBox(height: 24),
          
          // 저장 버튼
          ElevatedButton(
            onPressed: _selectedTypes.isEmpty ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9B7ED9),
              minimumSize: Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('저장', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestItem(BloodTestType type) {
    final isSelected = _selectedTypes.contains(type);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Color(0xFF9B7ED9) : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 헤더 (탭하면 선택/해제)
          InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedTypes.remove(type);
                } else {
                  _selectedTypes.add(type);
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Color(0xFF9B7ED9) : Colors.grey[400],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          type.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 입력 필드 (선택 시에만 표시)
          if (isSelected)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _controllers[type],
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  suffixText: type.unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _save() async {
    final bloodTest = BloodTest(
      id: uuid.v4(),
      cycleId: widget.cycleId,
      date: _selectedDate,
      e2: _getValue(BloodTestType.e2),
      fsh: _getValue(BloodTestType.fsh),
      lh: _getValue(BloodTestType.lh),
      p4: _getValue(BloodTestType.p4),
      hcg: _getValue(BloodTestType.hcg),
      amh: _getValue(BloodTestType.amh),
      tsh: _getValue(BloodTestType.tsh),
      vitD: _getValue(BloodTestType.vitD),
      createdAt: DateTime.now(),
    );
    
    await supabase.from('blood_tests').insert(bloodTest.toJson());
    Navigator.pop(context, bloodTest);
  }
  
  double? _getValue(BloodTestType type) {
    if (!_selectedTypes.contains(type)) return null;
    final text = _controllers[type]?.text ?? '';
    return double.tryParse(text);
  }
}
```

---

## 요약

| 항목 | 내용 |
|------|------|
| UI 형태 | 타임라인 (연결된 히스토리) |
| 시술 종류 | 시험관 / 인공수정 선택 |
| 시험관 단계 | 과배란 / 채취 / 이식 / 동결 |
| 인공수정 단계 | 과배란(선택) / 인공수정 |
| 자연주기 | 인공수정에서 과배란 생략 |
| 동결배아 이식 | 시험관에서 채취 생략 |
| 종료 결과 | 4가지 (성공/동결대기/쉬어가기/다음준비) |
| 추가 방식 | [+] → 단계 선택 → 정보 입력 |
| 편집 방식 | 항목 탭 → 바텀시트 |
| 피검사 기록 | E2, FSH, LH, P4, β-hCG, AMH, TSH, Vit D |
| 삭제된 것 | 통계 탭, 요약 카드, 탭 전환, 이번 사이클 결과 |
