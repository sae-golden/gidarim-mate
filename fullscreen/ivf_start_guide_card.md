# 시험관메이트 - 홈 화면 시작하기 카드

## 개요
첫 사용자를 위한 가이드 카드. 강제 온보딩 대신 홈 화면에 미완료 항목을 카드로 표시하고, 완료하면 하나씩 사라지는 방식.

---

## UI 설계

### 홈 화면 - 시작하기 카드
```
┌─────────────────────────────────────────┐
│ ✨ 편안한 밤 되세요                  🔔 │
│ 오늘도 한 걸음 더 가까워지고 있어요     │
├─────────────────────────────────────────┤
│ 💜 오늘의 한마디                        │
│    밤사이 좋은 일이 생길 거예요         │
├─────────────────────────────────────────┤
│                                         │
│ 📌 시작하기                             │
│ ┌─────────────────────────────────────┐ │
│ │ 🏥 병원 등록하기                  > │ │
│ ├─────────────────────────────────────┤ │
│ │ 🔔 알림 켜기                      > │ │
│ ├─────────────────────────────────────┤ │
│ │ 💊 첫 약 등록하기                 > │ │
│ ├─────────────────────────────────────┤ │
│ │ 📋 치료 단계 등록하기             > │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 🌸 오늘도 한 걸음                       │
│    아직 등록된 약이 없어요              │
│    아래 + 버튼으로 추가해 보세요        │
│                                         │
└─────────────────────────────────────────┘
```

### 일부 완료 시
```
┌─────────────────────────────────────────┐
│ 📌 시작하기                             │
│ ┌─────────────────────────────────────┐ │
│ │ 🔔 알림 켜기                      > │ │  ← 병원 등록 완료됨
│ ├─────────────────────────────────────┤ │
│ │ 📋 치료 단계 등록하기             > │ │  ← 약 등록 완료됨
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### 전체 완료 시
시작하기 카드 자체가 사라짐! 🎉

---

## 체크리스트 항목

| # | 항목 | 탭 시 이동 | 완료 조건 |
|---|------|-----------|-----------|
| 1 | 🏥 병원 등록하기 | 설정 > 병원 정보 | 병원 저장됨 |
| 2 | 🔔 알림 켜기 | 설정 > 알림 설정 | 알림 ON |
| 3 | 💊 첫 약 등록하기 | 약물 추가 화면 | 약 1개 이상 등록 |
| 4 | 📋 치료 단계 등록하기 | 기록 탭 | 현재 단계 설정됨 |

---

## 데이터 모델

```dart
class OnboardingChecklist {
  bool isHospitalRegistered;    // 병원 등록 여부
  bool isNotificationEnabled;   // 알림 ON 여부
  bool hasMedication;           // 약 등록 여부
  bool hasTreatmentStage;       // 치료 단계 설정 여부
  
  // 모든 항목 완료 여부
  bool get isAllCompleted => 
    isHospitalRegistered && 
    isNotificationEnabled && 
    hasMedication && 
    hasTreatmentStage;
  
  // 미완료 항목 목록
  List<ChecklistItem> get incompleteItems {
    List<ChecklistItem> items = [];
    if (!isHospitalRegistered) items.add(ChecklistItem.hospital);
    if (!isNotificationEnabled) items.add(ChecklistItem.notification);
    if (!hasMedication) items.add(ChecklistItem.medication);
    if (!hasTreatmentStage) items.add(ChecklistItem.treatmentStage);
    return items;
  }
}

enum ChecklistItem {
  hospital,       // 병원 등록
  notification,   // 알림 켜기
  medication,     // 약 등록
  treatmentStage, // 치료 단계
}
```

---

## 표시 로직

```dart
// 홈 화면에서
Widget build(BuildContext context) {
  final checklist = ref.watch(onboardingChecklistProvider);
  
  return Column(
    children: [
      // 오늘의 한마디
      TodayMessageCard(),
      
      // 시작하기 카드 (미완료 항목 있을 때만)
      if (!checklist.isAllCompleted)
        StartGuideCard(items: checklist.incompleteItems),
      
      // 오늘도 한 걸음
      TodayMedicationCard(),
      
      // 곧 만나요
      UpcomingEventCard(),
    ],
  );
}
```

---

## 각 항목별 동작

### 1. 병원 등록하기
```dart
onTap: () {
  Navigator.push(context, HospitalSettingPage());
}
// 병원 저장 시 → isHospitalRegistered = true
```

### 2. 알림 켜기
```dart
onTap: () async {
  // 시스템 알림 권한 요청
  final granted = await NotificationService.requestPermission();
  if (granted) {
    // 앱 내 알림 설정 ON
    ref.read(settingsProvider).setNotificationEnabled(true);
  }
}
// 알림 ON 시 → isNotificationEnabled = true
```

### 3. 첫 약 등록하기
```dart
onTap: () {
  Navigator.push(context, AddMedicationPage());
}
// 약 1개 이상 등록 시 → hasMedication = true
```

### 4. 치료 단계 등록하기
```dart
onTap: () {
  Navigator.push(context, TreatmentRecordPage());
  // 또는 바텀시트로 빠른 선택
  showTreatmentStageSelector(context);
}
// 치료 단계 설정 시 → hasTreatmentStage = true
```

---

## 치료 단계 빠른 선택 (바텀시트)

```
┌─────────────────────────────────────────┐
│ 📋 현재 어떤 단계에 계세요?             │
├─────────────────────────────────────────┤
│                                         │
│   ○ 🌱 아직 시작 전이에요               │
│                                         │
│   ○ 💉 과배란 주사 중이에요             │
│                                         │
│   ○ 🥚 채취 완료, 이식 대기 중이에요    │
│                                         │
│   ○ 🎯 이식 완료, 판정 기다리는 중이에요│
│                                         │
│            [선택 완료]                  │
│                                         │
└─────────────────────────────────────────┘
```

---

## 카드 스타일

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Color(0xFFE9D5FF), width: 1),  // 연보라 테두리
    boxShadow: [
      BoxShadow(
        color: Color(0xFF9B7ED9).withOpacity(0.1),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('📌'),
          SizedBox(width: 8),
          Text('시작하기', style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          )),
        ],
      ),
      SizedBox(height: 12),
      // 미완료 항목 리스트
      ...items.map((item) => ChecklistItemTile(item: item)),
    ],
  ),
)
```

---

## 요약

| 특징 | 설명 |
|------|------|
| 위치 | 홈 화면 상단 (오늘의 한마디 아래) |
| 표시 조건 | 미완료 항목이 1개 이상일 때 |
| 사라지는 조건 | 항목 완료 시 해당 항목만 사라짐 |
| 전체 완료 시 | 카드 자체가 사라짐 |
| 강제성 | 없음 (언제든 할 수 있음) |
