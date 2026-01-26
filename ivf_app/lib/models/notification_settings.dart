/// 알림 설정 모델 (단순 버전)
/// - 소리: 없음 (무조건)
/// - 진동: 항상 켜짐
/// - 스누즈: 5분 간격, 최대 3회
class NotificationSettings {
  final bool isEnabled; // 알림 받기
  final int repeatIntervalMinutes; // 스누즈 간격 (분)

  const NotificationSettings({
    this.isEnabled = true,
    this.repeatIntervalMinutes = 5, // 기본값 5분
  });

  /// 기본 설정
  static const NotificationSettings defaultSettings = NotificationSettings();

  /// 스누즈 간격 옵션
  static const List<int> repeatIntervalOptions = [3, 5, 10];

  /// 자동 스누즈 타임아웃 (초)
  static const int autoSnoozeTimeoutSeconds = 60; // 1분 방치 시 자동 스누즈

  /// 최대 스누즈 횟수
  static const int maxSnoozeCount = 3;

  NotificationSettings copyWith({
    bool? isEnabled,
    int? repeatIntervalMinutes,
  }) {
    return NotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'repeatIntervalMinutes': repeatIntervalMinutes,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      isEnabled: json['isEnabled'] as bool? ?? true,
      repeatIntervalMinutes: json['repeatIntervalMinutes'] as int? ?? 5,
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

/// 약물 복용 기록
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
