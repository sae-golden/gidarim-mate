/// 약물 정보 모델
class Medication {
  final String id;
  final String name; // 약물명
  final String? dosage; // 용량
  final String time; // 시간 (예: "매일 아침 8:00")
  final DateTime startDate; // 시작일
  final DateTime endDate; // 종료일
  final MedicationType type; // 주사 or 경구약
  final String? pattern; // 패턴 (매일, 격일, 월수금 등)
  final int totalCount; // 총 횟수
  
  Medication({
    required this.id,
    required this.name,
    this.dosage,
    required this.time,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.pattern,
    required this.totalCount,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type.toString(),
      'pattern': pattern,
      'totalCount': totalCount,
    };
  }
  
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String?,
      time: json['time'] as String? ?? '08:00',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now(),
      type: MedicationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MedicationType.oral,
      ),
      pattern: json['pattern'] as String?,
      totalCount: json['totalCount'] as int? ?? 1,
    );
  }
}

/// 약물 타입
enum MedicationType {
  injection, // 주사
  oral, // 경구약
  suppository, // 질정
  patch, // 한약 (기존 patch 유지 - DB 호환성)
}

/// 약물 타입별 알림 메시지 및 아이콘
extension MedicationTypeNotification on MedicationType {
  /// 알림 아이콘
  String get icon {
    switch (this) {
      case MedicationType.injection:
        return '💉';
      case MedicationType.oral:
        return '💊';
      case MedicationType.suppository:
        return '💊';
      case MedicationType.patch:
        return '🍵';
    }
  }

  /// 약물 타입 한글명
  String get typeName {
    switch (this) {
      case MedicationType.injection:
        return '주사';
      case MedicationType.oral:
        return '알약';
      case MedicationType.suppository:
        return '질정';
      case MedicationType.patch:
        return '한약';
    }
  }

  /// 미리 알림 제목 (10분 전 푸시)
  String get preNotificationTitle {
    switch (this) {
      case MedicationType.injection:
        return '곧 주사 맞을 시간이에요';
      case MedicationType.oral:
        return '곧 약 먹을 시간이에요';
      case MedicationType.suppository:
        return '곧 질정 사용할 시간이에요';
      case MedicationType.patch:
        return '곧 한약 먹을 시간이에요';
    }
  }

  /// 풀스크린 알림 제목 (정각)
  String get fullscreenTitle {
    switch (this) {
      case MedicationType.injection:
        return '주사 맞을 시간이에요';
      case MedicationType.oral:
        return '약 먹을 시간이에요';
      case MedicationType.suppository:
        return '질정 사용할 시간이에요';
      case MedicationType.patch:
        return '한약 먹을 시간이에요';
    }
  }

  /// 완료 버튼 텍스트
  String get completeButtonText {
    switch (this) {
      case MedicationType.injection:
        return '맞았어요';
      case MedicationType.oral:
        return '먹었어요';
      case MedicationType.suppository:
        return '완료했어요';
      case MedicationType.patch:
        return '먹었어요';
    }
  }

  /// 리마인드 알림 메시지 (미완료 시)
  String get reminderMessage {
    switch (this) {
      case MedicationType.injection:
        return '아직 주사 맞지 않으셨어요';
      case MedicationType.oral:
        return '아직 약 먹지 않으셨어요';
      case MedicationType.suppository:
        return '아직 질정 사용하지 않으셨어요';
      case MedicationType.patch:
        return '아직 한약 먹지 않으셨어요';
    }
  }

  /// 알림 본문 동사 (복용하세요 등)
  String get actionVerb {
    switch (this) {
      case MedicationType.injection:
        return '맞을 시간이에요';
      case MedicationType.oral:
        return '드실 시간이에요';
      case MedicationType.suppository:
        return '사용할 시간이에요';
      case MedicationType.patch:
        return '드실 시간이에요';
    }
  }
}

/// 약물 복용 기록
class MedicationLog {
  final String id;
  final String medicationId;
  final DateTime scheduledTime; // 예정 시간
  final DateTime? completedTime; // 완료 시간
  final bool isCompleted; // 완료 여부
  final String? injectionLocation; // 주사 위치 (주사인 경우)
  
  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.completedTime,
    required this.isCompleted,
    this.injectionLocation,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'injectionLocation': injectionLocation,
    };
  }
  
  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'],
      medicationId: json['medicationId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'])
          : null,
      isCompleted: json['isCompleted'],
      injectionLocation: json['injectionLocation'],
    );
  }
}
