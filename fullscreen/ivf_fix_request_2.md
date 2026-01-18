# IVF 앱 - 수정 요청 4가지

## 1. 이식 대기 단계 - "진행중" 뱃지 제거

### 현재 문제
- 이식 대기(Waiting) 단계에 "진행중" 뱃지가 표시됨
- 이식 대기는 그냥 기다리는 단계라 진행중 표시 불필요

### 수정 요청
- 이식 대기 단계에서는 "진행중" 뱃지 표시하지 않음
- 날짜 범위만 표시 (예: 2025.12.19 ~ 진행 중)

```
Before:
▶️ 이식 대기 (Waiting) [진행중]
   2025.12.19 ~ 진행 중

After:
📞 이식 대기 (Waiting)
   2025.12.19 ~ 진행 중
```

---

## 2. 홈 > 곧 만나요 - 현재 진행 단계 표시

### 현재 문제
- "곧 만나요"에 초음파 검사, 채취 예정일 등 고정된 내용 표시
- 실제 치료 단계와 연동 안 됨

### 수정 요청
- 치료 기록의 현재 진행 단계를 기반으로 동적 표시
- 다음 예정된 단계/일정 표시

### 로직
```dart
List<UpcomingEvent> getUpcomingEvents(TreatmentCycle cycle) {
  List<UpcomingEvent> events = [];
  
  // 현재 진행중인 단계의 다음 단계 찾기
  for (var stage in cycle.stages) {
    if (stage.status == StageStatus.pending && stage.date != null) {
      events.add(UpcomingEvent(
        title: stage.name,
        date: stage.date,
        dDay: calculateDDay(stage.date),
      ));
    }
  }
  
  return events;
}
```

### UI 예시
```
현재 단계: 과배란 진행중
→ 곧 만나요:
   🏥 채취 예정 D-3 (12/29)

현재 단계: 이식 대기
→ 곧 만나요:
   🎯 이식 예정 D-5 (1/2)

현재 단계: 이식 완료, 판정 대기
→ 곧 만나요:
   🩸 판정일 D-7 (1/10)
```

---

## 3. 날짜 선택 캘린더 - 현재 날짜 기준으로 시작

### 현재 문제
- 캘린더가 어떤 날짜부터 시작하는지 불명확
- 사용자가 스크롤해서 현재 날짜 찾아야 함

### 수정 요청
- 날짜 선택 캘린더 열릴 때 **현재 날짜 기준**으로 표시
- 현재 날짜가 화면 중앙 또는 상단에 보이도록

```dart
// 캘린더 초기화 시
initialDate: DateTime.now(),
firstDate: DateTime.now().subtract(Duration(days: 365)),
lastDate: DateTime.now().add(Duration(days: 365)),
```

---

## 4. 키보드 출력 시 화면 가림 방지

### 현재 문제
- 키보드가 올라오면 입력 필드가 가려짐
- 사용자가 입력 내용을 볼 수 없음

### 수정 요청
- 키보드 출력 시 화면 자동 스크롤
- 입력 필드가 키보드 위에 보이도록

### 해결 방법

**방법 1: Scaffold resizeToAvoidBottomInset**
```dart
Scaffold(
  resizeToAvoidBottomInset: true,  // 기본값 true
  body: ...
)
```

**방법 2: SingleChildScrollView 사용**
```dart
SingleChildScrollView(
  reverse: true,  // 키보드 올라올 때 아래서부터 스크롤
  child: Column(
    children: [
      // 입력 필드들
    ],
  ),
)
```

**방법 3: 바텀시트의 경우**
```dart
showModalBottomSheet(
  isScrollControlled: true,  // 필수!
  builder: (context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,  // 키보드 높이만큼 패딩
    ),
    child: ...
  ),
)
```

**방법 4: TextField에 focus 시 스크롤**
```dart
FocusNode _focusNode = FocusNode();

TextField(
  focusNode: _focusNode,
)

// focus 시 해당 위치로 스크롤
_focusNode.addListener(() {
  if (_focusNode.hasFocus) {
    Scrollable.ensureVisible(
      context,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
});
```
