import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/medication.dart';
import 'medication_storage_service.dart';

/// 홈 위젯 서비스
class HomeWidgetService {
  static const String _appGroupId = 'group.com.example.ivfapp';
  static const String _androidWidgetName = 'MedicationWidgetProvider';

  /// 마지막 업데이트 시간 (중복 업데이트 방지)
  static DateTime? _lastUpdateTime;
  static const Duration _updateDebounce = Duration(seconds: 2);

  /// 업데이트 진행 중 플래그
  static bool _isUpdating = false;

  /// 위젯 초기화
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      debugPrint('HomeWidgetService 초기화 완료');
    } catch (e) {
      debugPrint('HomeWidgetService 초기화 실패: $e');
    }
  }

  /// 위젯 데이터 업데이트
  static Future<void> updateWidget() async {
    if (kIsWeb) return;

    // 중복 업데이트 방지
    if (_isUpdating) {
      debugPrint('위젯 업데이트 진행 중, 스킵');
      return;
    }

    // 디바운싱: 마지막 업데이트 후 일정 시간 내 재호출 방지
    final now = DateTime.now();
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!) < _updateDebounce) {
      debugPrint('위젯 업데이트 디바운싱, 스킵');
      return;
    }

    _isUpdating = true;
    _lastUpdateTime = now;

    try {
      // 오늘의 약물 가져오기
      final allMedications = await MedicationStorageService.getAllMedications();
      final todayMedications = _getTodayMedications(allMedications);

      // 복용 상태 가져오기
      final status = await MedicationStorageService.getMedicationStatus(DateTime.now());

      // 약물 데이터를 JSON으로 변환
      final medicationsJson = todayMedications.map((m) => {
        'id': m.id,
        'name': m.name,
        'time': m.time,
        'type': m.type.toString().split('.').last,
      }).toList();

      // SharedPreferences에 저장 (Android 위젯이 읽을 수 있도록)
      await HomeWidget.saveWidgetData<String>(
        'medications',
        jsonEncode(medicationsJson),
      );
      await HomeWidget.saveWidgetData<String>(
        'medication_status',
        jsonEncode(status),
      );

      // 위젯 업데이트 요청
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
        qualifiedAndroidName: 'com.example.ivf_app.$_androidWidgetName',
      );

      debugPrint('위젯 업데이트 완료: ${todayMedications.length}개 약물');
    } catch (e) {
      debugPrint('위젯 업데이트 실패: $e');
    } finally {
      _isUpdating = false;
    }
  }

  /// 오늘 복용해야 할 약물 필터링
  static List<Medication> _getTodayMedications(List<Medication> medications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return medications.where((med) {
      final startDate = DateTime(
        med.startDate.year,
        med.startDate.month,
        med.startDate.day,
      );
      final endDate = DateTime(
        med.endDate.year,
        med.endDate.month,
        med.endDate.day,
      );

      // 오늘이 복용 기간 내인지 확인
      if (today.isBefore(startDate) || today.isAfter(endDate)) {
        return false;
      }

      // 패턴에 따라 오늘 복용해야 하는지 확인
      switch (med.pattern) {
        case '매일':
          return true;
        case '격일':
          final daysDiff = today.difference(startDate).inDays;
          return daysDiff % 2 == 0;
        case '월수금':
          return [1, 3, 5].contains(today.weekday);
        case '화목토':
          return [2, 4, 6].contains(today.weekday);
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// 복용 완료 시 위젯 업데이트
  static Future<void> onMedicationCompleted(String medicationId) async {
    await updateWidget();
  }

  /// 약물 추가/수정/삭제 시 위젯 업데이트
  static Future<void> onMedicationsChanged() async {
    await updateWidget();
  }
}
