import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import 'medication_storage_service.dart';
import 'notification_service.dart';
import 'notification_settings_service.dart';
import 'alarm_service.dart';

/// 알림 스케줄러 서비스
/// 약물 일정에 따라 알림을 자동으로 예약/취소
class NotificationSchedulerService {
  static bool _initialized = false;

  /// 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    await NotificationService.initialize();
    await AlarmService.initialize();

    _initialized = true;
    debugPrint('NotificationSchedulerService 초기화 완료');
  }

  /// 모든 약물에 대한 알림 스케줄링
  static Future<void> scheduleAllMedications() async {
    final settings = await NotificationSettingsService.getSettings();
    if (!settings.isEnabled) {
      debugPrint('알림이 비활성화되어 있습니다.');
      return;
    }

    // 기존 알림 모두 취소
    await NotificationService.cancelAllNotifications();
    await AlarmService.stopAllAlarms();

    // 오늘 복용해야 할 약물 조회
    final medications = await MedicationStorageService.getTodayMedications();
    debugPrint('오늘 복용 약물: ${medications.length}개');

    for (final med in medications) {
      await scheduleMedication(med);
    }

    debugPrint('모든 약물 알림 스케줄링 완료');
  }

  /// 단일 약물에 대한 알림 스케줄링
  static Future<void> scheduleMedication(Medication medication) async {
    final settings = await NotificationSettingsService.getSettings();
    if (!settings.isEnabled) return;

    final now = DateTime.now();
    final timeParts = medication.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // 오늘 투여 시간
    final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    // 이미 지난 시간이면 스킵
    if (scheduledTime.isBefore(now)) {
      debugPrint('이미 지난 시간: ${medication.name} at ${medication.time}');
      return;
    }

    final isInjection = medication.type == MedicationType.injection;
    final notificationId = medication.id.hashCode.abs() % 100000;

    if (settings.alarmStyle) {
      // 알람 스타일 (끌 때까지 울림)
      await AlarmService.setMedicationAlarm(
        id: notificationId,
        medicationId: medication.id,
        medicationName: medication.name,
        scheduledTime: scheduledTime,
        isInjection: isInjection,
        dosage: medication.dosage,
      );
    } else {
      // 일반 푸시 알림
      await NotificationService.scheduleMedicationNotification(
        id: notificationId,
        medicationName: medication.name,
        scheduledTime: scheduledTime,
        isInjection: isInjection,
        dosage: medication.dosage,
        medicationId: medication.id,
        minutesBefore: 0, // 정각에 알림
      );
    }

    // 미리 알림 (설정된 경우)
    if (settings.preNotification) {
      final preNotificationId = notificationId + 50000;
      final preTime = scheduledTime.subtract(
        Duration(minutes: settings.preNotificationMinutes),
      );

      if (preTime.isAfter(now)) {
        await NotificationService.scheduleMedicationNotification(
          id: preNotificationId,
          medicationName: '${medication.name} (${settings.preNotificationMinutes}분 후)',
          scheduledTime: preTime,
          isInjection: isInjection,
          dosage: medication.dosage,
          medicationId: medication.id,
          minutesBefore: 0,
        );
        debugPrint('미리 알림 예약: ${medication.name} at $preTime');
      }
    }

    debugPrint('알림 예약됨: ${medication.name} at $scheduledTime');
  }

  /// 특정 약물 알림 취소
  static Future<void> cancelMedicationNotification(String medicationId) async {
    final notificationId = medicationId.hashCode.abs() % 100000;

    await NotificationService.cancelNotification(notificationId);
    await NotificationService.cancelNotification(notificationId + 50000); // 미리 알림
    await AlarmService.stopAlarm(notificationId);

    debugPrint('알림 취소됨: $medicationId');
  }

  /// 다음 날 알림 스케줄링 (자정에 호출)
  static Future<void> scheduleNextDayNotifications() async {
    await scheduleAllMedications();
  }

  /// 복용 완료 시 재알림 취소
  static Future<void> onMedicationCompleted(String medicationId) async {
    final notificationId = medicationId.hashCode.abs() % 100000;

    // 재알림 취소
    await NotificationService.cancelNotification(notificationId + 10000);
    await AlarmService.stopAlarm(notificationId + 10000);

    debugPrint('재알림 취소됨: $medicationId');
  }

  /// 미완료 시 재알림 설정
  static Future<void> scheduleSnooze({
    required Medication medication,
    int? customIntervalMinutes,
  }) async {
    final settings = await NotificationSettingsService.getSettings();
    if (!settings.repeatIfNotCompleted) return;

    final interval = customIntervalMinutes ?? settings.repeatIntervalMinutes;
    final snoozeTime = DateTime.now().add(Duration(minutes: interval));

    final isInjection = medication.type == MedicationType.injection;
    final notificationId = medication.id.hashCode.abs() % 100000 + 10000;

    if (settings.alarmStyle) {
      await AlarmService.setSnoozeAlarm(
        id: notificationId,
        medicationId: medication.id,
        medicationName: medication.name,
        isInjection: isInjection,
        dosage: medication.dosage,
        customIntervalMinutes: interval,
      );
    } else {
      await NotificationService.scheduleMedicationNotification(
        id: notificationId,
        medicationName: '${medication.name} (다시 알림)',
        scheduledTime: snoozeTime,
        isInjection: isInjection,
        dosage: medication.dosage,
        medicationId: medication.id,
        minutesBefore: 0,
      );
    }

    debugPrint('재알림 예약됨: ${medication.name} at $snoozeTime');
  }

  /// 배터리 최적화 예외 요청 안내
  static Future<void> requestBatteryOptimizationExemption() async {
    // 사용자에게 배터리 최적화 예외를 설정하도록 안내
    // permission_handler 패키지로 구현 가능
    debugPrint('배터리 최적화 예외 요청 필요');
  }

  /// 예약된 알림 목록 조회
  static Future<List<Map<String, dynamic>>> getScheduledNotifications() async {
    final pending = await NotificationService.getPendingNotifications();
    final alarms = await AlarmService.getAllAlarms();

    final result = <Map<String, dynamic>>[];

    for (final notification in pending) {
      result.add({
        'type': 'notification',
        'id': notification.id,
        'title': notification.title,
        'body': notification.body,
      });
    }

    for (final alarm in alarms) {
      result.add({
        'type': 'alarm',
        'id': alarm.id,
        'dateTime': alarm.dateTime.toString(),
        'title': alarm.notificationSettings.title,
      });
    }

    return result;
  }
}
