# IVF 앱 - 알림 액션 버튼 수정

## 요청 사항
알림에서 바로 액션 선택할 수 있도록 버튼 추가

---

## 알림 구조

### 기본 알림 (알약, 질정, 패치)
```
┌─────────────────────────────────────────┐
│ 🌸 난임메이트            오후 1:00    ∨ │
│ 약을 복용할 시간                        │
│ 오후 1:00 듀파스톤 복용하는 것을        │
│ 잊지 마세요.                            │
│                                         │
│ [다시 울림]  |  [건너뛰기]  |  [복용]   │
└─────────────────────────────────────────┘
```

**버튼 동작:**
- `다시 울림` → 10분/30분 후 다시 알림
- `건너뛰기` → 이번 복용 스킵 처리
- `복용` → 복용 완료 체크 ✓

---

### 주사 알림 (2단계 선택)
```
1단계: 기본 알림
┌─────────────────────────────────────────┐
│ 🌸 난임메이트            오후 8:00    ∨ │
│ 주사 맞을 시간                          │
│ 오후 8:00 고나엘에프 주사하는 것을      │
│ 잊지 마세요.                            │
│                                         │
│ [다시 울림]  |  [건너뛰기]  |  [완료]   │
└─────────────────────────────────────────┘

        ↓ [완료] 누르면

2단계: 주사 부위 선택
┌─────────────────────────────────────────┐
│ 💉 주사 부위 선택                       │
│                                         │
│  💡 추천: 오른쪽 (어제 왼쪽)            │
│                                         │
│     ┌─────────┐   ┌─────────┐          │
│     │         │   │         │          │
│     │  왼쪽   │   │ ★오른쪽 │          │
│     │         │   │         │          │
│     └─────────┘   └─────────┘          │
│                                         │
└─────────────────────────────────────────┘
```

---

## 플로우 정리

### 알약/질정/패치
```
알림 → [복용] → 완료 ✓
```

### 주사
```
알림 → [완료] → 부위 선택 (왼쪽/오른쪽) → 완료 ✓
```

---

## 데이터 저장

```dart
class MedicationLog {
  String medicationId;
  DateTime scheduledTime;    // 예정 시간
  DateTime? completedTime;   // 실제 복용/주사 시간
  MedicationStatus status;   // completed, skipped, snoozed
  String? injectionSide;     // 주사인 경우: 'left' / 'right'
}

enum MedicationStatus {
  pending,    // 대기
  completed,  // 복용/주사 완료
  skipped,    // 건너뜀
  snoozed,    // 다시 울림 설정됨
}
```

---

## 알림 버튼 텍스트

| 약물 종류 | 버튼 1 | 버튼 2 | 버튼 3 |
|-----------|--------|--------|--------|
| 💊 알약 | 다시 울림 | 건너뛰기 | 복용 |
| 💉 주사 | 다시 울림 | 건너뛰기 | 완료 |
| ⚪ 질정 | 다시 울림 | 건너뛰기 | 복용 |
| 🩹 패치 | 다시 울림 | 건너뛰기 | 완료 |

---

## Flutter 구현 참고

### 알림 액션 버튼 (flutter_local_notifications)
```dart
await flutterLocalNotificationsPlugin.show(
  id,
  title,
  body,
  NotificationDetails(
    android: AndroidNotificationDetails(
      'medication_channel',
      '약물 알림',
      actions: [
        AndroidNotificationAction('snooze', '다시 울림'),
        AndroidNotificationAction('skip', '건너뛰기'),
        AndroidNotificationAction('complete', isInjection ? '완료' : '복용'),
      ],
    ),
  ),
);
```

### 액션 핸들러
```dart
void onNotificationAction(String actionId, String? payload) {
  switch (actionId) {
    case 'snooze':
      // 10분 후 다시 알림 예약
      scheduleSnoozeNotification(payload);
      break;
    case 'skip':
      // 건너뛰기 처리
      markAsSkipped(payload);
      break;
    case 'complete':
      final medication = getMedication(payload);
      if (medication.type == MedicationType.injection) {
        // 주사면 부위 선택 화면으로
        showInjectionSideSelector(medication);
      } else {
        // 그 외는 바로 완료 처리
        markAsCompleted(payload);
      }
      break;
  }
}
```
