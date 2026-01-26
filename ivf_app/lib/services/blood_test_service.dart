import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simple_treatment_cycle.dart';

/// 피검사 기록 서비스
/// SharedPreferences를 사용한 로컬 저장
class BloodTestService {
  static const String _bloodTestsKey = 'blood_tests';

  /// 특정 사이클의 피검사 기록 조회
  static Future<List<BloodTest>> getBloodTests(String cycleId) async {
    final all = await getAllBloodTests();
    return all.where((test) => test.cycleId == cycleId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 모든 피검사 기록 조회
  static Future<List<BloodTest>> getAllBloodTests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_bloodTestsKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => BloodTest.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 피검사 기록 저장
  static Future<void> _saveAllBloodTests(List<BloodTest> tests) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tests.map((t) => t.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_bloodTestsKey, jsonString);
  }

  /// 피검사 기록 추가
  static Future<BloodTest> addBloodTest(BloodTest test) async {
    final all = await getAllBloodTests();
    all.add(test);
    await _saveAllBloodTests(all);
    return test;
  }

  /// 피검사 기록 업데이트
  static Future<BloodTest> updateBloodTest(BloodTest test) async {
    final all = await getAllBloodTests();
    final index = all.indexWhere((t) => t.id == test.id);
    if (index != -1) {
      all[index] = test;
      await _saveAllBloodTests(all);
    }
    return test;
  }

  /// 피검사 기록 삭제
  static Future<void> removeBloodTest(String testId) async {
    final all = await getAllBloodTests();
    all.removeWhere((t) => t.id == testId);
    await _saveAllBloodTests(all);
  }

  /// 특정 사이클의 모든 피검사 기록 삭제
  static Future<void> removeBloodTestsForCycle(String cycleId) async {
    final all = await getAllBloodTests();
    all.removeWhere((t) => t.cycleId == cycleId);
    await _saveAllBloodTests(all);
  }

  /// 모든 데이터 초기화 (테스트용)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bloodTestsKey);
  }

  /// 특정 날짜 범위의 피검사 기록 조회 (캘린더용)
  static Future<List<BloodTest>> getBloodTestsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllBloodTests();
    return all.where((test) {
      return test.date.isAfter(start.subtract(const Duration(days: 1))) &&
          test.date.isBefore(end.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 사이클에 연결되지 않은 피검사 기록 조회
  static Future<List<BloodTest>> getOrphanBloodTests() async {
    final all = await getAllBloodTests();
    return all.where((test) => test.cycleId.isEmpty).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
