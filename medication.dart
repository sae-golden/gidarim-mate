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
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      time: json['time'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      type: MedicationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      pattern: json['pattern'],
      totalCount: json['totalCount'],
    );
  }
}

/// 약물 타입
enum MedicationType {
  injection, // 주사
  oral, // 경구약
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
