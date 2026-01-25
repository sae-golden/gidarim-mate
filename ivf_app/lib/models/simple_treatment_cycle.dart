// 타임라인 기반 치료 사이클 모델
//
// 핵심 구조:
// - TreatmentCycle: 사이클 정보 (시작일, 종료일, 결과, 시술 종류)
// - TreatmentEvent: 타임라인 이벤트 (과배란, 채취, 이식, 동결, 인공수정)
// - 이벤트는 동적으로 추가/삭제 가능

/// 시술 종류
enum TreatmentType {
  ivf, // 시험관
  iui, // 인공수정
}

/// 시술 종류 확장
extension TreatmentTypeExtension on TreatmentType {
  String get name {
    switch (this) {
      case TreatmentType.ivf:
        return '시험관';
      case TreatmentType.iui:
        return '인공수정';
    }
  }

  String get emoji {
    switch (this) {
      case TreatmentType.ivf:
        return '🥚';
      case TreatmentType.iui:
        return '💫';
    }
  }

  String get description {
    switch (this) {
      case TreatmentType.ivf:
        return '체외수정 (IVF)';
      case TreatmentType.iui:
        return '자궁내 인공수정 (IUI)';
    }
  }
}

/// 이벤트 타입 (5가지)
enum EventType {
  stimulation, // 과배란 💉
  retrieval, // 채취 🥚
  transfer, // 이식 🌱
  freezing, // 동결 ❄️
  insemination, // 인공수정 💫
}

/// 이벤트 타입 확장
extension EventTypeExtension on EventType {
  String get name {
    switch (this) {
      case EventType.stimulation:
        return '과배란';
      case EventType.retrieval:
        return '채취';
      case EventType.transfer:
        return '이식';
      case EventType.freezing:
        return '동결';
      case EventType.insemination:
        return '인공수정';
    }
  }

  /// 타임라인 표시용 설명
  String get displayText {
    switch (this) {
      case EventType.stimulation:
        return '과배란 중이에요';
      case EventType.retrieval:
        return '채취했어요';
      case EventType.transfer:
        return '이식했어요';
      case EventType.freezing:
        return '동결했어요';
      case EventType.insemination:
        return '인공수정 했어요';
    }
  }

  String get emoji {
    switch (this) {
      case EventType.stimulation:
        return '💉';
      case EventType.retrieval:
        return '🥚';
      case EventType.transfer:
        return '🌱';
      case EventType.freezing:
        return '❄️';
      case EventType.insemination:
        return '💫';
    }
  }

  String get description {
    switch (this) {
      case EventType.stimulation:
        return '과배란 주사 시작';
      case EventType.retrieval:
        return '난자 채취';
      case EventType.transfer:
        return '배아 이식';
      case EventType.freezing:
        return '배아 동결';
      case EventType.insemination:
        return '인공수정 시술';
    }
  }

  /// 개수 입력이 있는지
  bool get hasCountInput {
    return this == EventType.retrieval ||
        this == EventType.transfer ||
        this == EventType.freezing;
  }

  /// 배양일수 입력이 있는지 (이식, 동결)
  bool get hasEmbryoDayInput {
    return this == EventType.transfer || this == EventType.freezing;
  }

  /// 다중 배아 입력이 있는지 (이식, 동결)
  bool get hasMultipleEmbryoInput {
    return this == EventType.transfer || this == EventType.freezing;
  }

  /// 채취 상세 정보 입력이 있는지
  bool get hasRetrievalDetails {
    return this == EventType.retrieval;
  }

  /// 개수 라벨
  String get countLabel {
    switch (this) {
      case EventType.retrieval:
        return '채취 개수';
      case EventType.transfer:
        return '이식 개수';
      case EventType.freezing:
        return '동결 개수';
      default:
        return '개수';
    }
  }

  /// 순서 (타임라인 정렬용)
  int get order {
    switch (this) {
      case EventType.stimulation:
        return 0;
      case EventType.retrieval:
        return 1;
      case EventType.insemination:
        return 2;
      case EventType.transfer:
        return 3;
      case EventType.freezing:
        return 4;
    }
  }
}

/// 사이클 결과 (4가지)
enum CycleResult {
  success, // 🎉 좋은 소식이 있어요!
  frozen, // ❄️ 동결하고 기다리기로 했어요
  rest, // 💜 이번엔 쉬어가기로 했어요
  nextTime, // 💜 아쉽지만 다음을 준비해요
}

/// 사이클 결과 확장
extension CycleResultExtension on CycleResult {
  String get label {
    switch (this) {
      case CycleResult.success:
        return '좋은 소식이 있어요!';
      case CycleResult.frozen:
        return '동결하고 기다리기로 했어요';
      case CycleResult.rest:
        return '이번엔 쉬어가기로 했어요';
      case CycleResult.nextTime:
        return '아쉽지만 다음을 준비해요';
    }
  }

  String get emoji {
    switch (this) {
      case CycleResult.success:
        return '🎉';
      case CycleResult.frozen:
        return '❄️';
      case CycleResult.rest:
      case CycleResult.nextTime:
        return '💜';
    }
  }

  String get shortLabel {
    switch (this) {
      case CycleResult.success:
        return '성공';
      case CycleResult.frozen:
        return '동결 대기';
      case CycleResult.rest:
        return '쉬어가기';
      case CycleResult.nextTime:
        return '다음 준비';
    }
  }
}

/// 배아 정보 (배양일수 + 개수)
class EmbryoInfo {
  final int days; // 배양일수 (2~6일)
  final int count; // 개수

  const EmbryoInfo({
    required this.days,
    required this.count,
  });

  /// 표시용 텍스트 (예: "5일 2개")
  String get displayText => '$days일 $count개';

  Map<String, dynamic> toJson() => {
        'days': days,
        'count': count,
      };

  factory EmbryoInfo.fromJson(Map<String, dynamic> json) {
    return EmbryoInfo(
      days: json['days'] as int,
      count: json['count'] as int,
    );
  }

  EmbryoInfo copyWith({int? days, int? count}) {
    return EmbryoInfo(
      days: days ?? this.days,
      count: count ?? this.count,
    );
  }
}

/// 타임라인 이벤트
class TreatmentEvent {
  final String id;
  final EventType type;
  final DateTime date;
  final int? count; // 채취/이식/동결 개수 (호환성)
  final int? embryoDays; // 배양일수 (호환성, 단일 값)
  final String? memo; // 메모
  final DateTime createdAt;

  // 채취 상세 정보 (retrieval)
  final int? matureCount; // 성숙난자 (M2) 개수
  final int? fertilizedCount; // 수정된 배아 개수

  // 다중 배아 정보 (transfer, freezing)
  final List<EmbryoInfo>? embryos; // 배아 정보 리스트

  TreatmentEvent({
    required this.id,
    required this.type,
    required this.date,
    this.count,
    this.embryoDays,
    this.memo,
    this.matureCount,
    this.fertilizedCount,
    this.embryos,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 표시용 날짜 (MM.DD)
  String get dateText {
    return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 전체 날짜 (YYYY.MM.DD)
  String get fullDateText {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 개수 텍스트
  String? get countText {
    if (count == null) return null;
    return '$count개';
  }

  /// 배양일수 텍스트
  String? get embryoDaysText {
    if (embryoDays == null) return null;
    return '$embryoDays일';
  }

  /// 다중 배아 표시 텍스트 (예: "5일 2개, 3일 1개")
  String? get embryosDisplayText {
    if (embryos == null || embryos!.isEmpty) {
      // 호환성: 기존 단일 값 사용
      if (embryoDays != null && count != null) {
        return '$embryoDays일 배아 · $count개';
      }
      return null;
    }
    return embryos!.map((e) => e.displayText).join(', ');
  }

  /// 총 배아 개수 (다중 배아 또는 단일 count)
  int get totalEmbryoCount {
    if (embryos != null && embryos!.isNotEmpty) {
      return embryos!.fold(0, (sum, e) => sum + e.count);
    }
    return count ?? 0;
  }

  /// 채취 상세 표시 텍스트 (예: "12개 → 성숙 10개 → 수정 8개")
  String? get retrievalDetailText {
    if (type != EventType.retrieval || count == null) return null;

    final parts = <String>['$count개'];
    if (matureCount != null) {
      parts.add('성숙 $matureCount개');
    }
    if (fertilizedCount != null) {
      parts.add('수정 $fertilizedCount개');
    }
    return parts.join(' → ');
  }

  /// 타임라인 표시 텍스트 (기획서 규칙 적용)
  String get timelineDisplayText {
    switch (type) {
      case EventType.stimulation:
        return dateText;
      case EventType.retrieval:
        return retrievalDetailText != null
            ? '$dateText · $retrievalDetailText'
            : (count != null ? '$dateText · $count개' : dateText);
      case EventType.transfer:
      case EventType.freezing:
        final embryoText = embryosDisplayText;
        return embryoText != null ? '$dateText · $embryoText' : dateText;
      case EventType.insemination:
        return dateText;
    }
  }

  TreatmentEvent copyWith({
    String? id,
    EventType? type,
    DateTime? date,
    int? count,
    int? embryoDays,
    String? memo,
    int? matureCount,
    int? fertilizedCount,
    List<EmbryoInfo>? embryos,
    DateTime? createdAt,
    bool clearCount = false,
    bool clearEmbryoDays = false,
    bool clearMemo = false,
    bool clearMatureCount = false,
    bool clearFertilizedCount = false,
    bool clearEmbryos = false,
  }) {
    return TreatmentEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      count: clearCount ? null : (count ?? this.count),
      embryoDays: clearEmbryoDays ? null : (embryoDays ?? this.embryoDays),
      memo: clearMemo ? null : (memo ?? this.memo),
      matureCount: clearMatureCount ? null : (matureCount ?? this.matureCount),
      fertilizedCount:
          clearFertilizedCount ? null : (fertilizedCount ?? this.fertilizedCount),
      embryos: clearEmbryos ? null : (embryos ?? this.embryos),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'date': date.toIso8601String(),
      'count': count,
      'embryoDays': embryoDays,
      'memo': memo,
      'matureCount': matureCount,
      'fertilizedCount': fertilizedCount,
      'embryos': embryos?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TreatmentEvent.fromJson(Map<String, dynamic> json) {
    return TreatmentEvent(
      id: json['id'] as String,
      type: EventType.values[json['type'] as int],
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int?,
      embryoDays: json['embryoDays'] as int?,
      memo: json['memo'] as String?,
      matureCount: json['matureCount'] as int?,
      fertilizedCount: json['fertilizedCount'] as int?,
      embryos: (json['embryos'] as List<dynamic>?)
          ?.map((e) => EmbryoInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// 새 이벤트 생성
  factory TreatmentEvent.create({
    required EventType type,
    required DateTime date,
    int? count,
    int? embryoDays,
    String? memo,
    int? matureCount,
    int? fertilizedCount,
    List<EmbryoInfo>? embryos,
  }) {
    return TreatmentEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      date: date,
      count: count,
      embryoDays: embryoDays,
      memo: memo,
      matureCount: matureCount,
      fertilizedCount: fertilizedCount,
      embryos: embryos,
    );
  }
}

/// 치료 사이클
class TreatmentCycle {
  final String id;
  final TreatmentType type; // 시술 종류 (시험관/인공수정)
  final int cycleNumber; // N차 시도
  final bool isNaturalCycle; // 자연주기 여부 (인공수정만)
  final bool isFrozenTransfer; // 동결배아 이식 여부 (시험관만)
  final DateTime startDate; // 시작일
  final DateTime? endDate; // 종료일
  final List<TreatmentEvent> events; // 타임라인 이벤트들
  final CycleResult? result; // 사이클 결과

  TreatmentCycle({
    required this.id,
    this.type = TreatmentType.ivf,
    required this.cycleNumber,
    this.isNaturalCycle = false,
    this.isFrozenTransfer = false,
    required this.startDate,
    this.endDate,
    List<TreatmentEvent>? events,
    this.result,
  }) : events = events ?? [];

  /// 시작일 텍스트
  String get startDateText {
    return '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}';
  }

  /// 종료일 텍스트
  String? get endDateText {
    if (endDate == null) return null;
    return '${endDate!.year}.${endDate!.month.toString().padLeft(2, '0')}.${endDate!.day.toString().padLeft(2, '0')}';
  }

  /// 헤더 표시용 제목 (예: "1차 채취", "2차 인공수정 · 자연주기")
  String get headerTitle {
    if (type == TreatmentType.iui) {
      final suffix = isNaturalCycle ? ' · 자연주기' : '';
      return '$cycleNumber차 인공수정$suffix';
    } else {
      final suffix = isFrozenTransfer ? ' · 동결배아' : '';
      return '$cycleNumber차 채취$suffix';
    }
  }

  /// 헤더 표시용 짧은 제목 (예: "1차 채취", "2차 인공수정")
  String get shortTitle {
    if (type == TreatmentType.iui) {
      return '$cycleNumber차 인공수정';
    } else {
      return '$cycleNumber차 채취';
    }
  }

  /// 새 채취/시도 시작 버튼 텍스트
  String get newCycleButtonText {
    if (type == TreatmentType.iui) {
      return '💫 새로운 시도 시작하기';
    } else {
      return '🥚 새로운 채취 시작하기';
    }
  }

  /// 사이클이 완료되었는지
  bool get isCompleted => result != null;

  /// 사이클이 진행 중인지
  bool get isOngoing => result == null;

  /// 이벤트가 있는지
  bool get hasEvents => events.isNotEmpty;

  /// 날짜순으로 정렬된 이벤트
  List<TreatmentEvent> get sortedEvents {
    final sorted = List<TreatmentEvent>.from(events);
    sorted.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.type.order.compareTo(b.type.order);
    });
    return sorted;
  }

  /// 마지막 이벤트
  TreatmentEvent? get lastEvent {
    if (events.isEmpty) return null;
    return sortedEvents.last;
  }

  /// 시술 종류에 따라 사용 가능한 이벤트 타입 목록
  List<EventType> get availableEventTypes {
    if (type == TreatmentType.iui) {
      // 인공수정
      if (isNaturalCycle) {
        // 자연주기: 과배란 없음
        return [EventType.insemination];
      } else {
        // 과배란 주기
        return [EventType.stimulation, EventType.insemination];
      }
    } else {
      // 시험관
      if (isFrozenTransfer) {
        // 동결배아 이식: 채취 없음
        return [EventType.stimulation, EventType.transfer];
      } else {
        return [
          EventType.stimulation,
          EventType.retrieval,
          EventType.transfer,
          EventType.freezing
        ];
      }
    }
  }

  /// 다음 예상 단계 (안내 메시지용)
  String? get nextStepHint {
    if (result != null) return null;

    final eventTypes = events.map((e) => e.type).toSet();

    if (type == TreatmentType.iui) {
      // 인공수정
      if (!isNaturalCycle && !eventTypes.contains(EventType.stimulation)) {
        return '과배란 주사를 시작하셨나요?';
      }
      if (!eventTypes.contains(EventType.insemination)) {
        return '인공수정 일정이 잡히셨나요?';
      }
      return '이번 시도는 어떻게 되셨나요?';
    } else {
      // 시험관
      if (!eventTypes.contains(EventType.stimulation)) {
        return '과배란 주사를 시작하셨나요?';
      }
      if (!isFrozenTransfer && !eventTypes.contains(EventType.retrieval)) {
        return '채취 일정이 잡히셨나요?';
      }
      if (!eventTypes.contains(EventType.transfer) &&
          !eventTypes.contains(EventType.freezing)) {
        return '이식 또는 동결 예정이신가요?';
      }
      return '이번 사이클은 어떻게 되셨나요?';
    }
  }

  /// 통계: 채취 개수
  int? get totalRetrievalCount {
    final retrievals = events.where((e) => e.type == EventType.retrieval);
    if (retrievals.isEmpty) return null;
    int total = 0;
    for (final e in retrievals) {
      if (e.count != null) total += e.count!;
    }
    return total > 0 ? total : null;
  }

  /// 통계: 이식 개수
  int? get totalTransferCount {
    final transfers = events.where((e) => e.type == EventType.transfer);
    if (transfers.isEmpty) return null;
    int total = 0;
    for (final e in transfers) {
      if (e.count != null) total += e.count!;
    }
    return total > 0 ? total : null;
  }

  /// 통계: 동결 개수
  int? get totalFreezeCount {
    final freezes = events.where((e) => e.type == EventType.freezing);
    if (freezes.isEmpty) return null;
    int total = 0;
    for (final e in freezes) {
      if (e.count != null) total += e.count!;
    }
    return total > 0 ? total : null;
  }

  /// 이벤트 추가
  TreatmentCycle addEvent(TreatmentEvent event) {
    return copyWith(events: [...events, event]);
  }

  /// 이벤트 업데이트
  TreatmentCycle updateEvent(TreatmentEvent updatedEvent) {
    final newEvents = events.map((e) {
      if (e.id == updatedEvent.id) {
        return updatedEvent;
      }
      return e;
    }).toList();
    return copyWith(events: newEvents);
  }

  /// 이벤트 삭제
  TreatmentCycle removeEvent(String eventId) {
    final newEvents = events.where((e) => e.id != eventId).toList();
    return copyWith(events: newEvents);
  }

  TreatmentCycle copyWith({
    String? id,
    TreatmentType? type,
    int? cycleNumber,
    bool? isNaturalCycle,
    bool? isFrozenTransfer,
    DateTime? startDate,
    DateTime? endDate,
    List<TreatmentEvent>? events,
    CycleResult? result,
    bool clearEndDate = false,
    bool clearResult = false,
  }) {
    return TreatmentCycle(
      id: id ?? this.id,
      type: type ?? this.type,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      isNaturalCycle: isNaturalCycle ?? this.isNaturalCycle,
      isFrozenTransfer: isFrozenTransfer ?? this.isFrozenTransfer,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      events: events ?? this.events,
      result: clearResult ? null : (result ?? this.result),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'cycleNumber': cycleNumber,
      'isNaturalCycle': isNaturalCycle,
      'isFrozenTransfer': isFrozenTransfer,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'events': events.map((e) => e.toJson()).toList(),
      'result': result?.index,
    };
  }

  factory TreatmentCycle.fromJson(Map<String, dynamic> json) {
    return TreatmentCycle(
      id: json['id'] as String,
      type: json['type'] != null
          ? TreatmentType.values[json['type'] as int]
          : TreatmentType.ivf,
      cycleNumber: json['cycleNumber'] as int,
      isNaturalCycle: json['isNaturalCycle'] as bool? ?? false,
      isFrozenTransfer: json['isFrozenTransfer'] as bool? ?? false,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => TreatmentEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      result: json['result'] != null
          ? CycleResult.values[json['result'] as int]
          : null,
    );
  }

  /// 새 사이클 생성
  factory TreatmentCycle.create({
    TreatmentType type = TreatmentType.ivf,
    int cycleNumber = 1,
    bool isNaturalCycle = false,
    bool isFrozenTransfer = false,
    DateTime? startDate,
  }) {
    return TreatmentCycle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      cycleNumber: cycleNumber,
      isNaturalCycle: isNaturalCycle,
      isFrozenTransfer: isFrozenTransfer,
      startDate: startDate ?? DateTime.now(),
    );
  }
}

// ============================================================
// 하위 호환성을 위한 레거시 타입들 (기존 코드와 호환)
// ============================================================

/// @deprecated Use EventType instead
typedef SimpleStageType = EventType;

/// @deprecated Use CycleResult instead
typedef CycleResultType = CycleResult;

/// 레거시 확장 (기존 코드 호환용)
extension SimpleStageTypeExtension on EventType {
  /// @deprecated
  bool get usesStartDateOnly => false;

  /// @deprecated
  bool get hasCultureDayInput => hasEmbryoDayInput;
}

/// 레거시 확장 (기존 코드 호환용)
extension CycleResultTypeExtension on CycleResult {
  /// @deprecated - Use label instead
  String get legacyLabel => label;
}

// ============================================================
// 피검사 관련 모델
// ============================================================

/// 피검사 수치 타입
enum BloodTestType {
  e2,    // 에스트라디올
  fsh,   // 난포자극호르몬
  lh,    // 황체형성호르몬
  p4,    // 프로게스테론
  hcg,   // β-hCG
  amh,   // 난소 예비력
  tsh,   // 갑상선
  vitD,  // 비타민D
}

/// 피검사 수치 타입 확장
extension BloodTestTypeExtension on BloodTestType {
  String get displayName {
    switch (this) {
      case BloodTestType.e2: return '에스트로겐';
      case BloodTestType.fsh: return '난포자극호르몬';
      case BloodTestType.lh: return '황체형성호르몬';
      case BloodTestType.p4: return '황체호르몬';
      case BloodTestType.hcg: return '임신호르몬';
      case BloodTestType.amh: return '난소예비력';
      case BloodTestType.tsh: return '갑상선호르몬';
      case BloodTestType.vitD: return '비타민D';
    }
  }

  /// 영문 약어 (기존 데이터 호환용)
  String get shortName {
    switch (this) {
      case BloodTestType.e2: return 'E2';
      case BloodTestType.fsh: return 'FSH';
      case BloodTestType.lh: return 'LH';
      case BloodTestType.p4: return 'P4';
      case BloodTestType.hcg: return 'β-hCG';
      case BloodTestType.amh: return 'AMH';
      case BloodTestType.tsh: return 'TSH';
      case BloodTestType.vitD: return 'VitD';
    }
  }

  String get description {
    switch (this) {
      case BloodTestType.e2: return '난포 성장 확인';
      case BloodTestType.fsh: return '난포자극호르몬';
      case BloodTestType.lh: return '배란 징후 확인';
      case BloodTestType.p4: return '황체 기능';
      case BloodTestType.hcg: return '임신 확인 수치';
      case BloodTestType.amh: return '난소 예비력';
      case BloodTestType.tsh: return '갑상선 기능';
      case BloodTestType.vitD: return '비타민D 수치';
    }
  }

  String get unit {
    switch (this) {
      case BloodTestType.e2: return 'pg/mL';
      case BloodTestType.fsh: return 'mIU/mL';
      case BloodTestType.lh: return 'mIU/mL';
      case BloodTestType.p4: return 'ng/mL';
      case BloodTestType.hcg: return 'mIU/mL';
      case BloodTestType.amh: return 'ng/mL';
      case BloodTestType.tsh: return 'mIU/L';
      case BloodTestType.vitD: return 'ng/mL';
    }
  }

  String get emoji {
    switch (this) {
      case BloodTestType.e2: return '🩸';
      case BloodTestType.fsh: return '🧬';
      case BloodTestType.lh: return '📈';
      case BloodTestType.p4: return '🌡️';
      case BloodTestType.hcg: return '🤰';
      case BloodTestType.amh: return '🥚';
      case BloodTestType.tsh: return '🦋';
      case BloodTestType.vitD: return '☀️';
    }
  }
}

/// 피검사 기록
class BloodTest {
  final String id;
  final String cycleId;
  final DateTime date;
  final double? e2;       // 에스트라디올
  final double? fsh;      // 난포자극호르몬
  final double? lh;       // 황체형성호르몬
  final double? p4;       // 프로게스테론
  final double? hcg;      // β-hCG
  final double? amh;      // 난소 예비력
  final double? tsh;      // 갑상선
  final double? vitD;     // 비타민D
  final DateTime createdAt;

  BloodTest({
    required this.id,
    required this.cycleId,
    required this.date,
    this.e2,
    this.fsh,
    this.lh,
    this.p4,
    this.hcg,
    this.amh,
    this.tsh,
    this.vitD,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 표시용 날짜 (MM.DD)
  String get dateText {
    return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 전체 날짜 (YYYY.MM.DD)
  String get fullDateText {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 값이 있는 수치들만 가져오기
  Map<BloodTestType, double> get values {
    final result = <BloodTestType, double>{};
    if (e2 != null) result[BloodTestType.e2] = e2!;
    if (fsh != null) result[BloodTestType.fsh] = fsh!;
    if (lh != null) result[BloodTestType.lh] = lh!;
    if (p4 != null) result[BloodTestType.p4] = p4!;
    if (hcg != null) result[BloodTestType.hcg] = hcg!;
    if (amh != null) result[BloodTestType.amh] = amh!;
    if (tsh != null) result[BloodTestType.tsh] = tsh!;
    if (vitD != null) result[BloodTestType.vitD] = vitD!;
    return result;
  }

  /// 요약 텍스트 (타임라인 표시용) - 한글화
  String get summaryText {
    final parts = <String>[];
    if (e2 != null) parts.add('에스트로겐: ${e2!.toStringAsFixed(0)}');
    if (fsh != null) parts.add('난포자극호르몬: ${fsh!.toStringAsFixed(1)}');
    if (lh != null) parts.add('황체형성호르몬: ${lh!.toStringAsFixed(1)}');
    if (p4 != null) parts.add('황체호르몬: ${p4!.toStringAsFixed(1)}');
    if (hcg != null) parts.add('임신호르몬: ${hcg!.toStringAsFixed(0)}');
    if (amh != null) parts.add('난소예비력: ${amh!.toStringAsFixed(2)}');
    if (tsh != null) parts.add('갑상선호르몬: ${tsh!.toStringAsFixed(2)}');
    if (vitD != null) parts.add('비타민D: ${vitD!.toStringAsFixed(0)}');

    if (parts.isEmpty) return '';
    if (parts.length <= 2) return parts.join(' · ');
    return '${parts.take(2).join(' · ')} 외 ${parts.length - 2}개';
  }

  /// 값이 하나라도 있는지 확인
  bool get hasAnyValue => values.isNotEmpty;

  BloodTest copyWith({
    String? id,
    String? cycleId,
    DateTime? date,
    double? e2,
    double? fsh,
    double? lh,
    double? p4,
    double? hcg,
    double? amh,
    double? tsh,
    double? vitD,
    DateTime? createdAt,
    bool clearE2 = false,
    bool clearFsh = false,
    bool clearLh = false,
    bool clearP4 = false,
    bool clearHcg = false,
    bool clearAmh = false,
    bool clearTsh = false,
    bool clearVitD = false,
  }) {
    return BloodTest(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      date: date ?? this.date,
      e2: clearE2 ? null : (e2 ?? this.e2),
      fsh: clearFsh ? null : (fsh ?? this.fsh),
      lh: clearLh ? null : (lh ?? this.lh),
      p4: clearP4 ? null : (p4 ?? this.p4),
      hcg: clearHcg ? null : (hcg ?? this.hcg),
      amh: clearAmh ? null : (amh ?? this.amh),
      tsh: clearTsh ? null : (tsh ?? this.tsh),
      vitD: clearVitD ? null : (vitD ?? this.vitD),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cycleId': cycleId,
      'date': date.toIso8601String(),
      'e2': e2,
      'fsh': fsh,
      'lh': lh,
      'p4': p4,
      'hcg': hcg,
      'amh': amh,
      'tsh': tsh,
      'vitD': vitD,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BloodTest.fromJson(Map<String, dynamic> json) {
    return BloodTest(
      id: json['id'] as String,
      cycleId: json['cycleId'] as String,
      date: DateTime.parse(json['date'] as String),
      e2: (json['e2'] as num?)?.toDouble(),
      fsh: (json['fsh'] as num?)?.toDouble(),
      lh: (json['lh'] as num?)?.toDouble(),
      p4: (json['p4'] as num?)?.toDouble(),
      hcg: (json['hcg'] as num?)?.toDouble(),
      amh: (json['amh'] as num?)?.toDouble(),
      tsh: (json['tsh'] as num?)?.toDouble(),
      vitD: (json['vitD'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// 새 피검사 기록 생성
  factory BloodTest.create({
    required String cycleId,
    required DateTime date,
    double? e2,
    double? fsh,
    double? lh,
    double? p4,
    double? hcg,
    double? amh,
    double? tsh,
    double? vitD,
  }) {
    return BloodTest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: cycleId,
      date: date,
      e2: e2,
      fsh: fsh,
      lh: lh,
      p4: p4,
      hcg: hcg,
      amh: amh,
      tsh: tsh,
      vitD: vitD,
    );
  }
}

// ============================================================
// 하위 호환성을 위한 레거시 타입들 (기존 코드와 호환)
// ============================================================

/// @deprecated Use TreatmentEvent instead
class SimpleTreatmentStage {
  final EventType type;
  final DateTime? startDate;
  final DateTime? date;
  final int? count;
  final String? memo;
  final int? cultureDay;

  SimpleTreatmentStage({
    required this.type,
    this.startDate,
    this.date,
    this.count,
    this.memo,
    this.cultureDay,
  });

  bool get hasDate => date != null || startDate != null;

  String get dateText {
    if (date != null) {
      return '${date!.month.toString().padLeft(2, '0')}.${date!.day.toString().padLeft(2, '0')}';
    }
    if (startDate != null) {
      return '${startDate!.month.toString().padLeft(2, '0')}.${startDate!.day.toString().padLeft(2, '0')} ~';
    }
    return '-';
  }

  SimpleTreatmentStage copyWith({
    EventType? type,
    DateTime? startDate,
    DateTime? date,
    int? count,
    String? memo,
    int? cultureDay,
    bool clearStartDate = false,
    bool clearDate = false,
    bool clearCount = false,
    bool clearMemo = false,
    bool clearCultureDay = false,
  }) {
    return SimpleTreatmentStage(
      type: type ?? this.type,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      date: clearDate ? null : (date ?? this.date),
      count: clearCount ? null : (count ?? this.count),
      memo: clearMemo ? null : (memo ?? this.memo),
      cultureDay: clearCultureDay ? null : (cultureDay ?? this.cultureDay),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'startDate': startDate?.toIso8601String(),
        'date': date?.toIso8601String(),
        'count': count,
        'memo': memo,
        'cultureDay': cultureDay,
      };

  factory SimpleTreatmentStage.fromJson(Map<String, dynamic> json) {
    return SimpleTreatmentStage(
      type: EventType.values[json['type'] as int],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      count: json['count'] as int?,
      memo: json['memo'] as String?,
      cultureDay: json['cultureDay'] as int?,
    );
  }
}

/// @deprecated Use TreatmentCycle instead
class SimpleTreatmentCycle {
  final String id;
  final int cycleNumber;
  final int attemptNumber;
  final DateTime startDate;
  final DateTime? endDate;
  final CycleResult? cycleResult;
  final List<SimpleTreatmentStage> stages;

  SimpleTreatmentCycle({
    required this.id,
    required this.cycleNumber,
    this.attemptNumber = 1,
    required this.startDate,
    this.endDate,
    this.cycleResult,
    List<SimpleTreatmentStage>? stages,
  }) : stages = stages ?? _createEmptyStages();

  static List<SimpleTreatmentStage> _createEmptyStages() {
    return EventType.values
        .map((type) => SimpleTreatmentStage(type: type))
        .toList();
  }

  SimpleTreatmentStage getStage(EventType type) {
    return stages.firstWhere((s) => s.type == type,
        orElse: () => SimpleTreatmentStage(type: type));
  }

  int? get retrievalCount => getStage(EventType.retrieval).count;
  int? get frozenCount => getStage(EventType.freezing).count;

  SimpleTreatmentCycle updateStage(SimpleTreatmentStage newStage) {
    final newStages = stages.map((s) {
      if (s.type == newStage.type) return newStage;
      return s;
    }).toList();
    return SimpleTreatmentCycle(
      id: id,
      cycleNumber: cycleNumber,
      attemptNumber: attemptNumber,
      startDate: startDate,
      endDate: endDate,
      cycleResult: cycleResult,
      stages: newStages,
    );
  }

  SimpleTreatmentCycle copyWith({
    String? id,
    int? cycleNumber,
    int? attemptNumber,
    DateTime? startDate,
    DateTime? endDate,
    CycleResult? cycleResult,
    List<SimpleTreatmentStage>? stages,
    bool clearEndDate = false,
    bool clearCycleResult = false,
  }) {
    return SimpleTreatmentCycle(
      id: id ?? this.id,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      cycleResult: clearCycleResult ? null : (cycleResult ?? this.cycleResult),
      stages: stages ?? this.stages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cycleNumber': cycleNumber,
        'attemptNumber': attemptNumber,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'cycleResult': cycleResult?.index,
        'stages': stages.map((s) => s.toJson()).toList(),
      };

  factory SimpleTreatmentCycle.fromJson(Map<String, dynamic> json) {
    return SimpleTreatmentCycle(
      id: json['id'] as String,
      cycleNumber: json['cycleNumber'] as int,
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      cycleResult: json['cycleResult'] != null
          ? CycleResult.values[json['cycleResult'] as int]
          : null,
      stages: (json['stages'] as List<dynamic>?)
              ?.map(
                  (s) => SimpleTreatmentStage.fromJson(s as Map<String, dynamic>))
              .toList() ??
          SimpleTreatmentCycle._createEmptyStages(),
    );
  }

  factory SimpleTreatmentCycle.create({int cycleNumber = 1}) {
    return SimpleTreatmentCycle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cycleNumber: cycleNumber,
      attemptNumber: 1,
      startDate: DateTime.now(),
    );
  }

  /// 레거시 → 새 모델 변환
  TreatmentCycle toNewModel() {
    final events = <TreatmentEvent>[];

    for (final stage in stages) {
      if (stage.hasDate) {
        events.add(TreatmentEvent(
          id: '${id}_${stage.type.index}',
          type: stage.type,
          date: stage.date ?? stage.startDate!,
          count: stage.count,
          embryoDays: stage.cultureDay,
          memo: stage.memo,
        ));
      }
    }

    return TreatmentCycle(
      id: id,
      cycleNumber: cycleNumber,
      startDate: startDate,
      endDate: endDate,
      events: events,
      result: cycleResult,
    );
  }
}
