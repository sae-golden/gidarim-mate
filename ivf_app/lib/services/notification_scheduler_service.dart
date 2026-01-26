import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import 'medication_storage_service.dart';
import 'notification_service.dart';
import 'notification_settings_service.dart';

/// 알림 스케줄러 서비스 (단순화 버전)
///
/// - 푸시 알림만 사용 (풀스크린 알람 없음)
/// - 스누즈는 main.dart에서 처리 (5분 후 1회만)
class NotificationSchedulerService {
  static bool _initialized = false;

  /// 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    await NotificationService.initialize();

    _initialized = true;
    debugPrint('✅ NotificationSchedulerService 초기화 완료 (단순화 버전)');
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

    // 오늘 복용해야 할 약물 조회
    final medications = await MedicationStorageService.getTodayMedications();
    debugPrint('오늘 복용 약물: ${medications.length}개');

    for (final med in medications) {
      await scheduleMedication(med);
    }

    debugPrint('✅ 모든 약물 알림 스케줄링 완료');
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

    final notificationId = medication.id.hashCode.abs() % 100000;

    // 푸시 알림 예약
    await NotificationService.scheduleMedicationNotification(
      id: notificationId,
      medicationId: medication.id,
      medicationName: medication.name,
      type: medication.type,
      scheduledTime: scheduledTime,
      dosage: medication.dosage,
    );

    debugPrint('📬 알림 예약됨: ${medication.name} at $scheduledTime');
  }

  /// 특정 약물 알림 취소
  static Future<void> cancelMedicationNotification(String medicationId) async {
    final notificationId = medicationId.hashCode.abs() % 100000;
    await NotificationService.cancelNotification(notificationId);
    debugPrint('🗑️ 알림 취소됨: $medicationId');
  }

  /// 다음 날 알림 스케줄링 (자정에 호출)
  static Future<void> scheduleNextDayNotifications() async {
    await scheduleAllMedications();
  }

  /// 복용 완료 시 스누즈 알림 취소
  static Future<void> onMedicationCompleted(String medicationId) async {
    final notificationId = medicationId.hashCode.abs() % 100000;
    // 스누즈 알림 취소 (ID + 100000)
    await NotificationService.cancelNotification(notificationId + 100000);
    debugPrint('✅ 스누즈 알림 취소됨: $medicationId');
  }

  /// 예약된 알림 목록 조회
  static Future<List<Map<String, dynamic>>> getScheduledNotifications() async {
    final pending = await NotificationService.getPendingNotifications();

    return pending.map((notification) => {
      'type': 'notification',
      'id': notification.id,
      'title': notification.title,
      'body': notification.body,
    }).toList();
  }
}
