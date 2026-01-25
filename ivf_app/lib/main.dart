import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_screen.dart';
import 'constants/app_colors.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler_service.dart';
import 'services/home_widget_service.dart';
import 'services/medication_storage_service.dart';
import 'services/injection_site_service.dart';
import 'models/medication.dart';
import 'widgets/injection_site_bottom_sheet.dart';
import 'widgets/completion_overlay.dart';

/// 전역 NavigatorKey (알림 액션 처리용)
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
            // 알림 탭 (앱 열기만)
            debugPrint('📱 알림 탭으로 앱 열림');
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
    // 주사인 경우 부위 선택 바텀시트 표시
    if (medicationType == MedicationType.injection) {
      await _showInjectionSiteBottomSheet(medicationId, medicationName);
    } else {
      // 경구/비강/패치 등은 바로 완료 처리
      await MedicationStorageService.markMedicationCompleted(
        medicationId: medicationId,
        date: DateTime.now(),
        scheduledCount: 1,
      );

      // 컨페티 표시
      final context = navigatorKey.currentContext;
      if (context != null && mounted) {
        CompletionOverlay.show(
          context,
          medicationName: medicationName,
          isInjection: false,
        );
      }

      debugPrint('✅ 복용 완료: $medicationName');
    }
  }

  /// 스누즈 처리 (5분 후 1회)
  Future<void> _handleSnooze({
    required String medicationId,
    required String medicationName,
    required MedicationType medicationType,
    String? dosage,
  }) async {
    final notificationId = medicationId.hashCode.abs() % 100000;

    await NotificationService.scheduleSnoozeNotification(
      originalId: notificationId,
      medicationId: medicationId,
      medicationName: medicationName,
      type: medicationType,
      dosage: dosage,
    );

    debugPrint('⏰ 스누즈 예약: $medicationName (5분 후)');
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

      // 모달 닫힘 후 약간의 딜레이 후 컨페티 표시
      await Future.delayed(const Duration(milliseconds: 100));

      // 컨페티 표시 (context 재확인)
      final confettiContext = navigatorKey.currentContext;
      if (confettiContext != null && mounted) {
        CompletionOverlay.show(
          confettiContext,
          medicationName: medicationName,
          isInjection: true,
        );
      }
    }
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
