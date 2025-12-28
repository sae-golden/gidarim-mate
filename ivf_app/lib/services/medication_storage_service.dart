import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';

/// 약물 로컬 저장 서비스
/// SharedPreferences를 사용한 로컬 저장
class MedicationStorageService {
  static const String _medicationsKey = 'local_medications';
  static const String _medicationStatusKey = 'local_medication_status';

  /// 모든 약물 조회
  static Future<List<Medication>> getAllMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_medicationsKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => Medication.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 오늘 복용해야 할 약물 조회
  static Future<List<Medication>> getTodayMedications() async {
    final allMedications = await getAllMedications();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allMedications.where((med) {
      final startDate = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      final endDate = DateTime(med.endDate.year, med.endDate.month, med.endDate.day);
      return !today.isBefore(startDate) && !today.isAfter(endDate);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// 약물 추가
  static Future<void> addMedication(Medication medication) async {
    final medications = await getAllMedications();
    medications.add(medication);
    await _saveMedications(medications);
  }

  /// 여러 약물 추가
  static Future<void> addMedications(List<Medication> newMedications) async {
    final medications = await getAllMedications();
    medications.addAll(newMedications);
    await _saveMedications(medications);
  }

  /// 약물 업데이트
  static Future<void> updateMedication(Medication medication) async {
    final medications = await getAllMedications();
    final index = medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      medications[index] = medication;
      await _saveMedications(medications);
    }
  }

  /// 약물 삭제
  static Future<void> deleteMedication(String medicationId) async {
    final medications = await getAllMedications();
    medications.removeWhere((m) => m.id == medicationId);
    await _saveMedications(medications);
  }

  /// 약물 목록 저장
  static Future<void> _saveMedications(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = medications.map((m) => m.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_medicationsKey, jsonString);
  }

  /// 복용 상태 조회 (날짜별)
  static Future<Map<String, bool>> getMedicationStatus(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = '${_medicationStatusKey}_${date.year}_${date.month}_${date.day}';
    final jsonString = prefs.getString(dateKey);

    if (jsonString == null) {
      return {};
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      return {};
    }
  }

  /// 복용 상태 저장
  static Future<void> setMedicationStatus(
    DateTime date,
    String medicationId,
    bool isCompleted,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = '${_medicationStatusKey}_${date.year}_${date.month}_${date.day}';

    final status = await getMedicationStatus(date);
    status[medicationId] = isCompleted;

    final jsonString = jsonEncode(status);
    await prefs.setString(dateKey, jsonString);
  }

  /// 모든 데이터 초기화 (테스트용)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_medicationsKey);
    // 상태 키들은 날짜별이라 전체 삭제는 복잡하므로 생략
  }
}
