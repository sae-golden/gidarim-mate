import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/additional_records.dart';

/// 추가 기록 항목 저장 서비스
/// 생리 시작일, 초음파 검사, 임신 테스트, 몸 상태 기록을 로컬에 저장
class AdditionalRecordService {
  // SharedPreferences 키
  static const String _periodRecordsKey = 'period_records';
  static const String _ultrasoundRecordsKey = 'ultrasound_records';
  static const String _pregnancyTestRecordsKey = 'pregnancy_test_records';
  static const String _conditionRecordsKey = 'condition_records';
  static const String _hospitalVisitRecordsKey = 'hospital_visit_records';

  // ============================================================
  // 생리 시작일 기록
  // ============================================================

  /// 모든 생리 시작일 기록 조회
  static Future<List<PeriodRecord>> getAllPeriodRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_periodRecordsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => PeriodRecord.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬
    } catch (e) {
      debugPrint('생리 기록 조회 오류: $e');
      return [];
    }
  }

  /// 특정 사이클의 생리 시작일 기록 조회
  static Future<List<PeriodRecord>> getPeriodRecordsByCycle(String cycleId) async {
    final all = await getAllPeriodRecords();
    return all.where((r) => r.cycleId == cycleId).toList();
  }

  /// 사이클에 연결되지 않은 생리 시작일 기록 조회
  static Future<List<PeriodRecord>> getOrphanPeriodRecords() async {
    final all = await getAllPeriodRecords();
    return all.where((r) => r.cycleId == null || r.cycleId!.isEmpty).toList();
  }

  /// 특정 날짜 범위의 생리 시작일 기록 조회
  static Future<List<PeriodRecord>> getPeriodRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllPeriodRecords();
    return all.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
          r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// 생리 시작일 기록 추가
  static Future<void> addPeriodRecord(PeriodRecord record) async {
    try {
      final records = await getAllPeriodRecords();
      records.add(record);
      await _savePeriodRecords(records);
    } catch (e) {
      debugPrint('생리 기록 추가 오류: $e');
      rethrow;
    }
  }

  /// 생리 시작일 기록 수정
  static Future<void> updatePeriodRecord(PeriodRecord record) async {
    try {
      final records = await getAllPeriodRecords();
      final index = records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        records[index] = record;
        await _savePeriodRecords(records);
      }
    } catch (e) {
      debugPrint('생리 기록 수정 오류: $e');
      rethrow;
    }
  }

  /// 생리 시작일 기록 삭제
  static Future<void> deletePeriodRecord(String id) async {
    try {
      final records = await getAllPeriodRecords();
      records.removeWhere((r) => r.id == id);
      await _savePeriodRecords(records);
    } catch (e) {
      debugPrint('생리 기록 삭제 오류: $e');
      rethrow;
    }
  }

  static Future<void> _savePeriodRecords(List<PeriodRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_periodRecordsKey, jsonString);
  }

  // ============================================================
  // 초음파 검사 기록
  // ============================================================

  /// 모든 초음파 검사 기록 조회
  static Future<List<UltrasoundRecord>> getAllUltrasoundRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_ultrasoundRecordsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => UltrasoundRecord.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬
    } catch (e) {
      debugPrint('초음파 기록 조회 오류: $e');
      return [];
    }
  }

  /// 특정 사이클의 초음파 검사 기록 조회
  static Future<List<UltrasoundRecord>> getUltrasoundRecordsByCycle(String cycleId) async {
    final all = await getAllUltrasoundRecords();
    return all.where((r) => r.cycleId == cycleId).toList();
  }

  /// 사이클에 연결되지 않은 초음파 검사 기록 조회
  static Future<List<UltrasoundRecord>> getOrphanUltrasoundRecords() async {
    final all = await getAllUltrasoundRecords();
    return all.where((r) => r.cycleId == null || r.cycleId!.isEmpty).toList();
  }

  /// 특정 날짜 범위의 초음파 검사 기록 조회
  static Future<List<UltrasoundRecord>> getUltrasoundRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllUltrasoundRecords();
    return all.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
          r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// 초음파 검사 기록 추가
  static Future<void> addUltrasoundRecord(UltrasoundRecord record) async {
    try {
      final records = await getAllUltrasoundRecords();
      records.add(record);
      await _saveUltrasoundRecords(records);
    } catch (e) {
      debugPrint('초음파 기록 추가 오류: $e');
      rethrow;
    }
  }

  /// 초음파 검사 기록 수정
  static Future<void> updateUltrasoundRecord(UltrasoundRecord record) async {
    try {
      final records = await getAllUltrasoundRecords();
      final index = records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        records[index] = record;
        await _saveUltrasoundRecords(records);
      }
    } catch (e) {
      debugPrint('초음파 기록 수정 오류: $e');
      rethrow;
    }
  }

  /// 초음파 검사 기록 삭제
  static Future<void> deleteUltrasoundRecord(String id) async {
    try {
      final records = await getAllUltrasoundRecords();
      records.removeWhere((r) => r.id == id);
      await _saveUltrasoundRecords(records);
    } catch (e) {
      debugPrint('초음파 기록 삭제 오류: $e');
      rethrow;
    }
  }

  static Future<void> _saveUltrasoundRecords(List<UltrasoundRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_ultrasoundRecordsKey, jsonString);
  }

  // ============================================================
  // 임신 테스트 기록
  // ============================================================

  /// 모든 임신 테스트 기록 조회
  static Future<List<PregnancyTestRecord>> getAllPregnancyTestRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pregnancyTestRecordsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => PregnancyTestRecord.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬
    } catch (e) {
      debugPrint('임신 테스트 기록 조회 오류: $e');
      return [];
    }
  }

  /// 특정 사이클의 임신 테스트 기록 조회
  static Future<List<PregnancyTestRecord>> getPregnancyTestRecordsByCycle(String cycleId) async {
    final all = await getAllPregnancyTestRecords();
    return all.where((r) => r.cycleId == cycleId).toList();
  }

  /// 사이클에 연결되지 않은 임신 테스트 기록 조회
  static Future<List<PregnancyTestRecord>> getOrphanPregnancyTestRecords() async {
    final all = await getAllPregnancyTestRecords();
    return all.where((r) => r.cycleId == null || r.cycleId!.isEmpty).toList();
  }

  /// 특정 날짜 범위의 임신 테스트 기록 조회
  static Future<List<PregnancyTestRecord>> getPregnancyTestRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllPregnancyTestRecords();
    return all.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
          r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// 임신 테스트 기록 추가
  static Future<void> addPregnancyTestRecord(PregnancyTestRecord record) async {
    try {
      final records = await getAllPregnancyTestRecords();
      records.add(record);
      await _savePregnancyTestRecords(records);
    } catch (e) {
      debugPrint('임신 테스트 기록 추가 오류: $e');
      rethrow;
    }
  }

  /// 임신 테스트 기록 수정
  static Future<void> updatePregnancyTestRecord(PregnancyTestRecord record) async {
    try {
      final records = await getAllPregnancyTestRecords();
      final index = records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        records[index] = record;
        await _savePregnancyTestRecords(records);
      }
    } catch (e) {
      debugPrint('임신 테스트 기록 수정 오류: $e');
      rethrow;
    }
  }

  /// 임신 테스트 기록 삭제
  static Future<void> deletePregnancyTestRecord(String id) async {
    try {
      final records = await getAllPregnancyTestRecords();
      records.removeWhere((r) => r.id == id);
      await _savePregnancyTestRecords(records);
    } catch (e) {
      debugPrint('임신 테스트 기록 삭제 오류: $e');
      rethrow;
    }
  }

  static Future<void> _savePregnancyTestRecords(List<PregnancyTestRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_pregnancyTestRecordsKey, jsonString);
  }

  // ============================================================
  // 몸 상태 기록
  // ============================================================

  /// 모든 몸 상태 기록 조회
  static Future<List<ConditionRecord>> getAllConditionRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conditionRecordsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ConditionRecord.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬
    } catch (e) {
      debugPrint('몸 상태 기록 조회 오류: $e');
      return [];
    }
  }

  /// 특정 사이클의 몸 상태 기록 조회
  static Future<List<ConditionRecord>> getConditionRecordsByCycle(String cycleId) async {
    final all = await getAllConditionRecords();
    return all.where((r) => r.cycleId == cycleId).toList();
  }

  /// 사이클에 연결되지 않은 몸 상태 기록 조회
  static Future<List<ConditionRecord>> getOrphanConditionRecords() async {
    final all = await getAllConditionRecords();
    return all.where((r) => r.cycleId == null || r.cycleId!.isEmpty).toList();
  }

  /// 특정 날짜 범위의 몸 상태 기록 조회
  static Future<List<ConditionRecord>> getConditionRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllConditionRecords();
    return all.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
          r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// 몸 상태 기록 추가
  static Future<void> addConditionRecord(ConditionRecord record) async {
    try {
      final records = await getAllConditionRecords();
      records.add(record);
      await _saveConditionRecords(records);
    } catch (e) {
      debugPrint('몸 상태 기록 추가 오류: $e');
      rethrow;
    }
  }

  /// 몸 상태 기록 수정
  static Future<void> updateConditionRecord(ConditionRecord record) async {
    try {
      final records = await getAllConditionRecords();
      final index = records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        records[index] = record;
        await _saveConditionRecords(records);
      }
    } catch (e) {
      debugPrint('몸 상태 기록 수정 오류: $e');
      rethrow;
    }
  }

  /// 몸 상태 기록 삭제
  static Future<void> deleteConditionRecord(String id) async {
    try {
      final records = await getAllConditionRecords();
      records.removeWhere((r) => r.id == id);
      await _saveConditionRecords(records);
    } catch (e) {
      debugPrint('몸 상태 기록 삭제 오류: $e');
      rethrow;
    }
  }

  static Future<void> _saveConditionRecords(List<ConditionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_conditionRecordsKey, jsonString);
  }

  // ============================================================
  // 병원 예약 기록
  // ============================================================

  /// 모든 병원 예약 기록 조회
  static Future<List<HospitalVisitRecord>> getAllHospitalVisitRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_hospitalVisitRecordsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => HospitalVisitRecord.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬
    } catch (e) {
      debugPrint('병원 예약 기록 조회 오류: $e');
      return [];
    }
  }

  /// 특정 사이클의 병원 예약 기록 조회
  static Future<List<HospitalVisitRecord>> getHospitalVisitRecordsByCycle(String cycleId) async {
    final all = await getAllHospitalVisitRecords();
    return all.where((r) => r.cycleId == cycleId).toList();
  }

  /// 사이클에 연결되지 않은 병원 예약 기록 조회
  static Future<List<HospitalVisitRecord>> getOrphanHospitalVisitRecords() async {
    final all = await getAllHospitalVisitRecords();
    return all.where((r) => r.cycleId == null || r.cycleId!.isEmpty).toList();
  }

  /// 특정 날짜 범위의 병원 예약 기록 조회
  static Future<List<HospitalVisitRecord>> getHospitalVisitRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllHospitalVisitRecords();
    return all.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
          r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// 병원 예약 기록 추가
  static Future<void> addHospitalVisitRecord(HospitalVisitRecord record) async {
    try {
      final records = await getAllHospitalVisitRecords();
      records.add(record);
      await _saveHospitalVisitRecords(records);
    } catch (e) {
      debugPrint('병원 예약 기록 추가 오류: $e');
      rethrow;
    }
  }

  /// 병원 예약 기록 수정
  static Future<void> updateHospitalVisitRecord(HospitalVisitRecord record) async {
    try {
      final records = await getAllHospitalVisitRecords();
      final index = records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        records[index] = record;
        await _saveHospitalVisitRecords(records);
      }
    } catch (e) {
      debugPrint('병원 예약 기록 수정 오류: $e');
      rethrow;
    }
  }

  /// 병원 예약 기록 삭제
  static Future<void> deleteHospitalVisitRecord(String id) async {
    try {
      final records = await getAllHospitalVisitRecords();
      records.removeWhere((r) => r.id == id);
      await _saveHospitalVisitRecords(records);
    } catch (e) {
      debugPrint('병원 예약 기록 삭제 오류: $e');
      rethrow;
    }
  }

  static Future<void> _saveHospitalVisitRecords(List<HospitalVisitRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_hospitalVisitRecordsKey, jsonString);
  }

  // ============================================================
  // 통합 조회 (캘린더용)
  // ============================================================

  /// 특정 날짜의 모든 기록 조회 (캘린더 색상 점 표시용)
  static Future<Map<RecordType, int>> getRecordCountsByDate(DateTime date) async {
    final result = <RecordType, int>{};

    // 날짜 범위 설정 (해당 날짜 하루)
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // 각 기록 타입별 개수 조회
    final periods = await getPeriodRecordsByDateRange(start, end);
    if (periods.isNotEmpty) result[RecordType.period] = periods.length;

    final ultrasounds = await getUltrasoundRecordsByDateRange(start, end);
    if (ultrasounds.isNotEmpty) result[RecordType.ultrasound] = ultrasounds.length;

    final pregnancyTests = await getPregnancyTestRecordsByDateRange(start, end);
    if (pregnancyTests.isNotEmpty) result[RecordType.pregnancyTest] = pregnancyTests.length;

    final conditions = await getConditionRecordsByDateRange(start, end);
    if (conditions.isNotEmpty) result[RecordType.condition] = conditions.length;

    final hospitalVisits = await getHospitalVisitRecordsByDateRange(start, end);
    if (hospitalVisits.isNotEmpty) result[RecordType.hospitalVisit] = hospitalVisits.length;

    return result;
  }

  /// 특정 날짜 범위의 모든 기록 날짜 조회 (캘린더 마커용)
  static Future<Map<DateTime, Set<RecordType>>> getRecordDatesByRange(
    DateTime start,
    DateTime end,
  ) async {
    final result = <DateTime, Set<RecordType>>{};

    void addRecord(DateTime date, RecordType type) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      result.putIfAbsent(dateOnly, () => {}).add(type);
    }

    // 각 기록 타입별 조회
    final periods = await getPeriodRecordsByDateRange(start, end);
    for (final record in periods) {
      addRecord(record.date, RecordType.period);
    }

    final ultrasounds = await getUltrasoundRecordsByDateRange(start, end);
    for (final record in ultrasounds) {
      addRecord(record.date, RecordType.ultrasound);
    }

    final pregnancyTests = await getPregnancyTestRecordsByDateRange(start, end);
    for (final record in pregnancyTests) {
      addRecord(record.date, RecordType.pregnancyTest);
    }

    final conditions = await getConditionRecordsByDateRange(start, end);
    for (final record in conditions) {
      addRecord(record.date, RecordType.condition);
    }

    final hospitalVisits = await getHospitalVisitRecordsByDateRange(start, end);
    for (final record in hospitalVisits) {
      addRecord(record.date, RecordType.hospitalVisit);
    }

    return result;
  }
}
