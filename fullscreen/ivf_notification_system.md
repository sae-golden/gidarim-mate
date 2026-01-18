# 시험관메이트 - 알림 시스템 개선

## 개요
미리 알림은 일반 푸시, 정각/리마인드는 풀스크린 알람으로 구분.
약물 타입별 메시지 및 버튼 텍스트 통일.

---

## 알림 플로우

```
10분 전: 📱 푸시
            ├→ [완료 버튼] → 앱 열림 + 체크 ✅
            └→ [알겠어요] → 닫힘

정각:    📞 풀스크린 (화면 켜짐 + 소리/진동)
            ├→ [완료 버튼] → 앱 열림 + 체크 ✅
            └→ [조금 이따 알려줘] → 5분 후 다시 풀스크린

5분 후:  📞 풀스크린 (1차 리마인드)
            ├→ [완료 버튼] → 앱 열림 + 체크 ✅
            └→ [조금 이따 알려줘] → 5분 후 다시

10분 후: 📞 풀스크린 (2차 리마인드)

15분 후: 📞 풀스크린 (3차, 마지막)
```

---

## 약물 타입별 메시지

| 타입 | 아이콘 | 제목 (푸시) | 제목 (풀스크린) | 완료 버튼 |
|------|--------|-------------|-----------------|-----------|
| 주사 (injection) | 💉 | 곧 주사 맞을 시간이에요 | 주사 맞을 시간이에요 | 맞았어요 |
| 알약 (oral) | 💊 | 곧 약 먹을 시간이에요 | 약 먹을 시간이에요 | 먹었어요 |
| 질정 (suppository) | 💊 | 곧 질정 사용할 시간이에요 | 질정 사용할 시간이에요 | 완료했어요 |
| 패치 (patch) | 🩹 | 곧 패치 붙일 시간이에요 | 패치 붙일 시간이에요 | 붙였어요 |

---

## 미리 알림 (10분 전) - 푸시

### 주사
```
┌─────────────────────────────────────────┐
│ 💉 시험관메이트                    10분 전 │
├─────────────────────────────────────────┤
│ 곧 주사 맞을 시간이에요                 │
│ 고나엘에프 · 밤 10:00                   │
├─────────────────────────────────────────┤
│      [맞았어요]        [알겠어요]        │
└─────────────────────────────────────────┘
```

### 알약
```
┌─────────────────────────────────────────┐
│ 💊 시험관메이트                    10분 전 │
├─────────────────────────────────────────┤
│ 곧 약 먹을 시간이에요                   │
│ 프로기노바 1알 · 오후 6:00              │
├─────────────────────────────────────────┤
│      [먹었어요]        [알겠어요]        │
└─────────────────────────────────────────┘
```

### 질정
```
┌─────────────────────────────────────────┐
│ 💊 시험관메이트                    10분 전 │
├─────────────────────────────────────────┤
│ 곧 질정 사용할 시간이에요               │
│ 유트로게스탄 · 밤 10:00                 │
├─────────────────────────────────────────┤
│     [완료했어요]       [알겠어요]        │
└─────────────────────────────────────────┘
```

### 패치
```
┌─────────────────────────────────────────┐
│ 🩹 시험관메이트                    10분 전 │
├─────────────────────────────────────────┤
│ 곧 패치 붙일 시간이에요                 │
│ 에스트라디올 패치 · 오전 9:00           │
├─────────────────────────────────────────┤
│      [붙였어요]        [알겠어요]        │
└─────────────────────────────────────────┘
```

---

## 정각 알림 - 풀스크린

### 주사
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                 💉                      │
│                                         │
│            고나엘에프                    │
│              주사                       │
│                                         │
│           밤 10:00                      │
│                                         │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │           맞았어요                  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│          조금 이따 알려줘               │
│                                         │
└─────────────────────────────────────────┘
```

### 알약
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                 💊                      │
│                                         │
│            프로기노바                    │
│             1알                         │
│                                         │
│           오후 6:00                     │
│                                         │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │           먹었어요                  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│          조금 이따 알려줘               │
│                                         │
└─────────────────────────────────────────┘
```

### 질정
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                 💊                      │
│                                         │
│           유트로게스탄                   │
│              질정                       │
│                                         │
│           밤 10:00                      │
│                                         │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │          완료했어요                 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│          조금 이따 알려줘               │
│                                         │
└─────────────────────────────────────────┘
```

### 패치
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                 🩹                      │
│                                         │
│         에스트라디올 패치                │
│                                         │
│                                         │
│           오전 9:00                     │
│                                         │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │           붙였어요                  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│          조금 이따 알려줘               │
│                                         │
└─────────────────────────────────────────┘
```

---

## 리마인드 알림 (미응답 시) - 풀스크린

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                 💊                      │
│                                         │
│            프로기노바                    │
│             1알                         │
│                                         │
│           오후 6:00                     │
│        ⚠️ 아직 복용 전이에요            │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │           먹었어요                  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│          조금 이따 알려줘               │
│                                         │
└─────────────────────────────────────────┘
```

- 최대 3회까지 리마인드
- 5분 간격으로 재알림

---

## 버튼 정리

### 푸시 알림 (미리 알림)
| 버튼 | 동작 |
|------|------|
| 맞았어요 / 먹었어요 / 완료했어요 / 붙였어요 | 앱 열림 → 복용 체크 |
| 알겠어요 | 알림만 닫힘 |

### 풀스크린 알림 (정각 / 리마인드)
| 버튼 | 동작 |
|------|------|
| 맞았어요 / 먹었어요 / 완료했어요 / 붙였어요 | 앱 열림 → 복용 체크 |
| 조금 이따 알려줘 | 5분 후 다시 풀스크린 |

---

## 구현 패키지

| 패키지 | 용도 |
|--------|------|
| `flutter_local_notifications` | 미리 알림 (푸시) |
| `alarm` | 풀스크린 알람 (정각/리마인드) |

---

## 코드 가이드

### 약물 타입 enum
```dart
enum MedicationType {
  injection,    // 주사
  oral,         // 알약
  suppository,  // 질정
  patch,        // 패치
}

extension MedicationTypeExt on MedicationType {
  String get icon {
    switch (this) {
      case MedicationType.injection: return '💉';
      case MedicationType.oral: return '💊';
      case MedicationType.suppository: return '💊';
      case MedicationType.patch: return '🩹';
    }
  }
  
  String get preNotificationTitle {
    switch (this) {
      case MedicationType.injection: return '곧 주사 맞을 시간이에요';
      case MedicationType.oral: return '곧 약 먹을 시간이에요';
      case MedicationType.suppository: return '곧 질정 사용할 시간이에요';
      case MedicationType.patch: return '곧 패치 붙일 시간이에요';
    }
  }
  
  String get fullscreenTitle {
    switch (this) {
      case MedicationType.injection: return '주사 맞을 시간이에요';
      case MedicationType.oral: return '약 먹을 시간이에요';
      case MedicationType.suppository: return '질정 사용할 시간이에요';
      case MedicationType.patch: return '패치 붙일 시간이에요';
    }
  }
  
  String get completeButtonText {
    switch (this) {
      case MedicationType.injection: return '맞았어요';
      case MedicationType.oral: return '먹었어요';
      case MedicationType.suppository: return '완료했어요';
      case MedicationType.patch: return '붙였어요';
    }
  }
}
```

### 알림 스케줄링
```dart
class NotificationService {
  // 미리 알림 (10분 전) - 푸시
  Future<void> schedulePreNotification({
    required int id,
    required String medicationName,
    required MedicationType type,
    required DateTime scheduledTime,
  }) async {
    final preTime = scheduledTime.subtract(Duration(minutes: 10));
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '${type.icon} 시험관메이트',
      type.preNotificationTitle,
      tz.TZDateTime.from(preTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'pre_notification',
          '미리 알림',
          actions: [
            AndroidNotificationAction(
              'complete',
              type.completeButtonText,
            ),
            AndroidNotificationAction(
              'dismiss',
              '알겠어요',
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  // 정각 알림 - 풀스크린
  Future<void> scheduleFullscreenAlarm({
    required int id,
    required String medicationName,
    required MedicationType type,
    required DateTime scheduledTime,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: scheduledTime,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      notificationTitle: type.fullscreenTitle,
      notificationBody: medicationName,
      enableNotificationOnKill: true,
    );
    
    await Alarm.set(alarmSettings: alarmSettings);
  }
}
```

### 풀스크린 알람 화면
```dart
class FullscreenAlarmScreen extends StatelessWidget {
  final String medicationName;
  final MedicationType type;
  final DateTime scheduledTime;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.icon, style: TextStyle(fontSize: 80)),
            SizedBox(height: 24),
            Text(
              medicationName,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _formatTime(scheduledTime),
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            SizedBox(height: 48),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () => _onComplete(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9B7ED9),
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  type.completeButtonText,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => _onSnooze(context),
              child: Text(
                '조금 이따 알려줘',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _onComplete(BuildContext context) {
    Alarm.stop(alarmId);
    // 앱 메인 화면으로 이동 + 복용 체크
    Navigator.pushReplacementNamed(context, '/home', arguments: {
      'markComplete': true,
      'medicationId': medicationId,
    });
  }
  
  void _onSnooze(BuildContext context) {
    Alarm.stop(alarmId);
    // 5분 후 다시 알람 예약
    _scheduleReminder(DateTime.now().add(Duration(minutes: 5)));
    Navigator.pop(context);
  }
}
```

---

## 요약

| 항목 | 내용 |
|------|------|
| 미리 알림 | 푸시 (10분 전) |
| 정각 알림 | 풀스크린 (화면 덮음) |
| 리마인드 | 풀스크린 (5분 간격, 최대 3회) |
| 주사 버튼 | 맞았어요 |
| 알약 버튼 | 먹었어요 |
| 질정 버튼 | 완료했어요 |
| 패치 버튼 | 붙였어요 |
| 스누즈 버튼 | 조금 이따 알려줘 |
