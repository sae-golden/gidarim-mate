import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_settings.dart';

/// 알림 설정 서비스
class NotificationSettingsService {
  static const String _settingsKey = 'notification_settings';
  static const String _lastInjectionSideKey = 'last_injection_side';
  static const String _injectionHistoryKey = 'injection_history';

  /// 알림 설정 조회
  static Future<NotificationSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString == null) {
      return NotificationSettings.defaultSettings;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return NotificationSettings.fromJson(json);
    } catch (e) {
      return NotificationSettings.defaultSettings;
    }
  }

  /// 알림 설정 저장
  static Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
  }

  /// 알림 활성화 여부만 업데이트
  static Future<void> setEnabled(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(isEnabled: enabled));
  }

  /// 알람 스타일 활성화 여부 업데이트
  static Future<void> setAlarmStyle(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(alarmStyle: enabled));
  }

  /// 미완료 시 재알림 활성화 여부 업데이트
  static Future<void> setRepeatIfNotCompleted(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(repeatIfNotCompleted: enabled));
  }

  /// 마지막 주사 부위 조회
  static Future<String?> getLastInjectionSide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastInjectionSideKey);
  }

  /// 마지막 주사 부위 저장
  static Future<void> saveLastInjectionSide(String side) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastInjectionSideKey, side);
  }

  /// 추천 주사 부위 (어제와 반대쪽)
  static Future<String> getRecommendedInjectionSide() async {
    final lastSide = await getLastInjectionSide();
    if (lastSide == null || lastSide == 'right') {
      return 'left';
    }
    return 'right';
  }

  /// 주사 부위 텍스트
  static String getInjectionSideText(String side) {
    return side == 'left' ? '왼쪽' : '오른쪽';
  }

  /// 주사 기록 저장 (부위 포함)
  static Future<void> saveInjectionRecord({
    required String medicationId,
    required String side,
    required DateTime time,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 마지막 부위 업데이트
    await saveLastInjectionSide(side);

    // 히스토리에 추가
    final historyJson = prefs.getString(_injectionHistoryKey);
    List<Map<String, dynamic>> history = [];

    if (historyJson != null) {
      try {
        history = (jsonDecode(historyJson) as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } catch (e) {
        history = [];
      }
    }

    history.add({
      'medicationId': medicationId,
      'side': side,
      'time': time.toIso8601String(),
    });

    // 최근 100개만 유지
    if (history.length > 100) {
      history = history.sublist(history.length - 100);
    }

    await prefs.setString(_injectionHistoryKey, jsonEncode(history));
  }

  /// 최근 주사 기록 조회
  static Future<List<Map<String, dynamic>>> getRecentInjectionHistory({
    int limit = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_injectionHistoryKey);

    if (historyJson == null) return [];

    try {
      final history = (jsonDecode(historyJson) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // 최근 것부터 반환
      return history.reversed.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}
