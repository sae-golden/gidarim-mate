import 'treatment_stage.dart';

/// 단계 상태
enum StageStatus {
  completed, // 완료
  inProgress, // 진행중
  pending, // 예정
}

/// 이식 타입
enum TransferType {
  fresh,  // 신선이식
  frozen, // 동결이식
}

extension TransferTypeExtension on TransferType {
  String get displayName {
    switch (this) {
      case TransferType.fresh:
        return '신선이식';
      case TransferType.frozen:
        return '동결이식';
    }
  }

  String get shortName {
    switch (this) {
      case TransferType.fresh:
        return '신선';
      case TransferType.frozen:
        return '동결';
    }
  }

  String get emoji {
    switch (this) {
      case TransferType.fresh:
        return '🌱';
      case TransferType.frozen:
        return '❄️';
    }
  }
}

/// 이식 결과 상태
enum TransferResultStatus {
  inProgress, // 진행중 (판정 전)
  success,    // 성공 (임신)
  fail,       // 실패
}

extension TransferResultStatusExtension on TransferResultStatus {
  String get displayName {
    switch (this) {
      case TransferResultStatus.inProgress:
        return '진행중';
      case TransferResultStatus.success:
        return '성공';
      case TransferResultStatus.fail:
        return '실패';
    }
  }

  String get emoji {
    switch (this) {
      case TransferResultStatus.inProgress:
        return '⏳';
      case TransferResultStatus.success:
        return '🎉';
      case TransferResultStatus.fail:
        return '❌';
    }
  }
}

/// 채취 사이클 (1차 채취, 2차 채취...)
class RetrievalCycle {
  final String id;
  final int cycleNumber;           // 1차, 2차...
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;             // 현재 진행 중인 사이클인지

  // 채취 관련 데이터
  final StimulationData? stimulation;
  final RetrievalData? retrieval;
  final List<LabResult> labResults; // 수정, 배양 결과

  // 동결배아 관리
  final int totalFrozenEmbryos;    // 총 동결 배아 수
  final int usedFrozenEmbryos;     // 사용한 동결 배아 수

  // 이식 기록들
  final List<TransferAttempt> transfers;

  final String? memo;

  RetrievalCycle({
    required this.id,
    required this.cycleNumber,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.stimulation,
    this.retrieval,
    this.labResults = const [],
    this.totalFrozenEmbryos = 0,
    this.usedFrozenEmbryos = 0,
    this.transfers = const [],
    this.memo,
  });

  /// 남은 동결배아 수
  int get remainingEmbryos => totalFrozenEmbryos - usedFrozenEmbryos;

  /// 현재 진행 중인 이식
  TransferAttempt? get currentTransfer {
    return transfers.cast<TransferAttempt?>().firstWhere(
      (t) => t?.status == TransferResultStatus.inProgress,
      orElse: () => null,
    );
  }

  /// 마지막 이식
  TransferAttempt? get lastTransfer {
    return transfers.isEmpty ? null : transfers.last;
  }

  /// 동결이식 횟수
  int get frozenTransferCount {
    return transfers.where((t) => t.type == TransferType.frozen).length;
  }

  /// 결과 요약 문자열
  String get resultSummary {
    final parts = <String>[];
    if (retrieval != null) {
      parts.add('채취 ${retrieval!.totalEggs}개');
    }

    final day5 = labResults.cast<LabResult?>().firstWhere(
      (r) => r?.type == LabResultType.day5,
      orElse: () => null,
    );
    if (day5 != null) {
      parts.add('배반포 ${day5.count}개');
    }

    if (totalFrozenEmbryos > 0) {
      parts.add('동결 ${remainingEmbryos}개');
    }

    return parts.isEmpty ? '데이터 없음' : parts.join(' → ');
  }

  /// 이식 기록 요약 문자열
  String get transferSummary {
    if (transfers.isEmpty) return '';

    final parts = <String>[];
    for (final t in transfers) {
      final typeStr = t.type == TransferType.fresh ? '신선' : '동결${t.frozenAttemptNumber ?? 1}차';
      final statusEmoji = t.status.emoji;
      parts.add('$typeStr $statusEmoji');
    }
    return parts.join(' → ');
  }

  RetrievalCycle copyWith({
    String? id,
    int? cycleNumber,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    StimulationData? stimulation,
    RetrievalData? retrieval,
    List<LabResult>? labResults,
    int? totalFrozenEmbryos,
    int? usedFrozenEmbryos,
    List<TransferAttempt>? transfers,
    String? memo,
  }) {
    return RetrievalCycle(
      id: id ?? this.id,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      stimulation: stimulation ?? this.stimulation,
      retrieval: retrieval ?? this.retrieval,
      labResults: labResults ?? this.labResults,
      totalFrozenEmbryos: totalFrozenEmbryos ?? this.totalFrozenEmbryos,
      usedFrozenEmbryos: usedFrozenEmbryos ?? this.usedFrozenEmbryos,
      transfers: transfers ?? this.transfers,
      memo: memo ?? this.memo,
    );
  }
}

/// 이식 시도 기록
class TransferAttempt {
  final String id;
  final TransferType type;         // 신선 / 동결
  final int? frozenAttemptNumber;  // 동결 1차, 2차... (동결이식인 경우)
  final DateTime date;
  final TransferResultStatus status;
  final TransferData? transferData; // 이식 데이터
  final ResultData? resultData;     // 판정 결과
  final String? memo;

  TransferAttempt({
    required this.id,
    required this.type,
    this.frozenAttemptNumber,
    required this.date,
    this.status = TransferResultStatus.inProgress,
    this.transferData,
    this.resultData,
    this.memo,
  });

  /// 표시용 이름 (신선이식, 동결 1차, 동결 2차...)
  String get displayName {
    if (type == TransferType.fresh) {
      return '신선이식';
    }
    return '동결 ${frozenAttemptNumber ?? 1}차';
  }

  TransferAttempt copyWith({
    String? id,
    TransferType? type,
    int? frozenAttemptNumber,
    DateTime? date,
    TransferResultStatus? status,
    TransferData? transferData,
    ResultData? resultData,
    String? memo,
  }) {
    return TransferAttempt(
      id: id ?? this.id,
      type: type ?? this.type,
      frozenAttemptNumber: frozenAttemptNumber ?? this.frozenAttemptNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      transferData: transferData ?? this.transferData,
      resultData: resultData ?? this.resultData,
      memo: memo ?? this.memo,
    );
  }
}

/// 치료 사이클 (1회 시도) - 기존 호환성 유지
class TreatmentCycle {
  final String id;
  final int cycleNumber; // 시도 회차
  final DateTime startDate;
  final DateTime? endDate;
  final List<CycleStage> stages;
  final String? memo;

  TreatmentCycle({
    required this.id,
    required this.cycleNumber,
    required this.startDate,
    this.endDate,
    required this.stages,
    this.memo,
  });

  /// 현재 진행중인 단계 찾기
  CycleStage? get currentStage {
    return stages.cast<CycleStage?>().firstWhere(
          (s) => s?.status == StageStatus.inProgress,
          orElse: () => null,
        );
  }

  /// 결과 요약 (채취 → 수정 → Day3 → 배반포 → 동결)
  String get resultSummary {
    final retrieval = getStageData<RetrievalData>(TreatmentStage.retrieval);
    final waiting = getStageData<WaitingData>(TreatmentStage.waiting);

    final parts = <String>[];
    if (retrieval != null) {
      parts.add('채취 ${retrieval.totalEggs}');
    }

    if (waiting != null) {
      final fertilization = waiting.getResult(LabResultType.fertilization);
      final day3 = waiting.getResult(LabResultType.day3);
      final day5 = waiting.getResult(LabResultType.day5);
      final frozen = waiting.getResult(LabResultType.frozen);

      if (fertilization != null) {
        parts.add('수정 ${fertilization.count}');
      }
      if (day3 != null) {
        parts.add('Day3 ${day3.count}');
      }
      if (day5 != null) {
        parts.add('배반포 ${day5.count}');
      }
      if (frozen != null) {
        parts.add('동결 ${frozen.count}');
      }
    }

    return parts.isEmpty ? '데이터 없음' : parts.join(' → ');
  }

  /// 특정 단계 데이터 가져오기
  T? getStageData<T>(TreatmentStage stage) {
    final cycleStage = stages.cast<CycleStage?>().firstWhere(
          (s) => s?.stage == stage,
          orElse: () => null,
        );
    return cycleStage?.data as T?;
  }

  /// D-Day 계산 (이식일 기준)
  int? get dDay {
    final transfer = stages.cast<CycleStage?>().firstWhere(
          (s) => s?.stage == TreatmentStage.transfer,
          orElse: () => null,
        );
    if (transfer?.startDate != null) {
      return transfer!.startDate!.difference(DateTime.now()).inDays;
    }
    return null;
  }

  TreatmentCycle copyWith({
    String? id,
    int? cycleNumber,
    DateTime? startDate,
    DateTime? endDate,
    List<CycleStage>? stages,
    String? memo,
  }) {
    return TreatmentCycle(
      id: id ?? this.id,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      stages: stages ?? this.stages,
      memo: memo ?? this.memo,
    );
  }
}

/// 사이클 내 단계
class CycleStage {
  final TreatmentStage stage;
  final StageStatus? _manualStatus; // 수동 설정 상태 (null이면 자동 계산)
  final DateTime? startDate;
  final DateTime? endDate;
  final dynamic data; // 단계별 상세 데이터
  final String? memo;

  CycleStage({
    required this.stage,
    StageStatus? status,
    this.startDate,
    this.endDate,
    this.data,
    this.memo,
  }) : _manualStatus = status;

  /// 단계 정보
  TreatmentStageInfo get info => TreatmentStageInfo.stageInfo[stage]!;

  /// 결과가 입력되어 있는지 확인
  bool get hasResult {
    switch (stage) {
      case TreatmentStage.stimulation:
        return data != null && data is StimulationData;
      case TreatmentStage.retrieval:
        return data != null && data is RetrievalData;
      case TreatmentStage.waiting:
        final waitingData = data as WaitingData?;
        return waitingData != null && waitingData.results.isNotEmpty;
      case TreatmentStage.transfer:
        return data != null && data is TransferData;
      case TreatmentStage.result:
        final resultData = data as ResultData?;
        return resultData != null && resultData.isPregnant != null;
    }
  }

  /// 자동 계산된 상태 (날짜 기반)
  StageStatus get status {
    // 수동 설정된 상태가 있으면 우선 사용
    if (_manualStatus != null) {
      return _manualStatus;
    }

    return calculatedStatus;
  }

  /// 날짜 기준 자동 상태 계산
  StageStatus get calculatedStatus {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 이식 대기(waiting)는 특별 처리: 결과가 있으면 완료, 시작했으면 완료 (진행중 상태 없음)
    if (stage == TreatmentStage.waiting) {
      if (hasResult) {
        return StageStatus.completed;
      }
      if (startDate != null) {
        final startDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);
        if (startDateOnly.isBefore(todayDate) || startDateOnly.isAtSameMomentAs(todayDate)) {
          return StageStatus.completed;
        }
      }
      return StageStatus.pending;
    }

    // 1. 결과가 입력되어 있으면 → 완료
    if (hasResult) {
      // 단, result 단계는 isPregnant가 설정되어야 완료
      if (stage == TreatmentStage.result) {
        final resultData = data as ResultData?;
        if (resultData?.isPregnant != null) {
          return StageStatus.completed;
        }
      } else {
        return StageStatus.completed;
      }
    }

    // 2. 시작 날짜가 없으면 → 예정
    if (startDate == null) {
      return StageStatus.pending;
    }

    final startDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);

    // 3. 종료 날짜가 있고 종료일이 지났으면 → 완료
    if (endDate != null) {
      final endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (endDateOnly.isBefore(todayDate)) {
        return StageStatus.completed;
      }
    }

    // 4. 시작 날짜가 오늘이거나 오늘 이전이면 → 진행중
    if (startDateOnly.isBefore(todayDate) || startDateOnly.isAtSameMomentAs(todayDate)) {
      return StageStatus.inProgress;
    }

    // 5. 시작 날짜가 미래이면 → 예정
    return StageStatus.pending;
  }

  /// D-Day 계산 (예정 상태일 때)
  int? get dDay {
    if (startDate == null) return null;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final startDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);
    return startDateOnly.difference(todayDate).inDays;
  }

  /// 상태 텍스트
  String get statusText {
    switch (calculatedStatus) {
      case StageStatus.pending:
        if (dDay != null && dDay! > 0) {
          return 'D-$dDay';
        }
        return '예정';
      case StageStatus.inProgress:
        return '진행중';
      case StageStatus.completed:
        return '완료';
    }
  }

  /// 기간 문자열
  String get periodString {
    if (startDate == null) return '예정';
    final start =
        '${startDate!.year}.${startDate!.month.toString().padLeft(2, '0')}.${startDate!.day.toString().padLeft(2, '0')}';

    // 이식 대기(waiting)는 기간 표시 안함 (날짜만 표시)
    if (stage == TreatmentStage.waiting) {
      return start;
    }

    if (endDate == null) {
      return calculatedStatus == StageStatus.inProgress ? '$start ~ 진행 중' : start;
    }
    final end =
        '${endDate!.month.toString().padLeft(2, '0')}.${endDate!.day.toString().padLeft(2, '0')}';
    return '$start ~ $end';
  }

  CycleStage copyWith({
    TreatmentStage? stage,
    StageStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    dynamic data,
    String? memo,
  }) {
    return CycleStage(
      stage: stage ?? this.stage,
      status: status ?? _manualStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      data: data ?? this.data,
      memo: memo ?? this.memo,
    );
  }
}

// ==================== 단계별 데이터 모델 ====================

/// 1. 과배란 (Stimulation) 데이터
class StimulationData {
  final int injectionCount; // 주사 횟수
  final int? durationDays; // 기간 (일)
  final String? memo;

  StimulationData({
    required this.injectionCount,
    this.durationDays,
    this.memo,
  });

  StimulationData copyWith({
    int? injectionCount,
    int? durationDays,
    String? memo,
  }) {
    return StimulationData(
      injectionCount: injectionCount ?? this.injectionCount,
      durationDays: durationDays ?? this.durationDays,
      memo: memo ?? this.memo,
    );
  }
}

/// 2. 채취 (Retrieval) 데이터
class RetrievalData {
  final int totalEggs; // 총 채취 난자 수
  final int matureEggs; // 성숙란(M2) 수
  final String? memo;

  RetrievalData({
    required this.totalEggs,
    required this.matureEggs,
    this.memo,
  });

  RetrievalData copyWith({
    int? totalEggs,
    int? matureEggs,
    String? memo,
  }) {
    return RetrievalData(
      totalEggs: totalEggs ?? this.totalEggs,
      matureEggs: matureEggs ?? this.matureEggs,
      memo: memo ?? this.memo,
    );
  }
}

/// 3. 이식 대기 (Waiting) 데이터 - 병원 결과들
class WaitingData {
  final List<LabResult> results; // 병원 결과 리스트
  final String? memo;

  WaitingData({
    required this.results,
    this.memo,
  });

  /// 특정 타입의 결과 가져오기
  LabResult? getResult(LabResultType type) {
    return results.cast<LabResult?>().firstWhere(
          (r) => r?.type == type,
          orElse: () => null,
        );
  }

  /// 결과 추가
  WaitingData addResult(LabResult result) {
    return WaitingData(
      results: [...results, result],
      memo: memo,
    );
  }

  /// 결과 업데이트
  WaitingData updateResult(LabResult result) {
    final index = results.indexWhere((r) => r.id == result.id);
    if (index == -1) return this;
    final newResults = List<LabResult>.from(results);
    newResults[index] = result;
    return WaitingData(results: newResults, memo: memo);
  }

  /// 결과 삭제
  WaitingData removeResult(String id) {
    return WaitingData(
      results: results.where((r) => r.id != id).toList(),
      memo: memo,
    );
  }

  WaitingData copyWith({
    List<LabResult>? results,
    String? memo,
  }) {
    return WaitingData(
      results: results ?? this.results,
      memo: memo ?? this.memo,
    );
  }
}

/// 병원 결과 (수정, Day3, Day5, 동결 등)
class LabResult {
  final String id;
  final LabResultType type;
  final DateTime recordedAt;
  final int? count;
  final String? method; // IVF, ICSI, Split (수정 결과용)
  final String? gradeNote; // 등급 메모 (AA 1개, AB 2개 등)
  final String? memo;

  LabResult({
    required this.id,
    required this.type,
    required this.recordedAt,
    this.count,
    this.method,
    this.gradeNote,
    this.memo,
  });

  LabResult copyWith({
    String? id,
    LabResultType? type,
    DateTime? recordedAt,
    int? count,
    String? method,
    String? gradeNote,
    String? memo,
  }) {
    return LabResult(
      id: id ?? this.id,
      type: type ?? this.type,
      recordedAt: recordedAt ?? this.recordedAt,
      count: count ?? this.count,
      method: method ?? this.method,
      gradeNote: gradeNote ?? this.gradeNote,
      memo: memo ?? this.memo,
    );
  }
}

/// 수정 방법
enum FertilizationMethod {
  ivf, // 체외수정
  icsi, // 세포질내 정자 주입
  split, // 혼합
}

extension FertilizationMethodExtension on FertilizationMethod {
  String get displayName {
    switch (this) {
      case FertilizationMethod.ivf:
        return 'IVF (체외수정)';
      case FertilizationMethod.icsi:
        return 'ICSI (미세주입)';
      case FertilizationMethod.split:
        return 'Split (혼합)';
    }
  }

  String get shortName {
    switch (this) {
      case FertilizationMethod.ivf:
        return 'IVF';
      case FertilizationMethod.icsi:
        return 'ICSI';
      case FertilizationMethod.split:
        return 'Split';
    }
  }
}

/// 4. 이식 (Transfer) 데이터
class TransferData {
  final int? embryoCount; // 이식 배아 수
  final double? endometriumThickness; // 내막 두께 (mm)
  final String? embryoGrade; // 이식 배아 등급
  final String? memo;

  TransferData({
    this.embryoCount,
    this.endometriumThickness,
    this.embryoGrade,
    this.memo,
  });

  TransferData copyWith({
    int? embryoCount,
    double? endometriumThickness,
    String? embryoGrade,
    String? memo,
  }) {
    return TransferData(
      embryoCount: embryoCount ?? this.embryoCount,
      endometriumThickness: endometriumThickness ?? this.endometriumThickness,
      embryoGrade: embryoGrade ?? this.embryoGrade,
      memo: memo ?? this.memo,
    );
  }
}

/// 5. 판정 (Result) 데이터
class ResultData {
  final double? hcgLevel; // hCG 수치
  final bool? isPregnant; // 임신 여부
  final DateTime? testDate; // 검사일
  final String? memo;

  ResultData({
    this.hcgLevel,
    this.isPregnant,
    this.testDate,
    this.memo,
  });

  ResultData copyWith({
    double? hcgLevel,
    bool? isPregnant,
    DateTime? testDate,
    String? memo,
  }) {
    return ResultData(
      hcgLevel: hcgLevel ?? this.hcgLevel,
      isPregnant: isPregnant ?? this.isPregnant,
      testDate: testDate ?? this.testDate,
      memo: memo ?? this.memo,
    );
  }
}

/// 배아 등급
enum EmbryoGrade {
  aa,
  ab,
  ba,
  bb,
  ac,
  bc,
  ca,
  cb,
  cc,
}

extension EmbryoGradeExtension on EmbryoGrade {
  String get displayName {
    switch (this) {
      case EmbryoGrade.aa:
        return 'AA (최상)';
      case EmbryoGrade.ab:
        return 'AB (상)';
      case EmbryoGrade.ba:
        return 'BA (상)';
      case EmbryoGrade.bb:
        return 'BB (중상)';
      case EmbryoGrade.ac:
        return 'AC (중)';
      case EmbryoGrade.bc:
        return 'BC (중)';
      case EmbryoGrade.ca:
        return 'CA (중)';
      case EmbryoGrade.cb:
        return 'CB (중하)';
      case EmbryoGrade.cc:
        return 'CC (하)';
    }
  }

  String get shortName => name.toUpperCase();
}
