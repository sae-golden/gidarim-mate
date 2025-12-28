// 심플 치료 사이클 모델 (기록 탭 개선 버전)
//
// 핵심 변경사항:
// - 기본값: 1차 채취 (0차 아님)
// - 전체 단계 항상 표시
// - 날짜 입력: 과배란/이식대기는 시작일만, 나머지는 당일
// - 추가 입력: 채취 개수, 동결 개수, 판정 결과 (모두 선택)

/// 단계 타입
enum SimpleStageType {
  stimulation, // 과배란
  retrieval, // 채취
  waiting, // 이식 대기
  transfer, // 이식
  result, // 판정
}

/// 단계 타입 확장
extension SimpleStageTypeExtension on SimpleStageType {
  String get name {
    switch (this) {
      case SimpleStageType.stimulation:
        return '과배란';
      case SimpleStageType.retrieval:
        return '채취';
      case SimpleStageType.waiting:
        return '이식 대기';
      case SimpleStageType.transfer:
        return '이식';
      case SimpleStageType.result:
        return '판정';
    }
  }

  String get emoji {
    switch (this) {
      case SimpleStageType.stimulation:
        return '💉';
      case SimpleStageType.retrieval:
        return '🥚';
      case SimpleStageType.waiting:
        return '⏳';
      case SimpleStageType.transfer:
        return '🎯';
      case SimpleStageType.result:
        return '🩺';
    }
  }

  /// 시작일만 사용하는 단계인지 (과배란, 이식대기)
  bool get usesStartDateOnly {
    return this == SimpleStageType.stimulation ||
        this == SimpleStageType.waiting;
  }

  /// 개수 입력이 있는 단계인지
  bool get hasCountInput {
    return this == SimpleStageType.retrieval || this == SimpleStageType.waiting;
  }
}

/// 단계 상태
enum SimpleStageStatus {
  completed, // 완료 ✅
  inProgress, // 진행중 ▶️
  pending, // 예정 ○
}

/// 단계 상태 확장
extension SimpleStageStatusExtension on SimpleStageStatus {
  String get icon {
    switch (this) {
      case SimpleStageStatus.completed:
        return '✅';
      case SimpleStageStatus.inProgress:
        return '▶️';
      case SimpleStageStatus.pending:
        return '○';
    }
  }

  String get label {
    switch (this) {
      case SimpleStageStatus.completed:
        return '완료';
      case SimpleStageStatus.inProgress:
        return '진행중';
      case SimpleStageStatus.pending:
        return '예정';
    }
  }
}

/// 판정 결과
enum ResultType {
  success, // 성공
  failure, // 실패
  unknown, // 아직 모름
}

/// 판정 결과 확장
extension ResultTypeExtension on ResultType {
  String get label {
    switch (this) {
      case ResultType.success:
        return '성공';
      case ResultType.failure:
        return '실패';
      case ResultType.unknown:
        return '아직 모름';
    }
  }

  String get emoji {
    switch (this) {
      case ResultType.success:
        return '🎉';
      case ResultType.failure:
        return '😢';
      case ResultType.unknown:
        return '🤔';
    }
  }
}

/// 치료 단계
class SimpleTreatmentStage {
  final SimpleStageType type;
  final DateTime? startDate; // 시작일 (과배란, 이식대기)
  final DateTime? date; // 당일 (채취, 이식, 판정)
  final int? count; // 개수 (채취: 난자수, 이식대기: 동결수)
  final ResultType? result; // 결과 (판정 단계만)

  SimpleTreatmentStage({
    required this.type,
    this.startDate,
    this.date,
    this.count,
    this.result,
  });

  /// 날짜가 입력되어 있는지
  bool get hasDate {
    if (type.usesStartDateOnly) {
      return startDate != null;
    }
    return date != null;
  }

  /// 표시용 날짜 문자열
  String get dateText {
    if (type.usesStartDateOnly) {
      if (startDate == null) return '-';
      return '${_formatDate(startDate!)} ~';
    } else {
      if (date == null) return '-';
      return _formatDate(date!);
    }
  }

  /// 개수 텍스트 (채취, 이식대기만)
  String? get countText {
    if (!type.hasCountInput || count == null) return null;
    return '$count개';
  }

  String _formatDate(DateTime d) {
    return '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  SimpleTreatmentStage copyWith({
    SimpleStageType? type,
    DateTime? startDate,
    DateTime? date,
    int? count,
    ResultType? result,
    bool clearStartDate = false,
    bool clearDate = false,
    bool clearCount = false,
    bool clearResult = false,
  }) {
    return SimpleTreatmentStage(
      type: type ?? this.type,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      date: clearDate ? null : (date ?? this.date),
      count: clearCount ? null : (count ?? this.count),
      result: clearResult ? null : (result ?? this.result),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'startDate': startDate?.toIso8601String(),
      'date': date?.toIso8601String(),
      'count': count,
      'result': result?.index,
    };
  }

  factory SimpleTreatmentStage.fromJson(Map<String, dynamic> json) {
    return SimpleTreatmentStage(
      type: SimpleStageType.values[json['type'] as int],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      count: json['count'] as int?,
      result:
          json['result'] != null ? ResultType.values[json['result'] as int] : null,
    );
  }
}

/// 심플 치료 사이클
class SimpleTreatmentCycle {
  final String id;
  final int cycleNumber; // 채취 회차 (1차, 2차...)
  final int attemptNumber; // 시도 회차 (1차 시도, 2차 시도...)
  final DateTime startDate; // 사이클 시작일
  final List<SimpleTreatmentStage> stages;

  SimpleTreatmentCycle({
    required this.id,
    required this.cycleNumber,
    this.attemptNumber = 1,
    required this.startDate,
    List<SimpleTreatmentStage>? stages,
  }) : stages = stages ?? _createEmptyStages();

  /// 빈 단계 리스트 생성
  static List<SimpleTreatmentStage> _createEmptyStages() {
    return SimpleStageType.values
        .map((type) => SimpleTreatmentStage(type: type))
        .toList();
  }

  /// 특정 타입의 단계 가져오기
  SimpleTreatmentStage getStage(SimpleStageType type) {
    return stages.firstWhere((s) => s.type == type);
  }

  /// 단계 상태 계산
  SimpleStageStatus getStageStatus(SimpleStageType type) {
    final stage = getStage(type);
    final stageIndex = SimpleStageType.values.indexOf(type);

    // 1. 다음 단계에 날짜가 있으면 → 완료
    if (stageIndex < SimpleStageType.values.length - 1) {
      final nextType = SimpleStageType.values[stageIndex + 1];
      final nextStage = getStage(nextType);
      if (nextStage.hasDate) {
        return SimpleStageStatus.completed;
      }
    }

    // 2. 판정 단계이고 결과가 있으면 → 완료
    if (type == SimpleStageType.result && stage.result != null) {
      return SimpleStageStatus.completed;
    }

    // 3. 현재 단계에 날짜가 있고, 오늘 이전이면 → 진행중
    if (stage.hasDate) {
      final stageDate = stage.startDate ?? stage.date;
      if (stageDate != null) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final stageDateOnly =
            DateTime(stageDate.year, stageDate.month, stageDate.day);
        if (stageDateOnly.isBefore(todayDate) ||
            stageDateOnly.isAtSameMomentAs(todayDate)) {
          return SimpleStageStatus.inProgress;
        }
      }
    }

    // 4. 그 외 → 예정
    return SimpleStageStatus.pending;
  }

  /// 현재 진행 중인 단계
  SimpleStageType? get currentStageType {
    for (final type in SimpleStageType.values.reversed) {
      if (getStageStatus(type) == SimpleStageStatus.inProgress) {
        return type;
      }
    }
    // 진행중인 단계가 없으면 첫 번째 예정 단계 반환
    for (final type in SimpleStageType.values) {
      if (getStageStatus(type) == SimpleStageStatus.pending) {
        return type;
      }
    }
    return null;
  }

  /// 현재 진행 상태 텍스트
  String get currentStatusText {
    final currentType = currentStageType;
    if (currentType == null) return '완료';

    final status = getStageStatus(currentType);
    if (status == SimpleStageStatus.inProgress) {
      return '${currentType.name} 중';
    }
    return '${currentType.name} 예정';
  }

  /// 채취 개수
  int? get retrievalCount => getStage(SimpleStageType.retrieval).count;

  /// 동결 잔여 개수
  int? get frozenCount => getStage(SimpleStageType.waiting).count;

  /// 이식 시도 횟수 (이식 날짜가 있으면 1회)
  int get transferAttemptCount =>
      getStage(SimpleStageType.transfer).hasDate ? attemptNumber : 0;

  /// 단계 업데이트
  SimpleTreatmentCycle updateStage(SimpleTreatmentStage newStage) {
    final newStages = stages.map((s) {
      if (s.type == newStage.type) {
        return newStage;
      }
      return s;
    }).toList();

    return SimpleTreatmentCycle(
      id: id,
      cycleNumber: cycleNumber,
      attemptNumber: attemptNumber,
      startDate: startDate,
      stages: newStages,
    );
  }

  SimpleTreatmentCycle copyWith({
    String? id,
    int? cycleNumber,
    int? attemptNumber,
    DateTime? startDate,
    List<SimpleTreatmentStage>? stages,
  }) {
    return SimpleTreatmentCycle(
      id: id ?? this.id,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      startDate: startDate ?? this.startDate,
      stages: stages ?? this.stages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cycleNumber': cycleNumber,
      'attemptNumber': attemptNumber,
      'startDate': startDate.toIso8601String(),
      'stages': stages.map((s) => s.toJson()).toList(),
    };
  }

  factory SimpleTreatmentCycle.fromJson(Map<String, dynamic> json) {
    return SimpleTreatmentCycle(
      id: json['id'] as String,
      cycleNumber: json['cycleNumber'] as int,
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      startDate: DateTime.parse(json['startDate'] as String),
      stages: (json['stages'] as List<dynamic>?)
              ?.map((s) =>
                  SimpleTreatmentStage.fromJson(s as Map<String, dynamic>))
              .toList() ??
          SimpleTreatmentCycle._createEmptyStages(),
    );
  }

  /// 새 사이클 생성 (기본값: 1차 채취)
  factory SimpleTreatmentCycle.create({int cycleNumber = 1}) {
    return SimpleTreatmentCycle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cycleNumber: cycleNumber,
      attemptNumber: 1,
      startDate: DateTime.now(),
    );
  }
}
