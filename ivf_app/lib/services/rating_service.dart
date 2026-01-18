import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 평가 유도 플로우 관리 서비스
class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  // SharedPreferences 키
  static const String _keyFirstUseDate = 'rating_first_use_date';
  static const String _keyCompletedDoses = 'rating_completed_doses';
  static const String _keyHasRated = 'rating_has_rated';
  static const String _keyGivenStars = 'rating_given_stars';
  static const String _keyLastPromptDate = 'rating_last_prompt_date';
  static const String _keyFeedbackSubmitted = 'rating_feedback_submitted';

  // 노출 조건 상수
  static const int _minDaysOfUsage = 7; // 최소 7일 사용
  static const int _minCompletedDoses = 10; // 최소 10회 복용 완료
  static const int _minDaysSinceLastPrompt = 10; // 마지막 프롬프트 후 10일

  SharedPreferences? _prefs;

  /// 서비스 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _ensureFirstUseDate();
  }

  /// 첫 사용일 기록 (없는 경우에만)
  Future<void> _ensureFirstUseDate() async {
    final firstUseDate = _prefs?.getString(_keyFirstUseDate);
    if (firstUseDate == null) {
      await _prefs?.setString(_keyFirstUseDate, DateTime.now().toIso8601String());
      debugPrint('📊 RatingService: 첫 사용일 기록됨');
    }
  }

  /// 첫 사용일 가져오기
  DateTime? get firstUseDate {
    final dateStr = _prefs?.getString(_keyFirstUseDate);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  /// 사용 일수 계산
  int get daysOfUsage {
    final first = firstUseDate;
    if (first == null) return 0;
    return DateTime.now().difference(first).inDays;
  }

  /// 복용 완료 횟수 가져오기
  int get completedDoses => _prefs?.getInt(_keyCompletedDoses) ?? 0;

  /// 복용 완료 횟수 증가
  Future<void> incrementCompletedDoses() async {
    final current = completedDoses;
    await _prefs?.setInt(_keyCompletedDoses, current + 1);
    debugPrint('📊 RatingService: 복용 완료 횟수 증가 → ${current + 1}');
  }

  /// 이미 평가했는지 여부
  bool get hasRated => _prefs?.getBool(_keyHasRated) ?? false;

  /// 준 별점 (null이면 아직 평가 안함)
  int? get givenStars => _prefs?.getInt(_keyGivenStars);

  /// 피드백 제출 완료 여부
  bool get feedbackSubmitted => _prefs?.getBool(_keyFeedbackSubmitted) ?? false;

  /// 마지막 프롬프트 날짜
  DateTime? get lastPromptDate {
    final dateStr = _prefs?.getString(_keyLastPromptDate);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  /// 마지막 프롬프트 이후 경과 일수
  int get daysSinceLastPrompt {
    final last = lastPromptDate;
    if (last == null) return 999; // 프롬프트 받은 적 없으면 큰 값
    return DateTime.now().difference(last).inDays;
  }

  /// 평가 프롬프트를 표시해야 하는지 확인
  /// 조건: 7일+ 사용 AND 10회+ 복용 완료 AND 아직 평가 안함 AND 마지막 프롬프트로부터 10일+
  bool shouldShowRatingPrompt() {
    // 이미 평가했으면 표시 안함
    if (hasRated) {
      debugPrint('📊 RatingService: 이미 평가 완료됨 → 표시 안함');
      return false;
    }

    // 사용 일수 체크
    if (daysOfUsage < _minDaysOfUsage) {
      debugPrint('📊 RatingService: 사용 일수 부족 ($daysOfUsage일 < $_minDaysOfUsage일) → 표시 안함');
      return false;
    }

    // 복용 완료 횟수 체크
    if (completedDoses < _minCompletedDoses) {
      debugPrint('📊 RatingService: 복용 완료 횟수 부족 ($completedDoses회 < $_minCompletedDoses회) → 표시 안함');
      return false;
    }

    // 마지막 프롬프트 이후 경과일 체크
    if (daysSinceLastPrompt < _minDaysSinceLastPrompt) {
      debugPrint('📊 RatingService: 마지막 프롬프트 후 ${daysSinceLastPrompt}일 < $_minDaysSinceLastPrompt일 → 표시 안함');
      return false;
    }

    debugPrint('📊 RatingService: 평가 프롬프트 표시 조건 충족!');
    return true;
  }

  /// 프롬프트 표시 기록
  Future<void> recordPromptShown() async {
    await _prefs?.setString(_keyLastPromptDate, DateTime.now().toIso8601String());
    debugPrint('📊 RatingService: 프롬프트 표시 기록됨');
  }

  /// 별점 저장 (평가 완료 처리)
  Future<void> saveRating(int stars) async {
    await _prefs?.setInt(_keyGivenStars, stars);
    await _prefs?.setBool(_keyHasRated, true);
    debugPrint('📊 RatingService: 별점 $stars점 저장됨');
  }

  /// 피드백 제출 완료 기록
  Future<void> recordFeedbackSubmitted() async {
    await _prefs?.setBool(_keyFeedbackSubmitted, true);
    debugPrint('📊 RatingService: 피드백 제출 완료 기록됨');
  }

  /// "다음에 하기" 선택 시 - 프롬프트 날짜만 기록
  Future<void> recordLater() async {
    await recordPromptShown();
    debugPrint('📊 RatingService: "다음에 하기" 선택됨');
  }

  /// 테스트/디버그용: 모든 평가 데이터 초기화
  Future<void> resetAllRatingData() async {
    await _prefs?.remove(_keyFirstUseDate);
    await _prefs?.remove(_keyCompletedDoses);
    await _prefs?.remove(_keyHasRated);
    await _prefs?.remove(_keyGivenStars);
    await _prefs?.remove(_keyLastPromptDate);
    await _prefs?.remove(_keyFeedbackSubmitted);
    await _ensureFirstUseDate();
    debugPrint('📊 RatingService: 모든 평가 데이터 초기화됨');
  }

  /// 디버그 정보 출력
  void printDebugInfo() {
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 RatingService 상태');
    debugPrint('  첫 사용일: $firstUseDate');
    debugPrint('  사용 일수: $daysOfUsage일');
    debugPrint('  복용 완료 횟수: $completedDoses회');
    debugPrint('  평가 완료 여부: $hasRated');
    debugPrint('  준 별점: $givenStars');
    debugPrint('  피드백 제출: $feedbackSubmitted');
    debugPrint('  마지막 프롬프트: $lastPromptDate');
    debugPrint('  프롬프트 후 경과일: $daysSinceLastPrompt일');
    debugPrint('  표시 조건 충족: ${shouldShowRatingPrompt()}');
    debugPrint('═══════════════════════════════════════');
  }
}
