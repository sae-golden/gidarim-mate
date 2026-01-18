// 추가 기록 항목 모델들
// 기획서에 따른 4개 신규 항목: 생리 시작일, 초음파 검사, 임신 테스트, 몸 상태

import 'package:flutter/material.dart';

/// 기록 항목 타입 (전체 11개)
enum RecordType {
  // 주기 관리
  period,        // 생리 시작일
  cycleResult,   // 사이클 결과

  // 시술 기록
  stimulation,   // 과배란 주사
  insemination,  // 인공수정
  retrieval,     // 난자 채취
  transfer,      // 배아 이식
  freezing,      // 배아 동결

  // 검사 기록
  bloodTest,     // 피검사
  ultrasound,    // 초음파 검사
  pregnancyTest, // 임신 테스트

  // 일상 기록
  condition,     // 몸 상태
}

/// 기록 타입 확장
extension RecordTypeExtension on RecordType {
  String get name {
    switch (this) {
      case RecordType.period: return '생리 시작일';
      case RecordType.cycleResult: return '사이클 결과';
      case RecordType.stimulation: return '과배란 주사';
      case RecordType.insemination: return '인공수정';
      case RecordType.retrieval: return '난자 채취';
      case RecordType.transfer: return '배아 이식';
      case RecordType.freezing: return '배아 동결';
      case RecordType.bloodTest: return '피검사';
      case RecordType.ultrasound: return '초음파 검사';
      case RecordType.pregnancyTest: return '임신 테스트';
      case RecordType.condition: return '몸 상태';
    }
  }

  /// 바텀시트 선택용 감성적 표현
  String get displayText {
    switch (this) {
      case RecordType.period: return '생리 시작했어요';
      case RecordType.cycleResult: return '사이클 결과';
      case RecordType.stimulation: return '과배란 중이에요';
      case RecordType.insemination: return '인공수정 했어요';
      case RecordType.retrieval: return '채취했어요';
      case RecordType.transfer: return '이식했어요';
      case RecordType.freezing: return '동결했어요';
      case RecordType.bloodTest: return '피검사 했어요';
      case RecordType.ultrasound: return '초음파 봤어요';
      case RecordType.pregnancyTest: return '임신 테스트 했어요';
      case RecordType.condition: return '오늘 몸 상태 기록하기';
    }
  }

  String get emoji {
    switch (this) {
      case RecordType.period: return '🔴';
      case RecordType.cycleResult: return '🏁';
      case RecordType.stimulation: return '💉';
      case RecordType.insemination: return '💫';
      case RecordType.retrieval: return '🥚';
      case RecordType.transfer: return '🌱';
      case RecordType.freezing: return '❄️';
      case RecordType.bloodTest: return '📋';
      case RecordType.ultrasound: return '🔍';
      case RecordType.pregnancyTest: return '🤞';
      case RecordType.condition: return '📝';
    }
  }

  Color get color {
    switch (this) {
      case RecordType.period: return const Color(0xFFE74C3C);         // 빨강
      case RecordType.cycleResult: return const Color(0xFFF1C40F);    // 골드
      case RecordType.stimulation: return const Color(0xFF9B7BDB);    // 보라
      case RecordType.insemination: return const Color(0xFFE91E8C);   // 핑크
      case RecordType.retrieval: return const Color(0xFFF5A623);      // 주황
      case RecordType.transfer: return const Color(0xFF7ED321);       // 초록
      case RecordType.freezing: return const Color(0xFF5DADE2);       // 하늘
      case RecordType.bloodTest: return const Color(0xFF4A90D9);      // 파랑
      case RecordType.ultrasound: return const Color(0xFF1ABC9C);     // 청록
      case RecordType.pregnancyTest: return const Color(0xFFBB8FCE);  // 연보라
      case RecordType.condition: return const Color(0xFF95A5A6);      // 회색
    }
  }

  /// 카테고리
  String get category {
    switch (this) {
      case RecordType.period:
      case RecordType.cycleResult:
        return '주기 관리';
      case RecordType.stimulation:
      case RecordType.insemination:
      case RecordType.retrieval:
      case RecordType.transfer:
      case RecordType.freezing:
        return '시술 기록';
      case RecordType.bloodTest:
      case RecordType.ultrasound:
      case RecordType.pregnancyTest:
        return '검사 기록';
      case RecordType.condition:
        return '일상 기록';
    }
  }
}

// ============================================================
// 생리 시작일 기록
// ============================================================

/// 생리 시작일 기록
class PeriodRecord {
  final String id;
  final String? cycleId;
  final DateTime date;
  final String? memo;
  final DateTime createdAt;

  PeriodRecord({
    required this.id,
    this.cycleId,
    required this.date,
    this.memo,
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

  PeriodRecord copyWith({
    String? id,
    String? cycleId,
    DateTime? date,
    String? memo,
    DateTime? createdAt,
    bool clearMemo = false,
  }) {
    return PeriodRecord(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      date: date ?? this.date,
      memo: clearMemo ? null : (memo ?? this.memo),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cycleId': cycleId,
      'date': date.toIso8601String(),
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PeriodRecord.fromJson(Map<String, dynamic> json) {
    return PeriodRecord(
      id: json['id'] as String,
      cycleId: json['cycleId'] as String?,
      date: DateTime.parse(json['date'] as String),
      memo: json['memo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory PeriodRecord.create({
    String? cycleId,
    required DateTime date,
    String? memo,
  }) {
    return PeriodRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: cycleId,
      date: date,
      memo: memo,
    );
  }
}

// ============================================================
// 초음파 검사 기록
// ============================================================

/// 초음파 검사 기록
class UltrasoundRecord {
  final String id;
  final String? cycleId;
  final DateTime date;
  final List<double>? follicleSizes;  // 난포 크기들 (mm)
  final double? endometriumThickness; // 내막 두께 (mm)
  final String? memo;
  final DateTime createdAt;

  UltrasoundRecord({
    required this.id,
    this.cycleId,
    required this.date,
    this.follicleSizes,
    this.endometriumThickness,
    this.memo,
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

  /// 난포 요약 텍스트
  String? get follicleSummary {
    if (follicleSizes == null || follicleSizes!.isEmpty) return null;
    final sorted = List<double>.from(follicleSizes!)..sort((a, b) => b.compareTo(a));
    if (sorted.length <= 3) {
      return '난포 ${sorted.map((s) => '${s.toStringAsFixed(0)}mm').join(', ')}';
    }
    return '난포 ${sorted.take(3).map((s) => '${s.toStringAsFixed(0)}mm').join(', ')} 외 ${sorted.length - 3}개';
  }

  /// 내막 두께 텍스트
  String? get endometriumText {
    if (endometriumThickness == null) return null;
    return '내막 ${endometriumThickness!.toStringAsFixed(1)}mm';
  }

  /// 타임라인 요약 텍스트
  String get summaryText {
    final parts = <String>[];
    if (follicleSummary != null) parts.add(follicleSummary!);
    if (endometriumText != null) parts.add(endometriumText!);
    if (parts.isEmpty) return dateText;
    return parts.join(' · ');
  }

  UltrasoundRecord copyWith({
    String? id,
    String? cycleId,
    DateTime? date,
    List<double>? follicleSizes,
    double? endometriumThickness,
    String? memo,
    DateTime? createdAt,
    bool clearFollicleSizes = false,
    bool clearEndometriumThickness = false,
    bool clearMemo = false,
  }) {
    return UltrasoundRecord(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      date: date ?? this.date,
      follicleSizes: clearFollicleSizes ? null : (follicleSizes ?? this.follicleSizes),
      endometriumThickness: clearEndometriumThickness ? null : (endometriumThickness ?? this.endometriumThickness),
      memo: clearMemo ? null : (memo ?? this.memo),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cycleId': cycleId,
      'date': date.toIso8601String(),
      'follicleSizes': follicleSizes,
      'endometriumThickness': endometriumThickness,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UltrasoundRecord.fromJson(Map<String, dynamic> json) {
    return UltrasoundRecord(
      id: json['id'] as String,
      cycleId: json['cycleId'] as String?,
      date: DateTime.parse(json['date'] as String),
      follicleSizes: (json['follicleSizes'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      endometriumThickness: (json['endometriumThickness'] as num?)?.toDouble(),
      memo: json['memo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory UltrasoundRecord.create({
    String? cycleId,
    required DateTime date,
    List<double>? follicleSizes,
    double? endometriumThickness,
    String? memo,
  }) {
    return UltrasoundRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: cycleId,
      date: date,
      follicleSizes: follicleSizes,
      endometriumThickness: endometriumThickness,
      memo: memo,
    );
  }
}

// ============================================================
// 임신 테스트 기록
// ============================================================

/// 임신 테스트 결과
enum PregnancyTestResult {
  positive,  // 양성
  faint,     // 희미한 선
  negative,  // 음성
}

/// 임신 테스트 결과 확장
extension PregnancyTestResultExtension on PregnancyTestResult {
  String get name {
    switch (this) {
      case PregnancyTestResult.positive: return '양성';
      case PregnancyTestResult.faint: return '희미한 선';
      case PregnancyTestResult.negative: return '음성';
    }
  }

  String get description {
    switch (this) {
      case PregnancyTestResult.positive: return '두 줄이 보여요';
      case PregnancyTestResult.faint: return '살짝 보이는 것 같아요';
      case PregnancyTestResult.negative: return '한 줄만 보여요';
    }
  }

  String get emoji {
    switch (this) {
      case PregnancyTestResult.positive: return '🎉';
      case PregnancyTestResult.faint: return '🤔';
      case PregnancyTestResult.negative: return '💜';
    }
  }

  Color get color {
    switch (this) {
      case PregnancyTestResult.positive: return const Color(0xFF7ED321);
      case PregnancyTestResult.faint: return const Color(0xFFF5A623);
      case PregnancyTestResult.negative: return const Color(0xFF95A5A6);
    }
  }
}

/// 임신 테스트 종류
enum PregnancyTestType {
  home,     // 자가테스트
  hospital, // 병원검사
}

/// 임신 테스트 종류 확장
extension PregnancyTestTypeExtension on PregnancyTestType {
  String get name {
    switch (this) {
      case PregnancyTestType.home: return '자가테스트';
      case PregnancyTestType.hospital: return '병원검사';
    }
  }
}

/// 임신 테스트 기록
class PregnancyTestRecord {
  final String id;
  final String? cycleId;
  final DateTime date;
  final PregnancyTestResult result;
  final PregnancyTestType? testType;
  final String? memo;
  final DateTime createdAt;

  PregnancyTestRecord({
    required this.id,
    this.cycleId,
    required this.date,
    required this.result,
    this.testType,
    this.memo,
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

  /// 타임라인 요약 텍스트
  String get summaryText {
    final parts = <String>[result.name];
    if (testType != null) parts.add(testType!.name);
    return parts.join(' · ');
  }

  PregnancyTestRecord copyWith({
    String? id,
    String? cycleId,
    DateTime? date,
    PregnancyTestResult? result,
    PregnancyTestType? testType,
    String? memo,
    DateTime? createdAt,
    bool clearTestType = false,
    bool clearMemo = false,
  }) {
    return PregnancyTestRecord(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      date: date ?? this.date,
      result: result ?? this.result,
      testType: clearTestType ? null : (testType ?? this.testType),
      memo: clearMemo ? null : (memo ?? this.memo),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cycleId': cycleId,
      'date': date.toIso8601String(),
      'result': result.index,
      'testType': testType?.index,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PregnancyTestRecord.fromJson(Map<String, dynamic> json) {
    return PregnancyTestRecord(
      id: json['id'] as String,
      cycleId: json['cycleId'] as String?,
      date: DateTime.parse(json['date'] as String),
      result: PregnancyTestResult.values[json['result'] as int],
      testType: json['testType'] != null
          ? PregnancyTestType.values[json['testType'] as int]
          : null,
      memo: json['memo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory PregnancyTestRecord.create({
    String? cycleId,
    required DateTime date,
    required PregnancyTestResult result,
    PregnancyTestType? testType,
    String? memo,
  }) {
    return PregnancyTestRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: cycleId,
      date: date,
      result: result,
      testType: testType,
      memo: memo,
    );
  }
}

// ============================================================
// 몸 상태 기록
// ============================================================

/// 증상 타입 (8가지)
enum SymptomType {
  bloating,     // 복부 팽만감
  headache,     // 두통
  nausea,       // 메스꺼움
  breastPain,   // 유방 통증
  fatigue,      // 피로감
  moodSwing,    // 기분 변화
  insomnia,     // 불면
  other,        // 기타
}

/// 증상 타입 확장
extension SymptomTypeExtension on SymptomType {
  String get name {
    switch (this) {
      case SymptomType.bloating: return '복부 팽만감';
      case SymptomType.headache: return '두통';
      case SymptomType.nausea: return '메스꺼움';
      case SymptomType.breastPain: return '유방 통증';
      case SymptomType.fatigue: return '피로감';
      case SymptomType.moodSwing: return '기분 변화';
      case SymptomType.insomnia: return '불면';
      case SymptomType.other: return '기타';
    }
  }

  String get description {
    switch (this) {
      case SymptomType.bloating: return '배가 빵빵해요';
      case SymptomType.headache: return '머리가 아파요';
      case SymptomType.nausea: return '속이 울렁거려요';
      case SymptomType.breastPain: return '가슴이 아파요';
      case SymptomType.fatigue: return '몸이 무거워요';
      case SymptomType.moodSwing: return '감정 기복이 있어요';
      case SymptomType.insomnia: return '잠들기 어려워요';
      case SymptomType.other: return '직접 입력';
    }
  }

  String get emoji {
    switch (this) {
      case SymptomType.bloating: return '🫄';
      case SymptomType.headache: return '🤕';
      case SymptomType.nausea: return '🤢';
      case SymptomType.breastPain: return '💔';
      case SymptomType.fatigue: return '😴';
      case SymptomType.moodSwing: return '🎭';
      case SymptomType.insomnia: return '😫';
      case SymptomType.other: return '📝';
    }
  }
}

/// 몸 상태 기록
class ConditionRecord {
  final String id;
  final String? cycleId;
  final DateTime date;
  final List<SymptomType> symptoms;
  final String? memo;
  final DateTime createdAt;

  ConditionRecord({
    required this.id,
    this.cycleId,
    required this.date,
    required this.symptoms,
    this.memo,
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

  /// 증상 요약 텍스트
  String get symptomsSummary {
    if (symptoms.isEmpty) return '증상 없음';
    if (symptoms.length <= 2) {
      return symptoms.map((s) => s.name).join(', ');
    }
    return '${symptoms.take(2).map((s) => s.name).join(', ')} 외 ${symptoms.length - 2}개';
  }

  /// 타임라인 요약 텍스트
  String get summaryText => symptomsSummary;

  ConditionRecord copyWith({
    String? id,
    String? cycleId,
    DateTime? date,
    List<SymptomType>? symptoms,
    String? memo,
    DateTime? createdAt,
    bool clearMemo = false,
  }) {
    return ConditionRecord(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      date: date ?? this.date,
      symptoms: symptoms ?? this.symptoms,
      memo: clearMemo ? null : (memo ?? this.memo),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cycleId': cycleId,
      'date': date.toIso8601String(),
      'symptoms': symptoms.map((s) => s.index).toList(),
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ConditionRecord.fromJson(Map<String, dynamic> json) {
    return ConditionRecord(
      id: json['id'] as String,
      cycleId: json['cycleId'] as String?,
      date: DateTime.parse(json['date'] as String),
      symptoms: (json['symptoms'] as List<dynamic>)
          .map((s) => SymptomType.values[s as int])
          .toList(),
      memo: json['memo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory ConditionRecord.create({
    String? cycleId,
    required DateTime date,
    required List<SymptomType> symptoms,
    String? memo,
  }) {
    return ConditionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: cycleId,
      date: date,
      symptoms: symptoms,
      memo: memo,
    );
  }
}
