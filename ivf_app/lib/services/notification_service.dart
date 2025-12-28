import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 알림 액션 ID
class NotificationActions {
  static const String snooze = 'snooze';     // 다시 울림
  static const String skip = 'skip';         // 건너뛰기
  static const String complete = 'complete'; // 복용/완료
}

/// 알림 액션 콜백 타입
typedef NotificationActionCallback = void Function(
  String actionId,
  String? payload,
);

/// 로컬 알림 서비스
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static const String _notificationEnabledKey = 'notification_enabled';

  /// 액션 콜백 (외부에서 설정)
  static NotificationActionCallback? onActionReceived;

  /// 주사 부위 선택 콜백 (주사 완료 시 호출)
  static void Function(String medicationId, String medicationName)? onInjectionComplete;

  /// 알림 서비스 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    // 타임존 초기화
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'medication_category',
          actions: [
            DarwinNotificationAction.plain('snooze', '다시 울림'),
            DarwinNotificationAction.plain('skip', '건너뛰기'),
            DarwinNotificationAction.plain('complete', '복용'),
          ],
        ),
        DarwinNotificationCategory(
          'injection_category',
          actions: [
            DarwinNotificationAction.plain('snooze', '다시 울림'),
            DarwinNotificationAction.plain('skip', '건너뛰기'),
            DarwinNotificationAction.plain('complete', '완료'),
          ],
        ),
      ],
    );

    // macOS 설정
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
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    _initialized = true;
    debugPrint('NotificationService 초기화 완료');
  }

  /// 알림 응답 처리 (탭 또는 액션)
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('알림 응답: actionId=${response.actionId}, payload=${response.payload}');

    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && actionId.isNotEmpty) {
      _handleAction(actionId, payload);
    } else {
      // 알림 본체 탭 시 - 앱 열기
      debugPrint('알림 탭됨 - 앱 열기');
    }
  }

  /// 백그라운드 알림 응답 처리
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('백그라운드 알림 응답: actionId=${response.actionId}');
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && actionId.isNotEmpty) {
      _handleAction(actionId, payload);
    }
  }

  /// 액션 처리
  static void _handleAction(String actionId, String? payload) {
    debugPrint('액션 처리: $actionId, payload: $payload');

    // 외부 콜백 호출
    onActionReceived?.call(actionId, payload);

    // payload에서 정보 파싱
    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final medicationId = data['medicationId'] as String?;
      final medicationName = data['medicationName'] as String?;
      final isInjection = data['isInjection'] as bool? ?? false;

      switch (actionId) {
        case NotificationActions.snooze:
          _handleSnooze(data);
          break;
        case NotificationActions.skip:
          _handleSkip(data);
          break;
        case NotificationActions.complete:
          if (isInjection && medicationId != null && medicationName != null) {
            // 주사인 경우 부위 선택 필요
            onInjectionComplete?.call(medicationId, medicationName);
          } else {
            // 그 외는 바로 완료 처리
            _handleComplete(data);
          }
          break;
      }
    } catch (e) {
      debugPrint('payload 파싱 오류: $e');
    }
  }

  /// 다시 울림 처리 (10분 후)
  static void _handleSnooze(Map<String, dynamic> data) {
    debugPrint('다시 울림 처리: $data');

    final medicationName = data['medicationName'] as String? ?? '약물';
    final isInjection = data['isInjection'] as bool? ?? false;
    final notificationId = data['notificationId'] as int? ?? 0;

    // 10분 후 다시 알림
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));

    showMedicationNotification(
      id: notificationId + 1000, // 새 ID
      medicationName: medicationName,
      scheduledTime: snoozeTime,
      isInjection: isInjection,
      dosage: data['dosage'] as String?,
      medicationId: data['medicationId'] as String?,
    );
  }

  /// 건너뛰기 처리
  static void _handleSkip(Map<String, dynamic> data) {
    debugPrint('건너뛰기 처리: $data');
    // TODO: 로그에 skipped 상태로 기록
  }

  /// 완료 처리
  static void _handleComplete(Map<String, dynamic> data) {
    debugPrint('완료 처리: $data');
    // TODO: 로그에 completed 상태로 기록
  }

  /// 알림 권한 요청
  static Future<bool> requestPermission() async {
    if (kIsWeb) {
      debugPrint('웹에서는 로컬 알림이 지원되지 않습니다.');
      return false;
    }

    // Android 13+ 권한 요청
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS 권한 요청
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

  /// 즉시 알림 표시 (테스트용)
  static Future<void> showTestNotification() async {
    if (kIsWeb) {
      debugPrint('웹에서는 로컬 알림이 지원되지 않습니다.');
      return;
    }

    await showMedicationNotification(
      id: 0,
      medicationName: '테스트 약물',
      scheduledTime: DateTime.now(),
      isInjection: false,
      dosage: '100mg',
    );
  }

  /// 약물 알림 표시 (액션 버튼 포함)
  static Future<void> showMedicationNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    required bool isInjection,
    String? dosage,
    String? medicationId,
  }) async {
    if (kIsWeb) {
      debugPrint('웹에서는 로컬 알림이 지원되지 않습니다.');
      return;
    }

    final timeString = _formatTime(scheduledTime);
    final icon = isInjection ? '💉' : '💊';
    final title = isInjection ? '주사 맞을 시간' : '약을 복용할 시간';
    final body = '$timeString $medicationName ${isInjection ? "주사" : "복용"}하는 것을 잊지 마세요.';
    final completeText = isInjection ? '완료' : '복용';

    // payload에 정보 저장
    final payload = jsonEncode({
      'notificationId': id,
      'medicationId': medicationId ?? id.toString(),
      'medicationName': medicationName,
      'isInjection': isInjection,
      'dosage': dosage,
      'scheduledTime': scheduledTime.toIso8601String(),
    });

    // Android 알림 설정 (액션 버튼 포함)
    final androidDetails = AndroidNotificationDetails(
      'ivf_medication_channel',
      '약물 알림',
      channelDescription: 'IVF 약물 투여 시간 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          NotificationActions.snooze,
          '다시 울림',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          NotificationActions.skip,
          '건너뛰기',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationActions.complete,
          completeText,
          showsUserInterface: isInjection, // 주사는 앱 열어서 부위 선택
        ),
      ],
    );

    // iOS 알림 설정
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: isInjection ? 'injection_category' : 'medication_category',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.show(
      id,
      '$icon $title',
      body,
      details,
      payload: payload,
    );

    debugPrint('알림 표시됨: $medicationName');
  }

  /// 약물 알림 예약 (액션 버튼 포함)
  static Future<void> scheduleMedicationNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    required bool isInjection,
    String? dosage,
    String? medicationId,
    int minutesBefore = 10,
  }) async {
    if (kIsWeb) {
      debugPrint('웹에서는 로컬 알림이 지원되지 않습니다.');
      return;
    }

    // 알림 시간 (투여 시간 X분 전)
    final notificationTime = scheduledTime.subtract(Duration(minutes: minutesBefore));

    // 이미 지난 시간이면 스킵
    if (notificationTime.isBefore(DateTime.now())) {
      debugPrint('이미 지난 시간의 알림은 예약하지 않습니다: $notificationTime');
      return;
    }

    final tzScheduledTime = tz.TZDateTime.from(notificationTime, tz.local);
    final timeString = _formatTime(scheduledTime);
    final icon = isInjection ? '💉' : '💊';
    final title = isInjection ? '주사 맞을 시간' : '약을 복용할 시간';
    final body = '$timeString $medicationName ${isInjection ? "주사" : "복용"}하는 것을 잊지 마세요.';
    final completeText = isInjection ? '완료' : '복용';

    // payload에 정보 저장
    final payload = jsonEncode({
      'notificationId': id,
      'medicationId': medicationId ?? id.toString(),
      'medicationName': medicationName,
      'isInjection': isInjection,
      'dosage': dosage,
      'scheduledTime': scheduledTime.toIso8601String(),
    });

    // Android 알림 설정 (액션 버튼 포함)
    final androidDetails = AndroidNotificationDetails(
      'ivf_medication_channel',
      '약물 알림',
      channelDescription: 'IVF 약물 투여 시간 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          NotificationActions.snooze,
          '다시 울림',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          NotificationActions.skip,
          '건너뛰기',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationActions.complete,
          completeText,
          showsUserInterface: isInjection,
        ),
      ],
    );

    // iOS 알림 설정
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: isInjection ? 'injection_category' : 'medication_category',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      '$icon $title',
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: payload,
    );

    debugPrint('알림 예약됨: $medicationName at $notificationTime');
  }

  /// 매일 반복 알림 예약
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
    if (kIsWeb) {
      debugPrint('웹에서는 로컬 알림이 지원되지 않습니다.');
      return;
    }

    // 알림 시간 계산 (X분 전)
    var notifyHour = hour;
    var notifyMinute = minute - minutesBefore;
    if (notifyMinute < 0) {
      notifyMinute += 60;
      notifyHour -= 1;
      if (notifyHour < 0) {
        notifyHour = 23;
      }
    }

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, notifyHour, notifyMinute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
    final originalTime = DateTime(now.year, now.month, now.day, hour, minute);
    final timeString = _formatTime(originalTime);
    final icon = isInjection ? '💉' : '💊';
    final title = isInjection ? '주사 맞을 시간' : '약을 복용할 시간';
    final body = '$timeString $medicationName ${isInjection ? "주사" : "복용"}하는 것을 잊지 마세요.';
    final completeText = isInjection ? '완료' : '복용';

    final payload = jsonEncode({
      'notificationId': id,
      'medicationId': medicationId ?? id.toString(),
      'medicationName': medicationName,
      'isInjection': isInjection,
      'dosage': dosage,
      'scheduledTime': originalTime.toIso8601String(),
    });

    final androidDetails = AndroidNotificationDetails(
      'ivf_medication_channel',
      '약물 알림',
      channelDescription: 'IVF 약물 투여 시간 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        const AndroidNotificationAction(
          NotificationActions.snooze,
          '다시 울림',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          NotificationActions.skip,
          '건너뛰기',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationActions.complete,
          completeText,
          showsUserInterface: isInjection,
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: isInjection ? 'injection_category' : 'medication_category',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      '$icon $title',
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint('매일 반복 알림 예약됨: $medicationName at $notifyHour:$notifyMinute');
  }

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

  /// 특정 약물의 모든 알림 취소
  static Future<void> cancelMedicationNotifications(int baseId) async {
    for (int i = 0; i < 10; i++) {
      await _notifications.cancel(baseId * 10 + i);
    }
  }

  /// 특정 알림 취소
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('모든 알림 취소됨');
  }

  /// 예약된 알림 목록 조회
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
