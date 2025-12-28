import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_settings.dart';
import 'notification_settings_service.dart';

/// 알람 서비스 (끌 때까지 울리는 알람 스타일)
class AlarmService {
  static bool _initialized = false;

  /// 알람 서비스 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    await Alarm.init();
    _initialized = true;
    debugPrint('AlarmService 초기화 완료');
  }

  /// 약물 알람 설정
  static Future<void> setMedicationAlarm({
    required int id,
    required String medicationId,
    required String medicationName,
    required DateTime scheduledTime,
    required bool isInjection,
    String? dosage,
  }) async {
    if (kIsWeb) {
      debugPrint('웹에서는 알람이 지원되지 않습니다.');
      return;
    }

    final settings = await NotificationSettingsService.getSettings();

    if (!settings.isEnabled) {
      debugPrint('알림이 비활성화되어 있습니다.');
      return;
    }

    // 이미 지난 시간이면 스킵
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('이미 지난 시간의 알람은 설정하지 않습니다: $scheduledTime');
      return;
    }

    final typeText = isInjection ? '주사' : '약';
    final emoji = isInjection ? '💉' : '💊';

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: scheduledTime,
      assetAudioPath: 'assets/alarm_sound.mp3',
      loopAudio: settings.alarmStyle, // 알람 스타일이면 반복
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: '$emoji $medicationName $typeText 시간',
        body: dosage != null ? '$dosage 복용하세요' : '복용 시간이에요!',
        stopButton: '중지',
        icon: 'ic_launcher',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
    debugPrint('알람 설정됨: $medicationName at $scheduledTime');
  }

  /// 미리 알림 설정 (일반 푸시 알림)
  static Future<void> setPreNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    required bool isInjection,
    int minutesBefore = 10,
  }) async {
    final settings = await NotificationSettingsService.getSettings();

    if (!settings.isEnabled || !settings.preNotification) {
      return;
    }

    final preTime = scheduledTime.subtract(
      Duration(minutes: settings.preNotificationMinutes),
    );

    if (preTime.isBefore(DateTime.now())) {
      return;
    }

    // 미리 알림은 일반 알림으로 설정 (flutter_local_notifications 사용)
    // NotificationService에서 처리
    debugPrint('미리 알림 설정됨: $medicationName at $preTime');
  }

  /// 재알림 설정 (다시 알림)
  static Future<void> setSnoozeAlarm({
    required int id,
    required String medicationId,
    required String medicationName,
    required bool isInjection,
    String? dosage,
    int? customIntervalMinutes,
  }) async {
    final settings = await NotificationSettingsService.getSettings();

    final intervalMinutes =
        customIntervalMinutes ?? settings.repeatIntervalMinutes;
    final snoozeTime = DateTime.now().add(Duration(minutes: intervalMinutes));

    await setMedicationAlarm(
      id: id + 10000, // 재알림은 ID 오프셋 추가
      medicationId: medicationId,
      medicationName: medicationName,
      scheduledTime: snoozeTime,
      isInjection: isInjection,
      dosage: dosage,
    );

    debugPrint('재알림 설정됨: $medicationName at $snoozeTime');
  }

  /// 알람 중지
  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
    debugPrint('알람 중지됨: ID $id');
  }

  /// 모든 알람 중지
  static Future<void> stopAllAlarms() async {
    await Alarm.stopAll();
    debugPrint('모든 알람 중지됨');
  }

  /// 특정 알람이 설정되어 있는지 확인
  static Future<bool> isAlarmSet(int id) async {
    final alarms = Alarm.getAlarms();
    return alarms.any((a) => a.id == id);
  }

  /// 설정된 모든 알람 조회
  static List<AlarmSettings> getAllAlarms() {
    return Alarm.getAlarms();
  }

  /// 알람 스트림 (알람 울릴 때 이벤트)
  static Stream<AlarmSettings> get ringStream => Alarm.ringStream.stream;
}

/// Platform 체크용 (kIsWeb 외)
class Platform {
  static bool get isIOS {
    try {
      return defaultTargetPlatform == TargetPlatform.iOS;
    } catch (e) {
      return false;
    }
  }

  static bool get isAndroid {
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (e) {
      return false;
    }
  }
}
