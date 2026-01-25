import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medication.dart';

/// 알림 액션 ID
class NotificationActions {
  static const String complete = 'COMPLETE';
  static const String snooze = 'SNOOZE';
}

/// 알림 서비스 (단순화 버전)
///
/// - flutter_local_notifications만 사용
/// - 푸시 알림 + 액션 버튼 2개 (복용 완료, 나중에)
/// - 스누즈는 5분 후 1회만
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _pendingActionKey = 'pending_notification_action';

  /// 스누즈 시간 (5분 고정)
  static const int snoozeMinutes = 5;

  /// 액션 처리 콜백 (main.dart에서 설정)
  static void Function(String actionId, String? payload)? onActionReceived;

  // ============================================
  // 초기화
  // ============================================

  /// 알림 서비스 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    // 타임존 초기화
    tz.initializeTimeZones();

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: _buildIOSCategories(),
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    _initialized = true;
    debugPrint('✅ NotificationService 초기화 완료 (단순화 버전)');
  }

  /// iOS 카테고리 빌드
  static List<DarwinNotificationCategory> _buildIOSCategories() {
    return [
      DarwinNotificationCategory(
        'medication_alarm',
        actions: [
          DarwinNotificationAction.plain(
            NotificationActions.complete,
            '복용 완료',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain(
            NotificationActions.snooze,
            '나중에',
          ),
        ],
        options: {
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      ),
    ];
  }

  /// 알림 응답 처리 (포그라운드)
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 알림 응답: actionId=${response.actionId}, payload=${response.payload}');

    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && payload != null) {
      onActionReceived?.call(actionId, payload);
    } else if (payload != null) {
      // 알림 탭 (버튼 아님) - 앱 열기
      onActionReceived?.call('TAP', payload);
    }
  }

  /// 알림 응답 처리 (백그라운드)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 백그라운드 알림 응답: actionId=${response.actionId}');

    // 백그라운드에서는 SharedPreferences에 저장하고 앱 시작 시 처리
    if (response.actionId != null && response.payload != null) {
      _savePendingAction(response.actionId!, response.payload!);
    }
  }

  /// 펜딩 액션 저장
  static Future<void> _savePendingAction(String actionId, String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingActionKey, jsonEncode({
      'actionId': actionId,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  /// 펜딩 액션 처리 (앱 시작 시 호출)
  static Future<void> processPendingAction() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingData = prefs.getString(_pendingActionKey);

    if (pendingData != null) {
      await prefs.remove(_pendingActionKey);

      try {
        final data = jsonDecode(pendingData) as Map<String, dynamic>;
        final actionId = data['actionId'] as String;
        final payload = data['payload'] as String;

        onActionReceived?.call(actionId, payload);
      } catch (e) {
        debugPrint('❌ 펜딩 액션 처리 오류: $e');
      }
    }
  }

  // ============================================
  // 권한 관리
  // ============================================

  /// 알림 권한 요청
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }

    if (Platform.isIOS) {
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
    }

    return true;
  }

  /// 정확한 알람 권한 요청 (Android 12+)
  static Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestExactAlarmsPermission();
        return granted ?? false;
      }
    }

    return true;
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

  // ============================================
  // 알림 예약
  // ============================================

  /// 약물 알림 예약
  static Future<void> scheduleMedicationNotification({
    required int id,
    required String medicationId,
    required String medicationName,
    required MedicationType type,
    required DateTime scheduledTime,
    String? dosage,
    bool isSnooze = false,
  }) async {
    if (kIsWeb) return;

    // 이미 지난 시간이면 스킵
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⏰ 이미 지난 알림 스킵: $scheduledTime');
      return;
    }

    // 알림 내용 구성
    final title = '${type.icon} ${medicationName} 복용 시간이에요';
    final body = dosage != null && dosage.isNotEmpty
        ? '$dosage ${type.actionVerb}'
        : '${type.actionVerb}';

    // 페이로드 (액션 처리에 필요한 데이터)
    final payload = jsonEncode({
      'medicationId': medicationId,
      'medicationName': medicationName,
      'type': type.name,
      'dosage': dosage,
      'isSnooze': isSnooze,
    });

    // Android 알림 상세 설정
    final androidDetails = AndroidNotificationDetails(
      'medication_channel',
      '약물 알림',
      channelDescription: '약물 복용 알림',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        AndroidNotificationAction(
          NotificationActions.complete,
          type.completeButtonText,
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          NotificationActions.snooze,
          '나중에',
        ),
      ],
    );

    // iOS 알림 상세 설정
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_alarm',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 알림 예약
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('📬 알림 예약됨: $medicationName at $scheduledTime (id=$id, isSnooze=$isSnooze)');
  }

  /// 스누즈 알림 예약 (5분 후 1회)
  static Future<void> scheduleSnoozeNotification({
    required int originalId,
    required String medicationId,
    required String medicationName,
    required MedicationType type,
    String? dosage,
  }) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    final snoozeId = originalId + 100000; // 스누즈 ID는 원본 + 100000

    await scheduleMedicationNotification(
      id: snoozeId,
      medicationId: medicationId,
      medicationName: medicationName,
      type: type,
      scheduledTime: snoozeTime,
      dosage: dosage,
      isSnooze: true,
    );

    debugPrint('⏰ 스누즈 예약됨: $medicationName ($snoozeMinutes분 후)');
  }

  // ============================================
  // 알림 취소
  // ============================================

  /// 특정 알림 취소
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    // 스누즈 알림도 함께 취소
    await _notifications.cancel(id + 100000);
    debugPrint('🗑️ 알림 취소: $id');
  }

  /// 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ 모든 알림 취소됨');
  }

  /// 예약된 알림 목록 조회
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ============================================
  // 테스트
  // ============================================

  /// 테스트 알림 (5초 후)
  static Future<void> showTestNotification() async {
    await scheduleMedicationNotification(
      id: 99999,
      medicationId: 'test',
      medicationName: '테스트 약물',
      type: MedicationType.oral,
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      dosage: '1알',
    );
  }

  /// 즉시 알림 표시 (테스트용)
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      '테스트 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }
}
