# 시험관메이트 - 알림 시스템 개선

## 개요
모든 약물 알림을 알람 스타일(끌 때까지 울림)로 기본 설정하고, 미완료 시 재알림 기능 추가. 주사는 완료 시 부위 선택 팝업 표시.

---

## 알림 설정 UI

```
┌─────────────────────────────────────────┐
│ 🔔 알림 설정                            │
├─────────────────────────────────────────┤
│                                         │
│ 알림 받기                          [ON] │
│                                         │
│ 미리 알림                          [ON] │
│ 미리 알림 시간                [10분 전] │
│                                         │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│                                         │
│ 🔊 알람 스타일 (끌 때까지 울림)    [ON] │
│                                         │
│ 🔁 미완료 시 재알림                [ON] │
│ 재알림 간격                   [10분 후] │
│                                         │
│ 💡 약 복용을 완료하지 않으면            │
│    10분 후 다시 알려드려요              │
│                                         │
└─────────────────────────────────────────┘
```

---

## 설정 옵션

| 설정 | 기본값 | 옵션 | 설명 |
|------|--------|------|------|
| 알림 받기 | ON | ON/OFF | 전체 알림 on/off |
| 미리 알림 | ON | ON/OFF | 복용 전 미리 알림 |
| 미리 알림 시간 | 10분 전 | 5분/10분/15분/30분 | 미리 알림 타이밍 |
| 알람 스타일 | **ON** | ON/OFF | 끌 때까지 울림 + 화면 켜짐 |
| 미완료 시 재알림 | **ON** | ON/OFF | 완료 안 하면 다시 알림 |
| 재알림 간격 | 10분 후 | 5분/10분/15분/30분 | 재알림 간격 |

---

## 알람 스타일 화면 (풀스크린)

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│              💉                         │
│                                         │
│         고나엘에프 주사                 │
│           밤 10:00                      │
│                                         │
│         🔊 알림음 울리는 중...          │
│                                         │
│                                         │
│   ┌───────────┐     ┌───────────┐      │
│   │  다시     │     │   완료    │      │
│   │  알림     │     │           │      │
│   └───────────┘     └───────────┘      │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

---

## 알림 완료 플로우

### 알약/질정/패치 💊⚪🩹
```
🔔 알람 울림 (화면 켜짐)
     │
     ├─ [완료] 탭 → ✅ 바로 완료!
     │
     ├─ [다시 알림] 탭 → ⏰ 설정된 간격 후 재알림
     │
     └─ 무시 (재알림 ON인 경우) → ⏰ 설정된 간격 후 자동 재알림
```

### 주사 💉
```
🔔 알람 울림 (화면 켜짐)
     │
     ├─ [완료] 탭 → 📍 주사 부위 선택 팝업
     │                    │
     │                    └─ 부위 선택 → ✅ 완료!
     │
     ├─ [다시 알림] 탭 → ⏰ 설정된 간격 후 재알림
     │
     └─ 무시 (재알림 ON인 경우) → ⏰ 설정된 간격 후 자동 재알림
```

---

## 주사 부위 선택 팝업

```
┌─────────────────────────────────────────┐
│                                         │
│         💉 어디에 맞았나요?             │
│                                         │
│         💡 어제: 왼쪽                   │
│            추천: 오른쪽 ⭐               │
│                                         │
│      ┌───────────┐  ┌───────────┐      │
│      │           │  │     ⭐    │      │
│      │   왼쪽    │  │   오른쪽   │      │
│      │           │  │           │      │
│      └───────────┘  └───────────┘      │
│                                         │
└─────────────────────────────────────────┘
```

### 부위 로테이션 로직
- 왼쪽 → 오른쪽 → 왼쪽 → 오른쪽 (번갈아가며)
- 어제 맞은 부위 표시
- 오늘 추천 부위 ⭐ 표시

---

## 재알림 플로우

```
⏰ 밤 10:00 - 첫 알람
     │
     └─ 무시 또는 [다시 알림]
            │
            ▼
⏰ 밤 10:10 - 재알림 (1차)
     │
     └─ 무시 또는 [다시 알림]
            │
            ▼
⏰ 밤 10:20 - 재알림 (2차)
     │
     └─ 무시 또는 [다시 알림]
            │
            ▼
        ... (완료할 때까지 반복)
```

---

## 데이터 모델

```dart
class NotificationSettings {
  bool isEnabled;              // 알림 받기
  bool preNotification;        // 미리 알림
  int preNotificationMinutes;  // 미리 알림 시간 (분)
  bool alarmStyle;             // 알람 스타일 (끌 때까지 울림)
  bool repeatIfNotCompleted;   // 미완료 시 재알림
  int repeatIntervalMinutes;   // 재알림 간격 (분)
}

class MedicationLog {
  String medicationId;
  DateTime scheduledTime;      // 예정 시간
  DateTime? completedTime;     // 실제 완료 시간
  MedicationStatus status;     // completed, skipped, pending
  String? injectionSide;       // 주사인 경우: 'left' / 'right'
  int snoozeCount;             // 다시 알림 횟수
}

enum MedicationStatus {
  pending,     // 대기
  completed,   // 완료
  skipped,     // 건너뜀
  snoozed,     // 다시 알림 중
}
```

---

## 구현 패키지

| 패키지 | 용도 |
|--------|------|
| `alarm` | 알람 스타일 (끌 때까지 울림, 화면 켜짐) |
| `flutter_local_notifications` | 일반 푸시 알림 |
| `shared_preferences` | 설정 저장 |

---

## 알람 스타일 구현 예시

```dart
// alarm 패키지 사용
import 'package:alarm/alarm.dart';

Future<void> setMedicationAlarm(Medication med) async {
  final settings = await getNotificationSettings();
  
  final alarmSettings = AlarmSettings(
    id: med.id.hashCode,
    dateTime: med.scheduledTime,
    assetAudioPath: 'assets/alarm_sound.mp3',
    loopAudio: settings.alarmStyle,  // 알람 스타일이면 반복
    vibrate: true,
    fadeDuration: 3.0,
    notificationTitle: med.name,
    notificationBody: '${med.type.displayName} 시간이에요!',
    enableNotificationOnKill: true,
  );
  
  await Alarm.set(alarmSettings: alarmSettings);
}

// 알람 화면에서 완료 버튼 탭 시
void onCompletePressed(Medication med) {
  Alarm.stop(med.id.hashCode);  // 알람 중지
  
  if (med.type == MedicationType.injection) {
    // 주사면 부위 선택 팝업
    showInjectionSiteDialog(med);
  } else {
    // 알약/질정/패치면 바로 완료
    completeMedication(med);
  }
}

// 다시 알림 버튼 탭 시
void onSnoozePressed(Medication med) {
  Alarm.stop(med.id.hashCode);
  
  final settings = await getNotificationSettings();
  final snoozeTime = DateTime.now().add(
    Duration(minutes: settings.repeatIntervalMinutes)
  );
  
  // 재알림 설정
  setMedicationAlarm(med.copyWith(scheduledTime: snoozeTime));
}
```

---

## 주사 부위 선택 다이얼로그

```dart
void showInjectionSiteDialog(Medication med) {
  final lastSide = getLastInjectionSide();  // 어제 부위
  final recommendedSide = lastSide == 'left' ? 'right' : 'left';
  
  showDialog(
    context: context,
    barrierDismissible: false,  // 바깥 탭 막기
    builder: (context) => AlertDialog(
      title: Text('💉 어디에 맞았나요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💡 어제: ${lastSide == 'left' ? '왼쪽' : '오른쪽'}'),
          Text('   추천: ${recommendedSide == 'left' ? '왼쪽' : '오른쪽'} ⭐'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => selectSide(med, 'left'),
                child: Text('왼쪽'),
              ),
              ElevatedButton(
                onPressed: () => selectSide(med, 'right'),
                style: recommendedSide == 'right' 
                  ? ElevatedButton.styleFrom(primary: Colors.purple)
                  : null,
                child: Text('오른쪽 ${recommendedSide == 'right' ? '⭐' : ''}'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

---

## 요약

| 항목 | 내용 |
|------|------|
| 기본 알림 방식 | **알람 스타일** (끌 때까지 울림) |
| 미완료 시 | **자동 재알림** (기본 10분 후) |
| 주사 완료 시 | **부위 선택 팝업** (왼쪽/오른쪽) |
| 알약/질정/패치 | 바로 완료 |
| 설정에서 변경 | 모두 ON/OFF 가능 |
