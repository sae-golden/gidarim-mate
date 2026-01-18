import 'package:shared_preferences/shared_preferences.dart';

/// 주사 부위 히스토리 서비스
/// 좌/우 번갈아 주사하도록 마지막 부위를 저장하고 추천
class InjectionSiteService {
  static const String _lastSiteKey = 'last_injection_site';
  static const String _siteHistoryKey = 'injection_site_history';

  /// 마지막 주사 부위 조회
  /// 반환: 'left' 또는 'right' 또는 null
  static Future<String?> getLastSite() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSiteKey);
  }

  /// 주사 부위 저장
  static Future<void> saveSite(String side) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSiteKey, side);

    // 히스토리에도 추가 (날짜 포함)
    final history = await getHistory();
    history.add({
      'side': side,
      'date': DateTime.now().toIso8601String(),
    });

    // 최근 30개만 유지
    if (history.length > 30) {
      history.removeRange(0, history.length - 30);
    }

    await prefs.setStringList(
      _siteHistoryKey,
      history.map((e) => '${e['side']}|${e['date']}').toList(),
    );
  }

  /// 주사 부위 히스토리 조회
  static Future<List<Map<String, String>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStrings = prefs.getStringList(_siteHistoryKey) ?? [];

    return historyStrings.map((str) {
      final parts = str.split('|');
      return {
        'side': parts[0],
        'date': parts.length > 1 ? parts[1] : '',
      };
    }).toList();
  }

  /// 추천 부위 계산 (마지막 부위의 반대편)
  static Future<String> getRecommendedSite() async {
    final lastSite = await getLastSite();
    if (lastSite == null) return 'left'; // 첫 주사는 왼쪽 추천
    return lastSite == 'left' ? 'right' : 'left';
  }

  /// 히스토리 초기화
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSiteKey);
    await prefs.remove(_siteHistoryKey);
  }
}
