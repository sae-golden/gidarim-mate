# IVF 약물 알림 앱 개발 가이드

**Flutter 기반 크로스 플랫폼 앱 개발 완벽 가이드**

---

## 📚 목차

1. [개발 환경 설정](#개발-환경-설정)
2. [프로젝트 구조](#프로젝트-구조)
3. [디자인 시스템 활용](#디자인-시스템-활용)
4. [화면별 구현 가이드](#화면별-구현-가이드)
5. [데이터 모델](#데이터-모델)
6. [상태 관리](#상태-관리)
7. [알림 구현](#알림-구현)
8. [테스트](#테스트)
9. [배포](#배포)

---

## 개발 환경 설정

### 1. Flutter 설치

#### macOS
```bash
# Homebrew로 설치
brew install --cask flutter

# PATH 설정
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

#### Windows
1. [Flutter 공식 사이트](https://flutter.dev)에서 SDK 다운로드
2. 압축 해제 후 PATH 환경 변수에 추가
3. `flutter doctor` 실행하여 설정 확인

#### Linux
```bash
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
export PATH="$PATH:$HOME/flutter/bin"
```

### 2. 개발 도구 설치

#### Android Studio
1. [Android Studio](https://developer.android.com/studio) 다운로드 및 설치
2. Flutter 플러그인 설치
3. Android SDK 설치

#### VS Code (추천)
1. [VS Code](https://code.visualstudio.com/) 다운로드 및 설치
2. Flutter 확장 프로그램 설치
3. Dart 확장 프로그램 설치

### 3. 프로젝트 생성

```bash
# 프로젝트 생성
flutter create --project-name ivf_medication_app --org com.ivfapp ivf_medication_app

# 프로젝트 디렉토리로 이동
cd ivf_medication_app

# 패키지 설치
flutter pub get

# 실행
flutter run
```

---

## 프로젝트 구조

```
ivf_medication_app/
├── lib/
│   ├── main.dart                 # 앱 진입점
│   ├── constants/                # 상수 (색상, 텍스트 스타일, 간격)
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_spacing.dart
│   ├── models/                   # 데이터 모델
│   │   ├── medication.dart
│   │   └── treatment_stage.dart
│   ├── screens/                  # 화면
│   │   ├── home_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── medication_input_screen.dart
│   │   ├── injection_location_screen.dart
│   │   ├── calendar_screen.dart
│   │   └── treatment_record_screen.dart
│   ├── widgets/                  # 공통 위젯
│   │   ├── app_button.dart
│   │   ├── app_card.dart
│   │   └── medication_item.dart
│   ├── providers/                # 상태 관리 (Provider)
│   │   ├── medication_provider.dart
│   │   └── treatment_provider.dart
│   └── utils/                    # 유틸리티
│       ├── notification_service.dart
│       └── database_helper.dart
├── pubspec.yaml                  # 패키지 설정
└── assets/                       # 이미지, 폰트 등
    ├── images/
    └── fonts/
```

---

## 디자인 시스템 활용

### 색상 사용

```dart
import 'package:ivf_medication_app/constants/app_colors.dart';

// 메인 컬러
Container(
  color: AppColors.primaryPurple,
)

// 그라데이션
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

### 텍스트 스타일 사용

```dart
import 'package:ivf_medication_app/constants/app_text_styles.dart';

Text(
  '제목',
  style: AppTextStyles.h1,
)

Text(
  '본문',
  style: AppTextStyles.body,
)
```

### 간격 사용

```dart
import 'package:ivf_medication_app/constants/app_spacing.dart';

Padding(
  padding: EdgeInsets.all(AppSpacing.m),
  child: ...
)

SizedBox(height: AppSpacing.l)
```

### 공통 위젯 사용

```dart
// 버튼
AppButton(
  text: '확인',
  onPressed: () {
    // 버튼 클릭 시 동작
  },
  type: AppButtonType.primary,
)

// 카드
AppCard(
  child: Text('카드 내용'),
  showAccent: true, // 왼쪽 액센트 바 표시
)
```

---

## 화면별 구현 가이드

### 1. 온보딩 화면 (약물 입력 방식 선택)

```dart
class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.m),
          child: Column(
            children: [
              Text('약물 일정을 입력해주세요', style: AppTextStyles.h1),
              SizedBox(height: AppSpacing.l),
              
              // 입력 방식 선택 버튼들
              _buildInputMethodButton(
                icon: Icons.camera_alt,
                title: '처방전 사진 찍기',
                subtitle: '가장 빠른 방법',
                onTap: () => _navigateToOCR(context),
              ),
              
              _buildInputMethodButton(
                icon: Icons.mic,
                title: '음성으로 말하기',
                subtitle: '편하게 말로 입력',
                onTap: () => _navigateToVoice(context),
              ),
              
              // ... 나머지 버튼들
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. 약물 입력 화면 (캘린더 기반)

```dart
class MedicationInputScreen extends StatefulWidget {
  @override
  _MedicationInputScreenState createState() => _MedicationInputScreenState();
}

class _MedicationInputScreenState extends State<MedicationInputScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String medicationName = '';
  String time = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('약물 추가')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            // 약물명 입력
            TextField(
              decoration: InputDecoration(labelText: '약물명'),
              onChanged: (value) => setState(() => medicationName = value),
            ),
            
            // 시간 선택
            TextField(
              decoration: InputDecoration(labelText: '시간 (예: 매일 아침 8:00)'),
              onChanged: (value) => setState(() => time = value),
            ),
            
            // 시작일 선택
            AppButton(
              text: startDate == null 
                ? '시작일 선택' 
                : '시작일: ${_formatDate(startDate!)}',
              onPressed: () => _selectStartDate(context),
            ),
            
            // 종료일 선택
            AppButton(
              text: endDate == null 
                ? '종료일 선택' 
                : '종료일: ${_formatDate(endDate!)}',
              onPressed: () => _selectEndDate(context),
            ),
            
            // 저장 버튼
            AppButton(
              text: '저장',
              onPressed: _saveMedication,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }
  
  void _saveMedication() {
    // Provider를 통해 약물 저장
    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: medicationName,
      time: time,
      startDate: startDate!,
      endDate: endDate!,
      type: MedicationType.injection,
      totalCount: _calculateTotalCount(),
    );
    
    Provider.of<MedicationProvider>(context, listen: false)
        .addMedication(medication);
    
    Navigator.pop(context);
  }
}
```

### 3. 주사 부위 입력 화면

```dart
class InjectionLocationScreen extends StatefulWidget {
  final String medicationId;
  
  const InjectionLocationScreen({required this.medicationId});
  
  @override
  _InjectionLocationScreenState createState() => 
      _InjectionLocationScreenState();
}

class _InjectionLocationScreenState extends State<InjectionLocationScreen> {
  String? selectedLocation;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('주사 위치 선택')),
      body: Column(
        children: [
          Text('어디에 주사를 맞으셨나요?', style: AppTextStyles.h2),
          SizedBox(height: AppSpacing.l),
          
          // 복부 그림 (9개 구역)
          _buildAbdomenGrid(),
          
          SizedBox(height: AppSpacing.l),
          
          // 완료 버튼
          AppButton(
            text: '완료',
            onPressed: selectedLocation != null ? _saveLocation : null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAbdomenGrid() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final location = _getLocationName(index);
        final isSelected = selectedLocation == location;
        
        return GestureDetector(
          onTap: () => setState(() => selectedLocation = location),
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected 
                ? AppColors.primaryPurple 
                : AppColors.cardBackground,
              border: Border.all(
                color: AppColors.primaryPurple,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                location,
                style: AppTextStyles.body.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _getLocationName(int index) {
    const locations = [
      '왼쪽 위', '중앙 위', '오른쪽 위',
      '왼쪽 중', '배꼽', '오른쪽 중',
      '왼쪽 아래', '중앙 아래', '오른쪽 아래',
    ];
    return locations[index];
  }
  
  void _saveLocation() {
    // 로그 저장
    final log = MedicationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      medicationId: widget.medicationId,
      scheduledTime: DateTime.now(),
      completedTime: DateTime.now(),
      isCompleted: true,
      injectionLocation: selectedLocation,
    );
    
    Provider.of<MedicationProvider>(context, listen: false).addLog(log);
    
    // 다음 추천 위치 계산 및 알림
    _showNextLocationRecommendation();
    
    Navigator.pop(context);
  }
}
```

---

## 데이터 모델

### Medication (약물)

```dart
class Medication {
  final String id;
  final String name;
  final String? dosage;
  final String time;
  final DateTime startDate;
  final DateTime endDate;
  final MedicationType type;
  final int totalCount;
  
  // JSON 변환
  Map<String, dynamic> toJson() { ... }
  factory Medication.fromJson(Map<String, dynamic> json) { ... }
}
```

### MedicationLog (복용 기록)

```dart
class MedicationLog {
  final String id;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? completedTime;
  final bool isCompleted;
  final String? injectionLocation;
  
  // JSON 변환
  Map<String, dynamic> toJson() { ... }
  factory MedicationLog.fromJson(Map<String, dynamic> json) { ... }
}
```

---

## 상태 관리

### Provider 사용

```dart
// providers/medication_provider.dart
class MedicationProvider with ChangeNotifier {
  List<Medication> _medications = [];
  List<MedicationLog> _logs = [];
  
  List<Medication> get medications => _medications;
  List<MedicationLog> get logs => _logs;
  
  void addMedication(Medication medication) {
    _medications.add(medication);
    notifyListeners();
  }
  
  void addLog(MedicationLog log) {
    _logs.add(log);
    notifyListeners();
  }
  
  List<MedicationLog> getTodayLogs() {
    final today = DateTime.now();
    return _logs.where((log) {
      return log.scheduledTime.year == today.year &&
             log.scheduledTime.month == today.month &&
             log.scheduledTime.day == today.day;
    }).toList();
  }
}
```

### main.dart에서 Provider 설정

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => TreatmentProvider()),
      ],
      child: IVFMedicationApp(),
    ),
  );
}
```

---

## 알림 구현

### flutter_local_notifications 설정

```dart
// utils/notification_service.dart
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }
  
  static Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          '약물 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
```

---

## 테스트

### 단위 테스트

```dart
// test/models/medication_test.dart
void main() {
  group('Medication', () {
    test('toJson and fromJson', () {
      final medication = Medication(
        id: '1',
        name: 'FSH 주사',
        time: '매일 아침 8:00',
        startDate: DateTime(2025, 1, 5),
        endDate: DateTime(2025, 1, 14),
        type: MedicationType.injection,
        totalCount: 10,
      );
      
      final json = medication.toJson();
      final decoded = Medication.fromJson(json);
      
      expect(decoded.name, medication.name);
      expect(decoded.totalCount, medication.totalCount);
    });
  });
}
```

---

## 배포

### Android

```bash
# 릴리스 빌드
flutter build apk --release

# APK 위치
build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
# 릴리스 빌드
flutter build ios --release

# Xcode에서 Archive 후 App Store Connect에 업로드
```

---

## 📝 다음 단계

1. **데이터베이스 연동**: sqflite로 로컬 저장
2. **알림 스케줄링**: 모든 약물에 대한 알림 자동 설정
3. **OCR 구현**: Google ML Kit 연동
4. **음성 인식**: speech_to_text 패키지 사용
5. **백엔드 연동**: Firebase 또는 Supabase

---

**Happy Coding! 🚀**
