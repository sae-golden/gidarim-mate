/// 알림 설정 모델
class NotificationSettings {
  final bool isEnabled; // 알림 받기
  final bool preNotification; // 미리 알림
  final int preNotificationMinutes; // 미리 알림 시간 (분)
  final bool alarmStyle; // 알람 스타일 (끌 때까지 울림)
  final bool repeatIfNotCompleted; // 미완료 시 재알림
  final int repeatIntervalMinutes; // 재알림 간격 (분)
  final double alarmVolume; // 알람 음량 (0.0 ~ 1.0)

  const NotificationSettings({
    this.isEnabled = true,
    this.preNotification = true,
    this.preNotificationMinutes = 10,
    this.alarmStyle = true,
    this.repeatIfNotCompleted = true,
    this.repeatIntervalMinutes = 5, // 기본값 5분으로 변경
    this.alarmVolume = 0.8,
  });

  /// 기본 설정
  static const NotificationSettings defaultSettings = NotificationSettings();

  /// 미리 알림 시간 옵션
  static const List<int> preNotificationOptions = [5, 10, 15, 30];

  /// 재알림 간격 옵션
  static const List<int> repeatIntervalOptions = [5, 10, 15, 30];

  NotificationSettings copyWith({
    bool? isEnabled,
    bool? preNotification,
    int? preNotificationMinutes,
    bool? alarmStyle,
    bool? repeatIfNotCompleted,
    int? repeatIntervalMinutes,
    double? alarmVolume,
  }) {
    return NotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      preNotification: preNotification ?? this.preNotification,
      preNotificationMinutes:
          preNotificationMinutes ?? this.preNotificationMinutes,
      alarmStyle: alarmStyle ?? this.alarmStyle,
      repeatIfNotCompleted: repeatIfNotCompleted ?? this.repeatIfNotCompleted,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      alarmVolume: alarmVolume ?? this.alarmVolume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'preNotification': preNotification,
      'preNotificationMinutes': preNotificationMinutes,
      'alarmStyle': alarmStyle,
      'repeatIfNotCompleted': repeatIfNotCompleted,
      'repeatIntervalMinutes': repeatIntervalMinutes,
      'alarmVolume': alarmVolume,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      isEnabled: json['isEnabled'] as bool? ?? true,
      preNotification: json['preNotification'] as bool? ?? true,
      preNotificationMinutes: json['preNotificationMinutes'] as int? ?? 10,
      alarmStyle: json['alarmStyle'] as bool? ?? true,
      repeatIfNotCompleted: json['repeatIfNotCompleted'] as bool? ?? true,
      repeatIntervalMinutes: json['repeatIntervalMinutes'] as int? ?? 5,
      alarmVolume: (json['alarmVolume'] as num?)?.toDouble() ?? 0.8,
    );
  }
}

/// 약물 복용 상태
enum MedicationStatus {
  pending, // 대기
  completed, // 완료
  skipped, // 건너뜀
  snoozed, // 다시 알림 중
}

/// 약물 복용 상태 확장
extension MedicationStatusExtension on MedicationStatus {
  String get label {
    switch (this) {
      case MedicationStatus.pending:
        return '대기';
      case MedicationStatus.completed:
        return '완료';
      case MedicationStatus.skipped:
        return '건너뜀';
      case MedicationStatus.snoozed:
        return '다시 알림';
    }
  }

  String get emoji {
    switch (this) {
      case MedicationStatus.pending:
        return '⏳';
      case MedicationStatus.completed:
        return '✅';
      case MedicationStatus.skipped:
        return '⏭️';
      case MedicationStatus.snoozed:
        return '🔁';
    }
  }
}

/// 약물 복용 기록 (확장 버전)
class MedicationLogEntry {
  final String id;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime; // 예정 시간
  final DateTime? completedTime; // 실제 완료 시간
  final MedicationStatus status;
  final String? injectionSide; // 주사인 경우: 'left' / 'right'
  final int snoozeCount; // 다시 알림 횟수
  final bool isInjection;

  MedicationLogEntry({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.completedTime,
    this.status = MedicationStatus.pending,
    this.injectionSide,
    this.snoozeCount = 0,
    this.isInjection = false,
  });

  MedicationLogEntry copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    DateTime? completedTime,
    MedicationStatus? status,
    String? injectionSide,
    int? snoozeCount,
    bool? isInjection,
  }) {
    return MedicationLogEntry(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completedTime: completedTime ?? this.completedTime,
      status: status ?? this.status,
      injectionSide: injectionSide ?? this.injectionSide,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      isInjection: isInjection ?? this.isInjection,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'status': status.index,
      'injectionSide': injectionSide,
      'snoozeCount': snoozeCount,
      'isInjection': isInjection,
    };
  }

  factory MedicationLogEntry.fromJson(Map<String, dynamic> json) {
    return MedicationLogEntry(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'] as String)
          : null,
      status: MedicationStatus.values[json['status'] as int? ?? 0],
      injectionSide: json['injectionSide'] as String?,
      snoozeCount: json['snoozeCount'] as int? ?? 0,
      isInjection: json['isInjection'] as bool? ?? false,
    );
  }
}
