import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simple_treatment_cycle.dart';

/// 심플 치료 사이클 서비스
/// SharedPreferences를 사용한 로컬 저장
class SimpleTreatmentService {
  static const String _currentCycleKey = 'simple_current_cycle';
  static const String _pastCyclesKey = 'simple_past_cycles';

  /// 현재 사이클 조회
  static Future<SimpleTreatmentCycle> getCurrentCycle() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_currentCycleKey);

    if (jsonString == null) {
      // 기본값: 1차 채취
      return SimpleTreatmentCycle.create(cycleNumber: 1);
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SimpleTreatmentCycle.fromJson(json);
    } catch (e) {
      // 파싱 실패 시 기본값 반환
      return SimpleTreatmentCycle.create(cycleNumber: 1);
    }
  }

  /// 현재 사이클 저장
  static Future<void> saveCurrentCycle(SimpleTreatmentCycle cycle) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(cycle.toJson());
    await prefs.setString(_currentCycleKey, jsonString);
  }

  /// 단계 업데이트 (현재 사이클)
  static Future<SimpleTreatmentCycle> updateStage(
    SimpleTreatmentStage stage,
  ) async {
    final currentCycle = await getCurrentCycle();
    final updatedCycle = currentCycle.updateStage(stage);
    await saveCurrentCycle(updatedCycle);
    return updatedCycle;
  }

  /// 지난 사이클 목록 조회
  static Future<List<SimpleTreatmentCycle>> getPastCycles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pastCyclesKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => SimpleTreatmentCycle.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 지난 사이클 목록 저장
  static Future<void> savePastCycles(List<SimpleTreatmentCycle> cycles) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cycles.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_pastCyclesKey, jsonString);
  }

  /// 새 채취 시작 (현재 사이클을 지난 사이클로 이동)
  static Future<SimpleTreatmentCycle> startNewRetrievalCycle() async {
    final currentCycle = await getCurrentCycle();
    final pastCycles = await getPastCycles();

    // 현재 사이클이 데이터가 있으면 지난 사이클로 이동
    if (_hasAnyData(currentCycle)) {
      pastCycles.insert(0, currentCycle);
      await savePastCycles(pastCycles);
    }

    // 새 사이클 생성 (회차 증가)
    final newCycleNumber = pastCycles.isEmpty ? 1 : pastCycles.length + 1;
    final newCycle = SimpleTreatmentCycle.create(cycleNumber: newCycleNumber);
    await saveCurrentCycle(newCycle);

    return newCycle;
  }

  /// 사이클에 데이터가 있는지 확인
  static bool _hasAnyData(SimpleTreatmentCycle cycle) {
    for (final stage in cycle.stages) {
      if (stage.hasDate || stage.count != null || stage.result != null) {
        return true;
      }
    }
    return false;
  }

  /// 모든 데이터 초기화 (테스트용)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentCycleKey);
    await prefs.remove(_pastCyclesKey);
  }

  /// 샘플 데이터 생성 (테스트용)
  static Future<SimpleTreatmentCycle> createSampleData() async {
    final now = DateTime.now();

    final sampleCycle = SimpleTreatmentCycle(
      id: now.millisecondsSinceEpoch.toString(),
      cycleNumber: 1,
      attemptNumber: 1,
      startDate: now.subtract(const Duration(days: 21)),
      stages: [
        SimpleTreatmentStage(
          type: SimpleStageType.stimulation,
          startDate: now.subtract(const Duration(days: 21)),
        ),
        SimpleTreatmentStage(
          type: SimpleStageType.retrieval,
          date: now.subtract(const Duration(days: 10)),
          count: 6,
        ),
        SimpleTreatmentStage(
          type: SimpleStageType.waiting,
          startDate: now.subtract(const Duration(days: 9)),
          count: 2,
        ),
        SimpleTreatmentStage(
          type: SimpleStageType.transfer,
        ),
        SimpleTreatmentStage(
          type: SimpleStageType.result,
        ),
      ],
    );

    await saveCurrentCycle(sampleCycle);
    return sampleCycle;
  }
}
