import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alarm/alarm.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/fullscreen_alarm_screen.dart';
import 'constants/app_colors.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler_service.dart';
import 'services/sync_service.dart';
import 'services/home_widget_service.dart';
import 'services/medication_storage_service.dart';
import 'services/cloud_storage_service.dart';
import 'services/injection_site_service.dart';
import 'models/medication.dart';
import 'widgets/injection_site_bottom_sheet.dart';

/// Supabase 초기화 성공 여부
bool _supabaseInitialized = false;

/// 전역 NavigatorKey (알람 화면 표시용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상단바(Status bar) 아이콘 색상을 어둡게 설정 (밝은 배경에서 보이도록)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android: 어두운 아이콘
    statusBarBrightness: Brightness.light, // iOS: 밝은 배경 = 어두운 아이콘
  ));

  // 로컬 중복 약물 정리 (앱 시작 시)
  try {
    final removedCount = await MedicationStorageService.removeDuplicateMedications();
    if (removedCount > 0) {
      debugPrint('🧹 앱 시작 시 $removedCount개 중복 약물 정리됨');
    }
  } catch (e) {
    debugPrint('중복 정리 실패: $e');
  }

  // Supabase 초기화
  try {
    await SupabaseService.initialize();
    _supabaseInitialized = true;
  } catch (e) {
    debugPrint('Supabase 초기화 실패: $e');
    // 초기화 실패해도 앱은 계속 실행 (오프라인 모드)
  }

  // 알림 서비스 초기화 (웹 제외)
  if (!kIsWeb) {
    try {
      await NotificationSchedulerService.initialize();
      // 기본 알림 권한만 요청 (SYSTEM_ALERT_WINDOW는 나중에 필요할 때 요청)
      await NotificationService.requestBasicPermission();
      // 오늘 약물 알림 스케줄링
      await NotificationSchedulerService.scheduleAllMedications();
    } catch (e) {
      debugPrint('알림 서비스 초기화 실패: $e');
    }
  }

  // 동기화 서비스 초기화
  try {
    await SyncService.initialize();
    // 로그인 상태면 초기 동기화 시도 (백그라운드에서)
    if (_supabaseInitialized && SupabaseService.isLoggedIn) {
      // 1. 먼저 클라우드 중복 정리
      CloudStorageService.removeDuplicateMedications().then((cloudRemoved) {
        if (cloudRemoved > 0) {
          debugPrint('🧹 클라우드 중복 $cloudRemoved개 정리됨');
        }
      }).catchError((e) {
        debugPrint('클라우드 중복 정리 오류: $e');
      });

      // 2. 동기화 후 로컬 중복 정리
      SyncService.syncAll().then((_) async {
        final removedCount = await MedicationStorageService.removeDuplicateMedications();
        if (removedCount > 0) {
          debugPrint('🧹 동기화 후 로컬 $removedCount개 중복 약물 정리됨');
        }
      }).catchError((e) {
        debugPrint('백그라운드 동기화 오류: $e');
      });
    }
  } catch (e) {
    debugPrint('동기화 서비스 초기화 실패: $e');
  }

  // 홈 위젯 초기화 및 업데이트 (Android/iOS만)
  if (!kIsWeb) {
    try {
      await HomeWidgetService.initialize();
      await HomeWidgetService.updateWidget();
    } catch (e) {
      debugPrint('홈 위젯 초기화 실패: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: IVFApp(),
    ),
  );
}

class IVFApp extends StatefulWidget {
  const IVFApp({super.key});

  @override
  State<IVFApp> createState() => _IVFAppState();
}

class _IVFAppState extends State<IVFApp> {
  /// 알람 스트림 구독 (dispose에서 해제 필요)
  StreamSubscription<AlarmSettings>? _alarmSubscription;

  @override
  void initState() {
    super.initState();
    _setupAlarmListener();
  }

  @override
  void dispose() {
    // 스트림 구독 해제
    _alarmSubscription?.cancel();
    // 콜백 정리
    NotificationService.onInjectionComplete = null;
    super.dispose();
  }

  /// 알람 리스너 설정
  void _setupAlarmListener() {
    if (kIsWeb) return;

    debugPrint('🎯 [ALARM] _setupAlarmListener 호출됨');

    // 주사 완료 콜백 설정 (푸시에서 "맞았어요" 탭 시)
    NotificationService.onInjectionComplete = (medicationId, medicationName) {
      _showInjectionSiteBottomSheet(medicationId, medicationName);
    };

    // 알림 액션 콜백 설정 (알림 탭 시 풀스크린 화면으로 이동)
    NotificationService.onActionReceived = (actionId, payload) {
      if (actionId == 'navigate_to_alarm' && payload != null) {
        _navigateToFullscreenFromNotification(payload);
      }
    };

    // 알람 울릴 때 호출 (구독을 필드에 저장하여 dispose에서 해제)
    _alarmSubscription = Alarm.ringStream.stream.listen((alarmSettings) async {
      debugPrint('🔔 [ALARM] ringStream 이벤트 수신! id=${alarmSettings.id}');
      debugPrint('🔔 [ALARM] alarmSettings: dateTime=${alarmSettings.dateTime}');

      // 알람 데이터 조회
      final alarmData = await NotificationService.getAlarmData(alarmSettings.id);
      debugPrint('🔔 [ALARM] alarmData 조회 결과: $alarmData');

      if (alarmData == null) {
        debugPrint('❌ [ALARM] 알람 데이터 없음: ${alarmSettings.id}');
        debugPrint('❌ [ALARM] SharedPreferences key: alarm_data_${alarmSettings.id}');
        return;
      }

      final medicationId = alarmData['medicationId'] as String? ?? '';
      final medicationName = alarmData['medicationName'] as String? ?? '';
      final dosage = alarmData['dosage'] as String?;
      final typeStr = alarmData['type'] as String? ?? 'oral';
      final scheduledTimeStr = alarmData['scheduledTime'] as String?;
      final reminderCount = alarmData['reminderCount'] as int? ?? 0;

      debugPrint('🔔 [ALARM] 파싱된 데이터: id=$medicationId, name=$medicationName, type=$typeStr, reminder=$reminderCount');

      final medicationType = MedicationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => MedicationType.oral,
      );

      // 시간 포맷팅
      String scheduledTime = '';
      if (scheduledTimeStr != null) {
        final dt = DateTime.tryParse(scheduledTimeStr);
        if (dt != null) {
          final hour = dt.hour;
          final minute = dt.minute.toString().padLeft(2, '0');
          if (hour < 12) {
            scheduledTime = '오전 ${hour == 0 ? 12 : hour}:$minute';
          } else {
            scheduledTime = '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
          }
        }
      }

      // Navigator 상태 확인
      final navState = navigatorKey.currentState;
      debugPrint('🔔 [ALARM] navigatorKey.currentState: $navState');

      if (navState == null) {
        debugPrint('❌ [ALARM] Navigator가 null! 화면을 표시할 수 없음');
        return;
      }

      // 풀스크린 알람 화면 표시
      debugPrint('🔔 [ALARM] FullscreenAlarmScreen으로 네비게이션 시도...');
      navState.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) {
            debugPrint('🔔 [ALARM] FullscreenAlarmScreen builder 호출됨!');
            return FullscreenAlarmScreen(
              alarmSettings: alarmSettings,
              medicationId: medicationId,
              medicationName: medicationName,
              dosage: dosage,
              medicationType: medicationType,
              scheduledTime: scheduledTime,
              reminderCount: reminderCount,
            );
          },
        ),
      );
      debugPrint('🔔 [ALARM] Navigator.push 완료');
    });

    debugPrint('🎯 [ALARM] ringStream 구독 완료');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '기다림메이트',
      debugShowCheckedModeBanner: false,
      // 한국어 로컬라이제이션 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      home: _getInitialScreen(),
    );
  }

  /// 초기 화면 결정
  /// 1. Supabase 초기화 성공 + 로그인 안됨 → 인증 화면
  /// 2. Supabase 초기화 성공 + 로그인됨 → 메인 화면
  /// 3. Supabase 초기화 실패 → 메인 화면 (오프라인 모드)
  Widget _getInitialScreen() {
    if (_supabaseInitialized && !SupabaseService.isLoggedIn) {
      return const AuthScreen();
    }
    return const MainScreen();
  }

  /// 알림 탭 시 풀스크린 화면으로 이동
  Future<void> _navigateToFullscreenFromNotification(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final medicationId = data['medicationId'] as String? ?? '';
      final medicationName = data['medicationName'] as String? ?? '';
      final dosage = data['dosage'] as String?;
      final typeStr = data['type'] as String? ?? 'oral';
      final scheduledTimeStr = data['scheduledTime'] as String?;
      final reminderCount = data['reminderCount'] as int? ?? 0;
      final notificationId = data['notificationId'] as int?;

      final medicationType = MedicationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => MedicationType.oral,
      );

      // 시간 포맷팅
      String scheduledTime = '';
      if (scheduledTimeStr != null) {
        final dt = DateTime.tryParse(scheduledTimeStr);
        if (dt != null) {
          final hour = dt.hour;
          final minute = dt.minute.toString().padLeft(2, '0');
          if (hour < 12) {
            scheduledTime = '오전 ${hour == 0 ? 12 : hour}:$minute';
          } else {
            scheduledTime = '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
          }
        }
      }

      // 더미 AlarmSettings 생성 (알림에서 온 경우)
      final dummyAlarmSettings = AlarmSettings(
        id: notificationId ?? 0,
        dateTime: DateTime.now(),
        assetAudioPath: 'packages/alarm/assets/not_blank.mp3',
        notificationSettings: const NotificationSettings(
          title: '',
          body: '',
        ),
      );

      final navState = navigatorKey.currentState;
      if (navState != null) {
        navState.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => FullscreenAlarmScreen(
              alarmSettings: dummyAlarmSettings,
              medicationId: medicationId,
              medicationName: medicationName,
              dosage: dosage,
              medicationType: medicationType,
              scheduledTime: scheduledTime,
              reminderCount: reminderCount,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 풀스크린 화면 이동 오류: $e');
    }
  }

  /// 주사 부위 선택 바텀시트 표시
  Future<void> _showInjectionSiteBottomSheet(
    String medicationId,
    String medicationName,
  ) async {
    // 마지막 주사 부위 조회
    final lastSide = await InjectionSiteService.getLastSite();

    // async 작업 후 context 유효성 재확인
    final context = navigatorKey.currentContext;
    if (context == null || !mounted) return;

    // 바텀시트 표시
    final selectedSide = await InjectionSiteBottomSheet.show(
      context,
      medicationName: medicationName,
      lastSide: lastSide,
    );

    if (selectedSide != null) {
      // 주사 부위 저장
      await InjectionSiteService.saveSite(selectedSide);

      // 복용 완료 처리
      await MedicationStorageService.markMedicationCompleted(
        medicationId: medicationId,
        date: DateTime.now(),
        scheduledCount: 1,
      );

      debugPrint('💉 주사 완료: $medicationName ($selectedSide)');
    }
  }
}
