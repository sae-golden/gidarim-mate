import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// GA4 분석 서비스
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// 초기화
  static Future<void> initialize() async {
    if (kIsWeb) return;

    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

    // 기본 사용자 속성 설정
    await _analytics?.setAnalyticsCollectionEnabled(true);

    debugPrint('📊 GA4 초기화 완료');
  }

  /// Navigator Observer (화면 추적용)
  static FirebaseAnalyticsObserver? get observer => _observer;

  // ==================== 화면 이벤트 ====================

  /// 화면 조회 기록
  static Future<void> logScreenView(String screenName) async {
    await _analytics?.logScreenView(screenName: screenName);
    debugPrint('📊 화면 조회: $screenName');
  }

  // ==================== 약물 관련 이벤트 ====================

  /// 약물 추가
  static Future<void> logMedicationAdded({
    required String medicationType,
    required String inputMethod, // voice, camera, manual
  }) async {
    await _analytics?.logEvent(
      name: 'medication_added',
      parameters: {
        'medication_type': medicationType,
        'input_method': inputMethod,
      },
    );
    debugPrint('📊 약물 추가: type=$medicationType, method=$inputMethod');
  }

  /// 약물 삭제
  static Future<void> logMedicationDeleted({
    required String medicationType,
  }) async {
    await _analytics?.logEvent(
      name: 'medication_deleted',
      parameters: {
        'medication_type': medicationType,
      },
    );
  }

  /// 약물 수정
  static Future<void> logMedicationEdited({
    required String medicationType,
  }) async {
    await _analytics?.logEvent(
      name: 'medication_edited',
      parameters: {
        'medication_type': medicationType,
      },
    );
  }

  // ==================== 복용 기록 이벤트 ====================

  /// 복용 완료
  static Future<void> logMedicationCompleted({
    required String medicationType,
    required String completionSource, // notification, manual, widget
  }) async {
    await _analytics?.logEvent(
      name: 'medication_completed',
      parameters: {
        'medication_type': medicationType,
        'completion_source': completionSource,
      },
    );
    debugPrint('📊 복용 완료: type=$medicationType, source=$completionSource');
  }

  /// 복용 취소
  static Future<void> logMedicationUncompleted({
    required String medicationType,
  }) async {
    await _analytics?.logEvent(
      name: 'medication_uncompleted',
      parameters: {
        'medication_type': medicationType,
      },
    );
  }

  /// 주사 부위 기록
  static Future<void> logInjectionSiteRecorded({
    required String side, // left, right
  }) async {
    await _analytics?.logEvent(
      name: 'injection_site_recorded',
      parameters: {
        'side': side,
      },
    );
  }

  // ==================== 알림 관련 이벤트 ====================

  /// 알림 수신
  static Future<void> logNotificationReceived() async {
    await _analytics?.logEvent(name: 'notification_received');
  }

  /// 알림 액션 (완료/스누즈)
  static Future<void> logNotificationAction({
    required String action, // complete, snooze, tap
  }) async {
    await _analytics?.logEvent(
      name: 'notification_action',
      parameters: {
        'action': action,
      },
    );
    debugPrint('📊 알림 액션: $action');
  }

  // ==================== 기능 사용 이벤트 ====================

  /// 백업 생성
  static Future<void> logBackupCreated() async {
    await _analytics?.logEvent(name: 'backup_created');
    debugPrint('📊 백업 생성');
  }

  /// 백업 복원
  static Future<void> logBackupRestored() async {
    await _analytics?.logEvent(name: 'backup_restored');
    debugPrint('📊 백업 복원');
  }

  /// 음성 입력 사용
  static Future<void> logVoiceInputUsed({
    required bool success,
  }) async {
    await _analytics?.logEvent(
      name: 'voice_input_used',
      parameters: {
        'success': success.toString(),
      },
    );
  }

  /// 카메라 입력 사용
  static Future<void> logCameraInputUsed({
    required bool success,
  }) async {
    await _analytics?.logEvent(
      name: 'camera_input_used',
      parameters: {
        'success': success.toString(),
      },
    );
  }

  /// 피드백 전송
  static Future<void> logFeedbackSent() async {
    await _analytics?.logEvent(name: 'feedback_sent');
  }

  /// 앱 리뷰 요청 표시
  static Future<void> logReviewPromptShown() async {
    await _analytics?.logEvent(name: 'review_prompt_shown');
  }

  /// 추가 기록 저장 (증상, 메모 등)
  static Future<void> logAdditionalRecordSaved({
    required String recordType, // symptom, memo, photo
  }) async {
    await _analytics?.logEvent(
      name: 'additional_record_saved',
      parameters: {
        'record_type': recordType,
      },
    );
  }

  // ==================== 사용자 속성 ====================

  /// 사용자 속성 설정
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics?.setUserProperty(name: name, value: value);
  }

  /// 총 등록 약물 수 설정
  static Future<void> setTotalMedicationsCount(int count) async {
    await setUserProperty(
      name: 'total_medications',
      value: count.toString(),
    );
  }
}
