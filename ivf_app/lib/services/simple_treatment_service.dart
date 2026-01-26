import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simple_treatment_cycle.dart';

/// 타임라인 기반 치료 사이클 서비스
/// SharedPreferences를 사용한 로컬 저장
class SimpleTreatmentService {
  static const String _currentCycleKey = 'timeline_current_cycle';
  static const String _pastCyclesKey = 'timeline_past_cycles';
  static const String _legacyCurrentCycleKey = 'simple_current_cycle';
  static const String _legacyPastCyclesKey = 'simple_past_cycles';

  /// 사이클이 명시적으로 생성되었는지 확인 (시술 선택 화면 표시 여부 결정)
  static Future<bool> hasCycleStarted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_currentCycleKey) || prefs.containsKey(_legacyCurrentCycleKey);
  }

  /// 현재 사이클 조회
  static Future<TreatmentCycle> getCurrentCycle() async {
    final prefs = await SharedPreferences.getInstance();

    // 새 키에서 먼저 조회
    var jsonString = prefs.getString(_currentCycleKey);
    debugPrint('📖 [SimpleTreatmentService] 사이클 로드 시도');
    debugPrint('   - 키 존재: ${jsonString != null}');

    if (jsonString == null) {
      // 레거시 데이터 마이그레이션 시도
      final legacyJson = prefs.getString(_legacyCurrentCycleKey);
      if (legacyJson != null) {
        debugPrint('   - 레거시 데이터 발견, 마이그레이션 시도');
        try {
          final legacy = SimpleTreatmentCycle.fromJson(
              jsonDecode(legacyJson) as Map<String, dynamic>);
          final migrated = legacy.toNewModel();
          await saveCurrentCycle(migrated);
          return migrated;
        } catch (e) {
          debugPrint('   ❌ 마이그레이션 실패: $e');
        }
      }

      debugPrint('   - 저장된 사이클 없음, 기본값 반환');
      return TreatmentCycle.create(cycleNumber: 1);
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final cycle = TreatmentCycle.fromJson(json);
      debugPrint('   ✅ 사이클 로드 성공: ${cycle.id}');
      debugPrint('   - 이벤트 수: ${cycle.events.length}');
      return cycle;
    } catch (e) {
      debugPrint('   ❌ 파싱 실패: $e');
      return TreatmentCycle.create(cycleNumber: 1);
    }
  }

  /// 현재 사이클 저장
  static Future<void> saveCurrentCycle(TreatmentCycle cycle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(cycle.toJson());
      final success = await prefs.setString(_currentCycleKey, jsonString);
      debugPrint('💾 [SimpleTreatmentService] 사이클 저장: ${cycle.id}');
      debugPrint('   - 이벤트 수: ${cycle.events.length}');
      debugPrint('   - 저장 성공: $success');
      if (cycle.events.isNotEmpty) {
        for (final event in cycle.events) {
          debugPrint('   - 이벤트: ${event.type.name} (${event.date})');
        }
      }
    } catch (e, stack) {
      debugPrint('❌ [SimpleTreatmentService] 사이클 저장 실패: $e');
      debugPrint('   스택: $stack');
    }
  }

  /// 사이클 저장 (현재 사이클 업데이트)
  static Future<void> saveCycle(TreatmentCycle cycle) async {
    await saveCurrentCycle(cycle);
  }

  /// 기본 사이클 생성 (시술 선택 없이 바로 시작)
  static Future<TreatmentCycle> createDefaultCycle() async {
    // 이미 사이클이 있는지 확인
    final hasStarted = await hasCycleStarted();
    if (hasStarted) {
      return await getCurrentCycle();
    }

    // 기본 IVF 사이클 생성
    final now = DateTime.now();
    final cycleNumber = await getNextCycleNumber(TreatmentType.ivf);

    final newCycle = TreatmentCycle(
      id: 'cycle_${now.millisecondsSinceEpoch}',
      cycleNumber: cycleNumber,
      type: TreatmentType.ivf,
      startDate: now,
      events: [],
    );

    await saveCurrentCycle(newCycle);
    // hasCycleStarted()는 _currentCycleKey 존재 여부로 판단하므로 별도 플래그 불필요

    return newCycle;
  }

  /// 이벤트 추가
  static Future<TreatmentCycle> addEvent(TreatmentEvent event) async {
    debugPrint('➕ [SimpleTreatmentService] 이벤트 추가: ${event.type.name}');
    debugPrint('   - 날짜: ${event.date}');
    final currentCycle = await getCurrentCycle();
    final updatedCycle = currentCycle.addEvent(event);
    await saveCurrentCycle(updatedCycle);
    debugPrint('   ✅ 이벤트 추가 완료');
    return updatedCycle;
  }

  /// 이벤트 업데이트
  static Future<TreatmentCycle> updateEvent(TreatmentEvent event) async {
    final currentCycle = await getCurrentCycle();
    final updatedCycle = currentCycle.updateEvent(event);
    await saveCurrentCycle(updatedCycle);
    return updatedCycle;
  }

  /// 이벤트 삭제
  static Future<TreatmentCycle> removeEvent(String eventId) async {
    final currentCycle = await getCurrentCycle();
    final updatedCycle = currentCycle.removeEvent(eventId);
    await saveCurrentCycle(updatedCycle);
    return updatedCycle;
  }

  /// 사이클 결과 설정
  static Future<TreatmentCycle> setCycleResult(CycleResult result) async {
    final currentCycle = await getCurrentCycle();
    final updatedCycle = currentCycle.copyWith(
      result: result,
      endDate: DateTime.now(),
    );
    await saveCurrentCycle(updatedCycle);
    return updatedCycle;
  }

  /// 사이클 결과 초기화
  static Future<TreatmentCycle> clearCycleResult() async {
    final currentCycle = await getCurrentCycle();
    final updatedCycle = currentCycle.copyWith(
      clearResult: true,
      clearEndDate: true,
    );
    await saveCurrentCycle(updatedCycle);
    return updatedCycle;
  }

  /// 지난 사이클 목록 조회
  static Future<List<TreatmentCycle>> getPastCycles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pastCyclesKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => TreatmentCycle.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 지난 사이클 목록 저장
  static Future<void> savePastCycles(List<TreatmentCycle> cycles) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cycles.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_pastCyclesKey, jsonString);
  }

  /// 새 사이클 시작 (현재 사이클을 지난 사이클로 이동)
  /// [type]: 시술 종류 (시험관/인공수정)
  /// [cycleNumber]: N차 시도
  /// [isNaturalCycle]: 자연주기 여부 (인공수정만)
  /// [isFrozenTransfer]: 동결배아 이식 여부 (시험관만)
  /// [startDate]: 시작일 (지정하지 않으면 오늘)
  static Future<TreatmentCycle> startNewCycle({
    TreatmentType type = TreatmentType.ivf,
    int? cycleNumber,
    bool isNaturalCycle = false,
    bool isFrozenTransfer = false,
    DateTime? startDate,
  }) async {
    final currentCycle = await getCurrentCycle();
    final pastCycles = await getPastCycles();

    // 현재 사이클에 데이터가 있으면 지난 사이클로 이동
    if (_hasAnyData(currentCycle)) {
      pastCycles.insert(0, currentCycle);
      await savePastCycles(pastCycles);
    }

    // 새 사이클 생성
    // cycleNumber가 지정되지 않은 경우, 같은 타입의 가장 높은 회차 + 1
    int newCycleNumber;
    if (cycleNumber != null) {
      newCycleNumber = cycleNumber;
    } else {
      // 같은 타입의 과거 사이클 중 가장 높은 회차 찾기
      final sameTypeCycles = pastCycles.where((c) => c.type == type).toList();
      if (sameTypeCycles.isEmpty) {
        newCycleNumber = 1;
      } else {
        final maxNumber = sameTypeCycles
            .map((c) => c.cycleNumber)
            .reduce((a, b) => a > b ? a : b);
        newCycleNumber = maxNumber + 1;
      }
    }

    var newCycle = TreatmentCycle.create(
      type: type,
      cycleNumber: newCycleNumber,
      isNaturalCycle: isNaturalCycle,
      isFrozenTransfer: isFrozenTransfer,
    );

    // 시작일이 지정된 경우 업데이트
    if (startDate != null) {
      newCycle = newCycle.copyWith(startDate: startDate);
    }

    await saveCurrentCycle(newCycle);

    return newCycle;
  }

  /// 사이클에 데이터가 있는지 확인
  static bool _hasAnyData(TreatmentCycle cycle) {
    return cycle.events.isNotEmpty || cycle.result != null;
  }

  /// 다음 추천 회차 계산
  /// [type]: 시술 종류
  static Future<int> getNextCycleNumber(TreatmentType type) async {
    final currentCycle = await getCurrentCycle();
    final pastCycles = await getPastCycles();

    // 현재 사이클과 과거 사이클 모두 확인
    final allCycles = [currentCycle, ...pastCycles];
    final sameTypeCycles = allCycles.where((c) => c.type == type).toList();

    if (sameTypeCycles.isEmpty) {
      return 1;
    }

    final maxNumber = sameTypeCycles
        .map((c) => c.cycleNumber)
        .reduce((a, b) => a > b ? a : b);
    return maxNumber + 1;
  }

  /// 사이클 정보 업데이트 (차수, 시술 종류, 시작일 등)
  static Future<TreatmentCycle> updateCycle(TreatmentCycle updatedCycle) async {
    final currentCycle = await getCurrentCycle();

    // 현재 사이클인지 확인
    if (currentCycle.id == updatedCycle.id) {
      await saveCurrentCycle(updatedCycle);
      return updatedCycle;
    }

    // 과거 사이클 중에서 찾기
    final pastCycles = await getPastCycles();
    final index = pastCycles.indexWhere((c) => c.id == updatedCycle.id);
    if (index != -1) {
      pastCycles[index] = updatedCycle;
      await savePastCycles(pastCycles);
    }

    return updatedCycle;
  }

  /// 사이클 삭제
  static Future<void> deleteCycle(String cycleId) async {
    final currentCycle = await getCurrentCycle();
    final pastCycles = await getPastCycles();

    // 현재 사이클 삭제
    if (currentCycle.id == cycleId) {
      // 과거 사이클이 있으면 가장 최근 것을 현재 사이클로 이동
      if (pastCycles.isNotEmpty) {
        final newCurrent = pastCycles.removeAt(0);
        await saveCurrentCycle(newCurrent);
        await savePastCycles(pastCycles);
      } else {
        // 과거 사이클이 없으면 새 사이클 생성
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_currentCycleKey);
      }
      return;
    }

    // 과거 사이클에서 삭제
    pastCycles.removeWhere((c) => c.id == cycleId);
    await savePastCycles(pastCycles);
  }

  /// 모든 데이터 초기화 (테스트용)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentCycleKey);
    await prefs.remove(_pastCyclesKey);
    // 레거시 데이터도 삭제
    await prefs.remove(_legacyCurrentCycleKey);
    await prefs.remove(_legacyPastCyclesKey);
  }

  /// 날짜 범위 내의 모든 이벤트 조회 (캘린더 연동용)
  /// 현재 사이클과 과거 사이클의 모든 이벤트를 날짜별로 반환
  static Future<Map<DateTime, List<TreatmentEvent>>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final currentCycle = await getCurrentCycle();
    final pastCycles = await getPastCycles();

    final Map<DateTime, List<TreatmentEvent>> result = {};

    // 모든 사이클의 이벤트 수집
    final allCycles = [currentCycle, ...pastCycles];

    for (final cycle in allCycles) {
      for (final event in cycle.events) {
        final eventDate = DateTime(event.date.year, event.date.month, event.date.day);

        // 날짜 범위 체크
        if (eventDate.isBefore(startDate) || eventDate.isAfter(endDate)) {
          continue;
        }

        result.putIfAbsent(eventDate, () => []);
        result[eventDate]!.add(event);
      }
    }

    return result;
  }

  /// 특정 날짜의 이벤트 조회
  static Future<List<TreatmentEvent>> getEventsByDate(DateTime date) async {
    final dateKey = DateTime(date.year, date.month, date.day);
    final events = await getEventsByDateRange(dateKey, dateKey);
    return events[dateKey] ?? [];
  }

  /// 날짜 범위 내의 사이클 결과 조회 (캘린더 연동용)
  static Future<Map<DateTime, CycleResult>> getCycleResultsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final currentCycle = await getCurrentCycle();
    final pastCycles = await getPastCycles();

    final Map<DateTime, CycleResult> result = {};

    final allCycles = [currentCycle, ...pastCycles];

    for (final cycle in allCycles) {
      if (cycle.result != null && cycle.endDate != null) {
        final endDateKey = DateTime(cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day);
        if (!endDateKey.isBefore(startDate) && !endDateKey.isAfter(endDate)) {
          result[endDateKey] = cycle.result!;
        }
      }
    }

    return result;
  }

  /// 날짜 범위 내의 사이클 시작일 조회 (캘린더 연동용)
  /// 반환: Map<날짜, List<사이클 정보 (cycleNumber, type)>>
  static Future<Map<DateTime, List<Map<String, dynamic>>>> getCycleStartDatesByRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final hasCycleStarted = await SimpleTreatmentService.hasCycleStarted();
    if (!hasCycleStarted) return {};

    final currentCycle = await getCurrentCycle();
    final pastCycles = await getPastCycles();

    final Map<DateTime, List<Map<String, dynamic>>> result = {};

    final allCycles = [currentCycle, ...pastCycles];

    for (final cycle in allCycles) {
      final cycleStartDate = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);

      // 날짜 범위 체크
      if (cycleStartDate.isBefore(startDate) || cycleStartDate.isAfter(endDate)) {
        continue;
      }

      result.putIfAbsent(cycleStartDate, () => []);
      result[cycleStartDate]!.add({
        'cycleNumber': cycle.cycleNumber,
        'type': cycle.type,
        'isFrozenTransfer': cycle.isFrozenTransfer,
        'isNaturalCycle': cycle.isNaturalCycle,
        'startDate': cycle.startDate,
      });
    }

    return result;
  }

  /// 샘플 데이터 생성 (테스트용)
  static Future<TreatmentCycle> createSampleData() async {
    final now = DateTime.now();

    final sampleCycle = TreatmentCycle(
      id: now.millisecondsSinceEpoch.toString(),
      cycleNumber: 1,
      startDate: now.subtract(const Duration(days: 21)),
      events: [
        TreatmentEvent(
          id: '${now.millisecondsSinceEpoch}_1',
          type: EventType.stimulation,
          date: now.subtract(const Duration(days: 21)),
          memo: '첫 주사 시작',
        ),
        TreatmentEvent(
          id: '${now.millisecondsSinceEpoch}_2',
          type: EventType.retrieval,
          date: now.subtract(const Duration(days: 10)),
          count: 8,
          memo: '컨디션 좋았음',
        ),
        TreatmentEvent(
          id: '${now.millisecondsSinceEpoch}_3',
          type: EventType.transfer,
          date: now.subtract(const Duration(days: 5)),
          count: 2,
          embryoDays: 5,
        ),
        TreatmentEvent(
          id: '${now.millisecondsSinceEpoch}_4',
          type: EventType.freezing,
          date: now.subtract(const Duration(days: 5)),
          count: 4,
          embryoDays: 5,
        ),
      ],
    );

    await saveCurrentCycle(sampleCycle);
    return sampleCycle;
  }

  // ============================================================
  // 레거시 호환성 메서드 (기존 코드와 호환)
  // ============================================================

  /// @deprecated Use addEvent or updateEvent instead
  static Future<SimpleTreatmentCycle> updateStage(
      SimpleTreatmentStage stage) async {
    // 레거시 코드 호환 - 실제로는 이벤트 추가/업데이트로 처리
    final currentCycle = await getCurrentCycle();

    // 기존 이벤트 찾기
    final existingEvent = currentCycle.events
        .where((e) => e.type == stage.type)
        .firstOrNull;

    if (stage.hasDate) {
      final event = TreatmentEvent(
        id: existingEvent?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: stage.type,
        date: stage.date ?? stage.startDate!,
        count: stage.count,
        embryoDays: stage.cultureDay,
        memo: stage.memo,
      );

      if (existingEvent != null) {
        await updateEvent(event);
      } else {
        await addEvent(event);
      }
    }

    // 레거시 형태로 반환
    return SimpleTreatmentCycle.create(cycleNumber: currentCycle.cycleNumber);
  }
}
