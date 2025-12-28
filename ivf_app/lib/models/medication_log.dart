/// 약물 복용/주사 로그 상태
enum MedicationStatus {
  pending,    // 대기
  completed,  // 복용/주사 완료
  skipped,    // 건너뜀
  snoozed,    // 다시 울림 설정됨
}

/// 약물 종류
enum MedicationType {
  pill,       // 알약 💊
  injection,  // 주사 💉
  suppository,// 질정 ⚪
  patch,      // 패치 🩹
}

/// 약물 복용/주사 로그
class MedicationLog {
  final String id;
  final String medicationId;
  final String medicationName;
  final MedicationType medicationType;
  final DateTime scheduledTime;    // 예정 시간
  DateTime? completedTime;         // 실제 복용/주사 시간
  MedicationStatus status;         // 상태
  String? injectionSide;           // 주사인 경우: 'left' / 'right'
  String? dosage;                  // 용량
  int snoozeCount;                 // 다시 울림 횟수

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.medicationType,
    required this.scheduledTime,
    this.completedTime,
    this.status = MedicationStatus.pending,
    this.injectionSide,
    this.dosage,
    this.snoozeCount = 0,
  });

  /// 복용/주사 완료 처리
  void markAsCompleted({String? side}) {
    status = MedicationStatus.completed;
    completedTime = DateTime.now();
    if (medicationType == MedicationType.injection && side != null) {
      injectionSide = side;
    }
  }

  /// 건너뛰기 처리
  void markAsSkipped() {
    status = MedicationStatus.skipped;
  }

  /// 다시 울림 처리
  void markAsSnoozed() {
    status = MedicationStatus.snoozed;
    snoozeCount++;
  }

  /// 액션 버튼 텍스트 반환
  String get completeButtonText {
    switch (medicationType) {
      case MedicationType.pill:
      case MedicationType.suppository:
        return '복용';
      case MedicationType.injection:
      case MedicationType.patch:
        return '완료';
    }
  }

  /// 아이콘 이모지 반환
  String get iconEmoji {
    switch (medicationType) {
      case MedicationType.pill:
        return '💊';
      case MedicationType.injection:
        return '💉';
      case MedicationType.suppository:
        return '⚪';
      case MedicationType.patch:
        return '🩹';
    }
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'medicationType': medicationType.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'status': status.name,
      'injectionSide': injectionSide,
      'dosage': dosage,
      'snoozeCount': snoozeCount,
    };
  }

  /// JSON에서 생성
  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'],
      medicationId: json['medicationId'],
      medicationName: json['medicationName'],
      medicationType: MedicationType.values.firstWhere(
        (e) => e.name == json['medicationType'],
        orElse: () => MedicationType.pill,
      ),
      scheduledTime: DateTime.parse(json['scheduledTime']),
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'])
          : null,
      status: MedicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MedicationStatus.pending,
      ),
      injectionSide: json['injectionSide'],
      dosage: json['dosage'],
      snoozeCount: json['snoozeCount'] ?? 0,
    );
  }
}
