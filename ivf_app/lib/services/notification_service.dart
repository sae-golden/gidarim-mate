import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/medication.dart';
import 'medication_storage_service.dart';

/// 백그라운드 알림 응답 처리 (top-level 함수 - 필수!)
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔔 백그라운드 알림 응답: actionId=${response.actionId}, payload=${response.payload}');

  final actionId = response.actionId;
  final payload = response.payload;

  if (actionId != null && actionId.isNotEmpty) {
    NotificationService._handleBackgroundAction(actionId, payload);
  }
}

/// 알림 액션 ID
class NotificationActions {
  static const String complete = 'complete'; // 완료 (맞았어요/먹었어요 등)
  static const String dismiss = 'dismiss';   // 알겠어요 (푸시 닫기)
  static const String snooze = 'snooze';     // 다시 울림 (5분 후 재알림)
  static const String skip = 'skip';         // 건너뛰기 (기록 안 함)
}

/// 알림 액션 콜백 타입
typedef NotificationActionCallback = void Function(String actionId, String? payload);

/// 알림 서비스 (푸시 + 풀스크린 알람 통합)
///
/// 알림 플로우:
/// 1. 10분 전: 📱 푸시 알림 (미리 알림)
/// 2. 정각: 📞 풀스크린 알람 (화면 켜짐 + 소리/진동)
/// 3. 미응답 시: 5분 간격으로 최대 3회 리마인드 (풀스크린)
class NotificationService {
  /// 싱글톤 인스턴스
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _nativeChannel = MethodChannel('com.ivfmate.app/alarm');

  static bool _initialized = false;
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _alarmDataKey = 'alarm_data_';
  static const String _reminderCountKey = 'reminder_count_';

  /// 리마인드 설정
  static const int _reminderIntervalMinutes = 5; // 리마인드 간격
  static const int _maxReminderCount = 3;        // 최대 리마인드 횟수

  /// 액션 콜백 (외부에서 설정)
  static NotificationActionCallback? onActionReceived;

  /// 주사 부위 선택 콜백 (주사 완료 시 호출)
  static void Function(String medicationId, String medicationName)? onInjectionComplete;

  // ============================================
  // 초기화
  // ============================================

  /// 알림 서비스 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    // 타임존 초기화
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정 - 약물 타입별 카테고리
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: _buildIOSCategories(),
    );

    const macSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );

    // Android 알림 채널 생성 (Importance.max로 설정)
    await _createNotificationChannels();

    // Alarm 패키지 초기화
    await Alarm.init();

    _initialized = true;
    debugPrint('✅ NotificationService 초기화 완료');
  }

  /// Android 알림 채널 생성
  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // 약물 알람 채널 (최고 중요도 - 풀스크린)
    const medicationAlarmChannel = AndroidNotificationChannel(
      'medication_alarm',
      '약물 알람',
      description: '약물 복용 시간 알람 (전체 화면)',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    // 미리 알림 채널 (높은 중요도)
    const preNotificationChannel = AndroidNotificationChannel(
      'pre_notification_channel',
      '미리 알림',
      description: '복용 시간 10분 전 알림',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(medicationAlarmChannel);
    await androidPlugin.createNotificationChannel(preNotificationChannel);

    debugPrint('📢 알림 채널 생성 완료');
  }

  /// iOS 카테고리 빌드 (약물 타입별)
  static List<DarwinNotificationCategory> _buildIOSCategories() {
    return MedicationType.values.map((type) {
      return DarwinNotificationCategory(
        'pre_${type.name}',
        actions: [
          DarwinNotificationAction.plain(
            NotificationActions.snooze,
            '다시 울림',
          ),
          DarwinNotificationAction.plain(
            NotificationActions.skip,
            '건너뛰기',
          ),
          DarwinNotificationAction.plain(
            NotificationActions.complete,
            type.completeButtonText,
          ),
        ],
      );
    }).toList();
  }

  // ============================================
  // 알림 응답 처리
  // ============================================

  /// 알림 응답 처리 (탭 또는 액션)
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 알림 응답: actionId=${response.actionId}, payload=${response.payload}');

    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && actionId.isNotEmpty) {
      _handleAction(actionId, payload);
    } else {
      // 알림 본체 탭 시 - 풀스크린 화면으로 이동
      if (payload != null) {
        _navigateToFullscreenAlarm(payload);
      } else {
        debugPrint('📱 알림 탭됨 - 앱 열기');
      }
    }
  }

  /// 풀스크린 알람 화면으로 이동
  static void _navigateToFullscreenAlarm(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final medicationName = data['medicationName'] as String? ?? '약물';
      final typeStr = data['type'] as String? ?? 'oral';
      final dosage = data['dosage'] as String?;
      final medicationId = data['medicationId'] as String?;
      final notificationId = data['notificationId'] as int?;
      final reminderCount = data['reminderCount'] as int? ?? 0;

      final type = MedicationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => MedicationType.oral,
      );

      debugPrint('🔔 풀스크린 화면으로 이동: $medicationName');

      // 여기서는 navigation을 직접 할 수 없으므로
      // 콜백을 통해 main.dart에서 처리하도록 함
      onActionReceived?.call('navigate_to_alarm', payload);
    } catch (e) {
      debugPrint('❌ 풀스크린 화면 이동 오류: $e');
    }
  }

  /// 백그라운드 액션 처리
  static Future<void> _handleBackgroundAction(String actionId, String? payload) async {
    debugPrint('🔔 백그라운드 액션 처리: $actionId');

    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      switch (actionId) {
        case NotificationActions.complete:
          await _handleComplete(data);
          break;
        case NotificationActions.snooze:
          await _handleSnooze(data);
          break;
        case NotificationActions.skip:
          debugPrint('⏭️ 건너뛰기 선택됨 - 기록 안 함');
          break;
        case NotificationActions.dismiss:
          debugPrint('📱 알겠어요 선택됨');
          break;
      }
    } catch (e) {
      debugPrint('❌ 백그라운드 액션 처리 오류: $e');
    }
  }

  /// 액션 처리
  static Future<void> _handleAction(String actionId, String? payload) async {
    debugPrint('🔔 액션 처리: $actionId');

    onActionReceived?.call(actionId, payload);

    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final medicationId = data['medicationId'] as String?;
      final medicationName = data['medicationName'] as String?;
      final typeStr = data['type'] as String?;
      final isInjection = typeStr == 'injection';

      switch (actionId) {
        case NotificationActions.complete:
          if (isInjection && medicationId != null && medicationName != null) {
            onInjectionComplete?.call(medicationId, medicationName);
          } else {
            await _handleComplete(data);
          }
          break;
        case NotificationActions.snooze:
          await _handleSnooze(data);
          break;
        case NotificationActions.skip:
          debugPrint('⏭️ 건너뛰기 선택됨 - 기록 안 함');
          break;
        case NotificationActions.dismiss:
          debugPrint('📱 알겠어요 선택됨');
          break;
      }
    } catch (e) {
      debugPrint('❌ 액션 처리 오류: $e');
    }
  }

  /// 완료 처리
  static Future<void> _handleComplete(Map<String, dynamic> data) async {
    final medicationId = data['medicationId'] as String?;
    if (medicationId == null) return;

    try {
      await MedicationStorageService.markMedicationCompleted(
        medicationId: medicationId,
        date: DateTime.now(),
        scheduledCount: 1,
      );

      await _resetReminderCount(medicationId);

      debugPrint('✅ 복용 완료 기록됨: $medicationId');
    } catch (e) {
      debugPrint('❌ 복용 완료 처리 오류: $e');
    }
  }

  /// 다시 울림 (스누즈) 처리 - 5분 후 재알림
  static Future<void> _handleSnooze(Map<String, dynamic> data) async {
    final medicationId = data['medicationId'] as String?;
    final medicationName = data['medicationName'] as String? ?? '약물';
    final typeStr = data['type'] as String? ?? 'oral';
    final dosage = data['dosage'] as String?;
    final notificationId = data['notificationId'] as int?;

    debugPrint('🔔 다시 울림 처리: $medicationName (5분 후)');

    try {
      final type = MedicationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => MedicationType.oral,
      );

      // 5분 후 재알림 예약
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final snoozeId = notificationId != null
          ? notificationId + 10000  // 스누즈 ID 충돌 방지
          : DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await scheduleFullscreenAlarm(
        id: snoozeId,
        medicationName: medicationName,
        type: type,
        scheduledTime: snoozeTime,
        dosage: dosage,
        medicationId: medicationId,
      );

      debugPrint('✅ 5분 후 다시 울림 예약됨: $medicationName at $snoozeTime');
    } catch (e) {
      debugPrint('❌ 다시 울림 처리 오류: $e');
    }
  }

  // ============================================
  // 권한 관리
  // ============================================

  /// 기본 알림 권한만 요청 (앱 시작 시 사용)
  /// SYSTEM_ALERT_WINDOW 권한은 요청하지 않음
  static Future<bool> requestBasicPermission() async {
    if (kIsWeb) return false;

    // Android: 기본 알림 권한만
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS: 알림 권한
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// 알림 권한 요청 (SYSTEM_ALERT_WINDOW 포함 - 풀스크린 알람 필요 시 사용)
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    // Android: 알림 권한 + 잠금화면 위 표시 권한
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // 기본 알림 권한
      final granted = await androidPlugin.requestNotificationsPermission();

      // 잠금화면 위에 표시 권한 (SYSTEM_ALERT_WINDOW)
      if (Platform.isAndroid) {
        final systemAlertWindowStatus = await Permission.systemAlertWindow.status;
        if (!systemAlertWindowStatus.isGranted) {
          debugPrint('🔐 잠금화면 위 표시 권한 요청');
          final result = await Permission.systemAlertWindow.request();
          debugPrint('🔐 잠금화면 위 표시 권한 결과: $result');
        }
      }

      return granted ?? false;
    }

    // iOS: 알림 권한
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// 정확한 알람 권한 요청 (Android 12+)
  static Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return true;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestExactAlarmsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// 정확한 알람 권한 확인
  static Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb) return true;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final canSchedule = await androidPlugin.canScheduleExactNotifications();
      return canSchedule ?? false;
    }

    return true;
  }

  /// 풀스크린 알람을 위한 모든 권한 요청
  static Future<Map<String, bool>> requestAllAlarmPermissions() async {
    final results = <String, bool>{};

    // 알림 권한
    results['notification'] = await requestPermission();

    // 정확한 알람 권한
    results['exactAlarm'] = await requestExactAlarmPermission();

    debugPrint('🔐 알람 권한 요청 결과: $results');
    return results;
  }

  /// 알림 활성화 여부 조회
  static Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? false;
  }

  /// 알림 활성화 상태 저장
  static Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
  }

  /// 디바이스 알림 설정 활성화 여부 확인
  static Future<bool> isDeviceNotificationEnabled() async {
    if (kIsWeb) return true;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final enabled = await androidPlugin.areNotificationsEnabled();
      return enabled ?? false;
    }

    // iOS는 권한 요청 시 설정됨
    return true;
  }

  /// 디바이스 알림 설정으로 이동
  static Future<void> openNotificationSettings() async {
    if (kIsWeb) return;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // ============================================
  // 미리 알림 (10분 전) - 푸시
  // ============================================

  /// 미리 알림 예약 (푸시)
  static Future<void> schedulePreNotification({
    required int id,
    required String medicationName,
    required MedicationType type,
    required DateTime scheduledTime,
    String? dosage,
    String? medicationId,
  }) async {
    if (kIsWeb) return;

    // 10분 전 시간 계산
    final preTime = scheduledTime.subtract(const Duration(minutes: 10));

    // 이미 지난 시간이면 스킵
    if (preTime.isBefore(DateTime.now())) {
      debugPrint('⏰ 이미 지난 미리 알림 스킵: $preTime');
      return;
    }

    final tzPreTime = tz.TZDateTime.from(preTime, tz.local);
    final timeString = _formatTime(scheduledTime);

    // 본문 구성: "약물명 용량 · 시간" 또는 "약물명 · 시간"
    final notificationBody = dosage != null
        ? '$medicationName $dosage · $timeString'
        : '$medicationName · $timeString';

    final payload = jsonEncode({
      'notificationId': id,
      'medicationId': medicationId ?? id.toString(),
      'medicationName': medicationName,
      'type': type.name,
      'dosage': dosage,
      'scheduledTime': scheduledTime.toIso8601String(),
    });

    // Android 알림 설정
    final androidDetails = AndroidNotificationDetails(
      'pre_notification_channel',
      '미리 알림',
      channelDescription: '복용 시간 10분 전 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          NotificationActions.snooze,
          '다시 울림',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          NotificationActions.skip,
          '건너뛰기',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActions.complete,
          type.completeButtonText,
          showsUserInterface: type == MedicationType.injection,
          cancelNotification: true,
        ),
      ],
    );

    // iOS 알림 설정
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'pre_${type.name}',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      '${type.icon} ${type.preNotificationTitle}',
      notificationBody,
      tzPreTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('📱 미리 알림 예약: $medicationName at $preTime');
  }

  // ============================================
  // 네이티브 풀스크린 알림
  // ============================================

  /// 네이티브 풀스크린 알림 표시 (즉시)
  /// 잠금화면 위에 바로 표시됨 (패턴 잠금 해제 불필요)
  static Future<void> showNativeFullScreenNotification({
    required int notificationId,
    required String title,
    required String message,
    String? medicationId,
    String? medicationName,
    String? medicationType,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      await _nativeChannel.invokeMethod('showFullScreenNotification', {
        'notificationId': notificationId,
        'title': title,
        'message': message,
        'medicationId': medicationId,
        'medicationName': medicationName,
        'medicationType': medicationType,
      });
      debugPrint('📞 네이티브 풀스크린 알림 표시: $title');
    } catch (e) {
      debugPrint('❌ 네이티브 풀스크린 알림 실패: $e');
    }
  }

  // ============================================
  // 정각 알림 - 풀스크린 알람
  // ============================================

  /// 정각 알림 예약 (풀스크린 알람)
  static Future<void> scheduleFullscreenAlarm({
    required int id,
    required String medicationName,
    required MedicationType type,
    required DateTime scheduledTime,
    String? dosage,
    String? medicationId,
  }) async {
    if (kIsWeb) return;

    // 이미 지난 시간이면 스킵
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⏰ 이미 지난 정각 알림 스킵: $scheduledTime');
      return;
    }

    // 알람 데이터 저장 (풀스크린 화면에서 사용)
    final alarmData = {
      'medicationId': medicationId ?? id.toString(),
      'medicationName': medicationName,
      'type': type.name,
      'dosage': dosage,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isReminder': false,
      'reminderCount': 0,
    };
    await _saveAlarmData(id, jsonEncode(alarmData));

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final timeString = _formatTime(scheduledTime);

    final payload = jsonEncode({
      'notificationId': id,
      'medicationId': medicationId ?? id.toString(),
      'medicationName': medicationName,
      'type': type.name,
      'dosage': dosage,
      'scheduledTime': scheduledTime.toIso8601String(),
    });

    // Android 풀스크린 알림 설정
    final androidDetails = AndroidNotificationDetails(
      'medication_alarm',
      '약물 알람',
      channelDescription: '약물 복용 시간 알람 (전체 화면)',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFF9B7ED9),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true, // 🔥 Full Screen Intent 활성화
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(
          NotificationActions.complete,
          type.completeButtonText,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          NotificationActions.snooze,
          '조금 이따',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    // iOS 알림 설정
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.aiff',
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'alarm_${type.name}',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      '${type.icon} ${type.fullscreenTitle}',
      dosage != null ? '$medicationName · $dosage · $timeString' : '$medicationName · $timeString',
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    // Alarm 패키지도 함께 사용 (소리/진동용)
    final alarmSettings = AlarmSettings(
      id: id + 10000, // ID 충돌 방지
      dateTime: scheduledTime,
      assetAudioPath: 'packages/alarm/assets/not_blank.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      warningNotificationOnKill: false,
      androidFullScreenIntent: false, // 알림은 flutter_local_notifications에서 처리
      notificationSettings: NotificationSettings(
        title: '${type.icon} ${type.fullscreenTitle}',
        body: dosage != null ? '$medicationName · $dosage' : medicationName,
        stopButton: type.completeButtonText,
        icon: 'ic_launcher',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    debugPrint('📞 풀스크린 알람 예약: $medicationName at $scheduledTime');
  }

  /// 리마인드 알림 예약 (5분 후)
  static Future<void> scheduleReminderAlarm({
    required int originalId,
    required String medicationName,
    required MedicationType type,
    required DateTime originalTime,
    String? dosage,
    String? medicationId,
    int reminderCount = 1,
  }) async {
    if (kIsWeb) return;

    if (reminderCount > _maxReminderCount) {
      debugPrint('⏰ 최대 리마인드 횟수 초과: $medicationName');
      return;
    }

    // 현재 시간 + 5분
    final reminderTime = DateTime.now().add(
      Duration(minutes: _reminderIntervalMinutes),
    );

    // 정각 알람 ID (originalId + 500) 기준으로 리마인더 ID 계산
    final reminderId = originalId + 500 + (reminderCount * 1000);

    // 알람 데이터 저장
    final alarmData = {
      'medicationId': medicationId ?? originalId.toString(),
      'medicationName': medicationName,
      'type': type.name,
      'dosage': dosage,
      'scheduledTime': originalTime.toIso8601String(),
      'isReminder': true,
      'reminderCount': reminderCount,
    };
    await _saveAlarmData(reminderId, jsonEncode(alarmData));
    await _saveReminderCount(medicationId ?? originalId.toString(), reminderCount);

    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
    final timeString = _formatTime(reminderTime);

    final payload = jsonEncode({
      'notificationId': reminderId,
      'medicationId': medicationId ?? originalId.toString(),
      'medicationName': medicationName,
      'type': type.name,
      'dosage': dosage,
      'scheduledTime': originalTime.toIso8601String(),
      'reminderCount': reminderCount,
    });

    // Android 풀스크린 리마인더 알림
    final androidDetails = AndroidNotificationDetails(
      'medication_alarm',
      '약물 알람',
      channelDescription: '약물 복용 시간 알람 (전체 화면)',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFFFA726),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true, // 🔥 Full Screen Intent 활성화
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(
          NotificationActions.complete,
          type.completeButtonText,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        if (reminderCount < _maxReminderCount)
          const AndroidNotificationAction(
            NotificationActions.snooze,
            '조금 이따',
            showsUserInterface: false,
            cancelNotification: true,
          ),
      ],
    );

    // iOS 알림 설정
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.aiff',
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'alarm_${type.name}',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      reminderId,
      '${type.icon} ${type.fullscreenTitle}',
      '⚠️ ${type.reminderMessage} · $timeString',
      tzReminderTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    // Alarm 패키지도 함께 사용 (소리/진동용)
    final alarmSettings = AlarmSettings(
      id: reminderId + 10000, // ID 충돌 방지
      dateTime: reminderTime,
      assetAudioPath: 'packages/alarm/assets/not_blank.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      warningNotificationOnKill: false,
      androidFullScreenIntent: false, // 알림은 flutter_local_notifications에서 처리
      notificationSettings: NotificationSettings(
        title: '${type.icon} ${type.fullscreenTitle}',
        body: '⚠️ ${type.reminderMessage}',
        stopButton: type.completeButtonText,
        icon: 'ic_launcher',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);

    debugPrint('📞 리마인드 알람 예약 ($reminderCount차): $medicationName at $reminderTime');
  }

  // ============================================
  // 약물별 알림 예약 (미리 + 정각)
  // ============================================

  /// 약물 알림 예약 (미리 알림 + 정각 풀스크린)
  static Future<void> scheduleMedicationNotifications({
    required int baseId,
    required String medicationName,
    required MedicationType type,
    required DateTime scheduledTime,
    String? dosage,
    String? medicationId,
  }) async {
    // 미리 알림 (10분 전 푸시)
    await schedulePreNotification(
      id: baseId,
      medicationName: medicationName,
      type: type,
      scheduledTime: scheduledTime,
      dosage: dosage,
      medicationId: medicationId,
    );

    // 정각 알림 (풀스크린)
    await scheduleFullscreenAlarm(
      id: baseId + 500, // ID 충돌 방지
      medicationName: medicationName,
      type: type,
      scheduledTime: scheduledTime,
      dosage: dosage,
      medicationId: medicationId,
    );
  }

  /// 매일 반복 알림 예약
  static Future<void> scheduleDailyMedicationNotifications({
    required int baseId,
    required String medicationName,
    required MedicationType type,
    required int hour,
    required int minute,
    String? dosage,
    String? medicationId,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // 오늘 시간이 지났으면 내일로
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleMedicationNotifications(
      baseId: baseId,
      medicationName: medicationName,
      type: type,
      scheduledTime: scheduledDate,
      dosage: dosage,
      medicationId: medicationId,
    );
  }

  // ============================================
  // 레거시 지원 메서드 (하위 호환)
  // ============================================

  /// 레거시: 약물 알림 예약 (기존 인터페이스 유지)
  static Future<void> scheduleMedicationNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    required bool isInjection,
    String? dosage,
    String? medicationId,
    int minutesBefore = 10,
  }) async {
    final type = isInjection ? MedicationType.injection : MedicationType.oral;

    await scheduleMedicationNotifications(
      baseId: id,
      medicationName: medicationName,
      type: type,
      scheduledTime: scheduledTime,
      dosage: dosage,
      medicationId: medicationId,
    );
  }

  /// 레거시: 매일 반복 알림 예약 (기존 인터페이스 유지)
  static Future<void> scheduleDailyMedicationNotification({
    required int id,
    required String medicationName,
    required int hour,
    required int minute,
    required bool isInjection,
    String? dosage,
    String? medicationId,
    int minutesBefore = 10,
  }) async {
    final type = isInjection ? MedicationType.injection : MedicationType.oral;

    await scheduleDailyMedicationNotifications(
      baseId: id,
      medicationName: medicationName,
      type: type,
      hour: hour,
      minute: minute,
      dosage: dosage,
      medicationId: medicationId,
    );
  }

  // ============================================
  // 알림/알람 취소
  // ============================================

  /// 특정 알림 취소
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    await Alarm.stop(id);
    await _removeAlarmData(id);
    debugPrint('🗑️ 알림 취소: $id');
  }

  /// 약물 관련 모든 알림 취소
  static Future<void> cancelMedicationNotifications(int baseId) async {
    // 푸시 알림 취소
    await _notifications.cancel(baseId);

    // 풀스크린 알람 취소 (정각 + 리마인드)
    await Alarm.stop(baseId + 500);
    await _removeAlarmData(baseId + 500);

    for (int i = 1; i <= _maxReminderCount; i++) {
      final reminderId = baseId + 500 + (i * 1000);
      await Alarm.stop(reminderId);
      await _removeAlarmData(reminderId);
    }

    debugPrint('🗑️ 약물 알림 모두 취소: baseId=$baseId');
  }

  /// 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await Alarm.stopAll();
    debugPrint('🗑️ 모든 알림 취소됨');
  }

  /// 예약된 알림 목록 조회
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 예약된 알람 목록 조회
  static Future<List<AlarmSettings>> getScheduledAlarms() async {
    return await Alarm.getAlarms();
  }

  // ============================================
  // 알람 데이터 관리
  // ============================================

  /// 알람 데이터 저장
  static Future<void> _saveAlarmData(int alarmId, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_alarmDataKey$alarmId', data);
  }

  /// 알람 데이터 조회
  static Future<Map<String, dynamic>?> getAlarmData(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_alarmDataKey$alarmId');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// 알람 데이터 삭제
  static Future<void> _removeAlarmData(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_alarmDataKey$alarmId');
  }

  /// 리마인드 카운트 저장
  static Future<void> _saveReminderCount(String medicationId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_reminderCountKey$medicationId', count);
  }

  /// 리마인드 카운트 조회
  static Future<int> getReminderCount(String medicationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_reminderCountKey$medicationId') ?? 0;
  }

  /// 리마인드 카운트 초기화
  static Future<void> _resetReminderCount(String medicationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_reminderCountKey$medicationId');
  }

  // ============================================
  // 유틸리티
  // ============================================

  /// 시간 포맷팅 (오전/오후 H:mm)
  static String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    if (hour < 12) {
      return '오전 ${hour == 0 ? 12 : hour}:$minute';
    } else {
      return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
    }
  }

  /// 테스트용 즉시 푸시 알림
  static Future<void> showTestNotification() async {
    if (kIsWeb) return;

    await schedulePreNotification(
      id: 99999,
      medicationName: '테스트 약물',
      type: MedicationType.oral,
      scheduledTime: DateTime.now().add(const Duration(minutes: 10)),
      dosage: '1알',
    );
  }

  /// 테스트용 즉시 풀스크린 알람
  static Future<void> showTestAlarm() async {
    if (kIsWeb) return;

    await scheduleFullscreenAlarm(
      id: 99998,
      medicationName: '테스트 약물',
      type: MedicationType.oral,
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      dosage: '1알',
    );
  }

  // ============================================
  // 인스턴스 메서드 (풀스크린 화면에서 사용)
  // ============================================

  /// 리마인드 알람 예약 (인스턴스 메서드)
  Future<void> scheduleNextReminder({
    required String medicationId,
    required String medicationName,
    String? dosage,
    required MedicationType medicationType,
    int reminderCount = 1,
  }) async {
    final originalId = int.tryParse(medicationId) ?? medicationId.hashCode;

    await NotificationService.scheduleReminderAlarm(
      originalId: originalId,
      medicationName: medicationName,
      type: medicationType,
      originalTime: DateTime.now(),
      dosage: dosage,
      medicationId: medicationId,
      reminderCount: reminderCount,
    );
  }

  /// 리마인드 알람 취소 (인스턴스 메서드)
  /// baseId는 원본 약물 ID이며, 정각 알람 ID (baseId + 500) 기준으로 리마인더를 취소
  Future<void> cancelReminderAlarms(int baseId) async {
    for (int i = 1; i <= _maxReminderCount; i++) {
      final reminderId = baseId + 500 + (i * 1000);
      await Alarm.stop(reminderId);
      await _removeAlarmData(reminderId);
    }
    debugPrint('🗑️ 리마인드 알람 취소: baseId=$baseId');
  }
}
