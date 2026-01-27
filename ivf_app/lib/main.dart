import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_screen.dart';
import 'constants/app_colors.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler_service.dart';
import 'services/home_widget_service.dart';
import 'services/medication_storage_service.dart';
import 'services/injection_site_service.dart';
import 'services/analytics_service.dart';
import 'models/medication.dart';
import 'widgets/injection_site_bottom_sheet.dart';
import 'widgets/completion_overlay.dart';

/// 전역 NavigatorKey (알림 액션 처리용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    // GA4 초기화
    await AnalyticsService.initialize();
    debugPrint('🔥 Firebase 초기화 완료');
  } catch (e) {
    debugPrint('Firebase 초기화 실패: $e');
  }

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

  // 알림 서비스 초기화 (웹 제외)
  if (!kIsWeb) {
    try {
      await NotificationSchedulerService.initialize();
      // 알림 권한 요청
      await NotificationService.requestPermission();
      // 오늘 약물 알림 스케줄링
      await NotificationSchedulerService.scheduleAllMedications();
    } catch (e) {
      debugPrint('알림 서비스 초기화 실패: $e');
    }
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
  @override
  void initState() {
    super.initState();
    _setupNotificationActionHandler();
    _processPendingActions();
  }

  @override
  void dispose() {
    NotificationService.onActionReceived = null;
    super.dispose();
  }

  /// 알림 액션 핸들러 설정
  void _setupNotificationActionHandler() {
    if (kIsWeb) return;

    NotificationService.onActionReceived = (actionId, payload) async {
      debugPrint('🔔 알림 액션 수신: actionId=$actionId');

      if (payload == null) return;

      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final medicationId = data['medicationId'] as String? ?? '';
        final medicationName = data['medicationName'] as String? ?? '';
        final typeStr = data['type'] as String? ?? 'oral';
        final dosage = data['dosage'] as String?;

        final medicationType = MedicationType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => MedicationType.oral,
        );

        switch (actionId) {
          case NotificationActions.complete:
            // 복용 완료 버튼
            await _handleComplete(
              medicationId: medicationId,
              medicationName: medicationName,
              medicationType: medicationType,
            );
            break;

          case NotificationActions.snooze:
            // 나중에 버튼 (5분 후 1회)
            await _handleSnooze(
              medicationId: medicationId,
              medicationName: medicationName,
              medicationType: medicationType,
              dosage: dosage,
            );
            break;

          case 'TAP':
          default:
            // 알림 탭 또는 앱 완전 종료 상태에서 버튼 클릭
            // (cold start 시 actionId가 null/TAP으로 올 수 있음)
            debugPrint('📱 알림 탭/버튼으로 앱 열림 - 복용 완료 처리');
            await _handleComplete(
              medicationId: medicationId,
              medicationName: medicationName,
              medicationType: medicationType,
            );
            break;
        }
      } catch (e) {
        debugPrint('❌ 알림 액션 처리 오류: $e');
      }
    };

    debugPrint('✅ 알림 액션 핸들러 설정 완료');
  }

  /// 펜딩 액션 처리 (백그라운드에서 온 액션)
  Future<void> _processPendingActions() async {
    if (kIsWeb) return;

    await NotificationService.processPendingAction();
  }

  /// 복용 완료 처리
  Future<void> _handleComplete({
    required String medicationId,
    required String medicationName,
    required MedicationType medicationType,
  }) async {
    // 재알림 취소 (복용 완료했으니 5분 후 재알림 필요 없음)
    final notificationId = medicationId.hashCode.abs() % 100000;
    await NotificationService.cancelSnoozeNotification(notificationId);

    // 주사인 경우 부위 선택 바텀시트 표시
    if (medicationType == MedicationType.injection) {
      await _showInjectionSiteBottomSheet(medicationId, medicationName);
    } else {
      // 경구/비강/패치 등은 바로 완료 처리
      try {
        await MedicationStorageService.markMedicationCompleted(
          medicationId: medicationId,
          date: DateTime.now(),
          scheduledCount: 1,
        );
        debugPrint('✅ 복용 완료: $medicationName');
      } catch (e) {
        debugPrint('❌ 복용 완료 저장 오류: $e');
        // 오류가 발생해도 컨페티는 표시 (사용자 경험 우선)
      }

      // 컨페티 표시 (재시도 포함)
      _showConfettiWithRetry(medicationName, false);
    }
  }

  /// 스누즈 처리 (나중에 버튼)
  /// - 정각 알림 예약 시 이미 5분 후 재알림이 자동 예약되어 있음
  /// - "나중에" 버튼은 단순히 알림 닫기만 하면 됨 (재알림은 이미 예약됨)
  Future<void> _handleSnooze({
    required String medicationId,
    required String medicationName,
    required MedicationType medicationType,
    String? dosage,
  }) async {
    // 재알림은 이미 자동 예약되어 있으므로 추가 작업 불필요
    debugPrint('⏰ 나중에 선택: $medicationName (5분 후 재알림 예정)');
  }

  /// 주사 부위 선택 바텀시트 표시
  Future<void> _showInjectionSiteBottomSheet(
    String medicationId,
    String medicationName,
  ) async {
    // 마지막 주사 부위 조회
    final lastSide = await InjectionSiteService.getLastSite();

    // 앱이 포그라운드로 올라올 때까지 대기 (최대 2초)
    BuildContext? context;
    for (var i = 0; i < 20; i++) {
      context = navigatorKey.currentContext;
      if (context != null && mounted) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (context == null || !mounted) {
      debugPrint('❌ 바텀시트 표시 실패: 컨텍스트 없음');
      return;
    }

    // 바텀시트 표시
    final selectedSide = await InjectionSiteBottomSheet.show(
      context,
      medicationName: medicationName,
      lastSide: lastSide,
    );

    if (selectedSide != null) {
      try {
        // 주사 부위 저장
        await InjectionSiteService.saveSite(selectedSide);

        // 복용 완료 처리
        await MedicationStorageService.markMedicationCompleted(
          medicationId: medicationId,
          date: DateTime.now(),
          scheduledCount: 1,
        );

        debugPrint('💉 주사 완료: $medicationName ($selectedSide)');
      } catch (e) {
        debugPrint('❌ 주사 완료 저장 오류: $e');
        // 오류가 발생해도 컨페티는 표시 (사용자 경험 우선)
      }

      // 프레임 렌더링 완료 후 컨페티 표시 (바텀시트 닫힘 보장)
      _showConfettiWithRetry(medicationName, true);
    }
  }

  /// 컨페티 표시 (컨텍스트 없거나 Overlay 없으면 재시도)
  void _showConfettiWithRetry(String medicationName, bool isInjection, [int retryCount = 0]) {
    if (retryCount > 20) {
      debugPrint('❌ 컨페티 표시 포기: 최대 재시도 초과');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Navigator의 overlay를 직접 사용
      final navigatorState = navigatorKey.currentState;
      if (navigatorState != null && mounted) {
        final overlay = navigatorState.overlay;
        if (overlay != null) {
          debugPrint('🎉 컨페티 표시 시도: $medicationName (시도 ${retryCount + 1})');
          final success = CompletionOverlay.showWithOverlay(
            overlay,
            medicationName: medicationName,
            isInjection: isInjection,
          );
          if (success) {
            debugPrint('✅ 컨페티 표시 성공');
            return;
          }
        }
      }
      // 실패 시 200ms 후 재시도
      debugPrint('⏳ Overlay 미준비, 재시도 예정 (시도 ${retryCount + 1})');
      await Future.delayed(const Duration(milliseconds: 200));
      _showConfettiWithRetry(medicationName, isInjection, retryCount + 1);
    });
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
      home: const MainScreen(),
    );
  }
}
